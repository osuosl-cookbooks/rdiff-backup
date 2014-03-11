#
# Cookbook Name:: rdiff-backup
# Recipe:: server
#
# Copyright 2013, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

UNMANAGED_HOSTS_DATABAG = 'rdiff-backup_unmanagedhosts'
CRON_FILE = '/etc/cron.d/rdiff-backup'

# Install rdiff-backup.
package "rdiff-backup" do
  action :install
end

# Create the server backup group.
group node['rdiff-backup']['server']['user'] do
  system true
end

# Create the server backup user.
user node['rdiff-backup']['server']['user'] do
  comment 'User for rdiff-backup server backups'
  gid node['rdiff-backup']['server']['user']
  system true
  shell '/bin/bash'
  home '/home/' + node['rdiff-backup']['server']['user']
  supports :manage_home => true
end

# Note: The server backup user's private key must be copied over manually.

nodes = Set.new

# Find nodes to back up by searching.
Chef::Log.info("Beginning search for nodes. This may take some time depending on your node count.")
hosts = search(:node, 'recipes:rdiff-backup\:\:client')
hosts.each do |host|
  host = host.to_hash # Convert the node to a deep hash for easy management.

  # Create a new "node" hash for each unmanaged host.
  newnode = deep_copy(node) # Use the rdiff-backup server's attributes as the defaults.
  deep_merge!(newnode, host) # Override the defaults with the client node's attributes.

  nodes << newnode # Add the new node to the set of nodes.
end

# Find nodes to back up from the unmanagedhosts databag too.
unmanagedhosts = data_bag(UNMANAGED_HOSTS_DATABAG).to_set
unmanagedhosts.each do |bagitem|
  host = data_bag_item(UNMANAGED_HOSTS_DATABAG, bagitem) # Read a "node" from the databag.
  
  # Create a new "node" hash for each unmanaged host.
  newnode = deep_copy(node) # Use the rdiff-backup server's attributes as the defaults.
  deep_merge!(newnode, host) # Override the defaults with the client node's attributes.
  newnode['fqdn'].gsub!('_', '.') # Fix the fqdn, since periods couldn't be used in the databag ID.

  nodes << newnode # Add the new node to the set of nodes.
end

# Filter out clients not in our environment, if applicable.
if node['rdiff-backup']['server']['restrict-to-own-environment']
  nodes.each do |n|
    if n['chef_environment'] != node.chef_environment
      nodes.delete(n)
    end
  end
end

if nodes.empty?
  Chef::Log.info("WARNING: No nodes returned from search or found in rdiff-backup_unmanagedclients databag.")
end

jobs = Set.new

# For each node, create a new job object for each job by merging job-specific attributes over node-specific ones.
nodes.each do |n|
  n['rdiff-backup']['client']['jobs'].keys.each do |src-dir|
    if src-dir.start_with?("/") # Only work with absolute paths. Also excludes the "default" hash.
      job = n['rdiff-backup']['client']['jobs']['default'] || Hash.new # Start with the client's default attributes if they are specified.
      deep_merge!(job, n['rdiff-backup']['client']['jobs'][src-dir]) # Merge the job-specific attributes over the top.
      job['fqdn'] = n['fqdn'] # Keep the fqdn in the job object.
      job['source-dir'] = src-dir # Keep the source-dir in the job object.
      jobs << job # Add the new job to the set of jobs.
    end
  end
end

# Keep the set of jobs in "bare" format too so we can compare with the "bare" pre-existing jobs.
specifiedjobs = Set.new
jobs.each do |job|
  newjob = Hash.new # Create a new "bare" job with just enough information to identify it.
  newjob['fqdn'] = job['fqdn']
  newjob['source-dir'] = job['source-dir']
  specifiedjobs << newjob # Add the job name of the form "fqdn dir" to the set of existing jobs.
end

# Get the set of jobs which already exist so we can decide which ones to remove.
existingjobs = Set.new
File.open(CRON_FILE, "r") do |file|
  file.each_line do |line|
    if line.match(/^\D.*/) == nil # Only parse lines that start with numbers, i.e. actual jobs.
      newjob = Hash.new # Create a new "bare" job with just enough information to identify it.
      newjob['fqdn'] = line.split[7]
      newjob['source-dir'] = line.split[8]
      existingjobs << newjob # Add the job name of the form "fqdn dir" to the set of existing jobs.
    end
  end
end

# Get the set of jobs that need to be removed by subtracting the set of specified jobs by the set of existing jobs.
removejobs = existingjobs.dup.subtract(specifiedjobs)

# Figure out how much time to wait between starting jobs.
minutesbetweenjobs = ((node['rdiff-backup']['server']['end-hour'] - node['rdiff-backup']['server']['start-hour'] + 24) % 24 * 60 ) / jobs.size
hoursbetweenjobs = minutesbetweenjobs / 60

# Set up each job.
setjobs = 0
jobs.each do |job|

  # Shorten some long variables for readability.
  fqdn = job['fqdn']
  sd = job['source-dir']
  dd = "#{job['destination-dir']}/filesystem/#{fqdn}#{sd}"
  suser = node['rdiff-backup']['server']['user']
  maxchange = job['nagios']['max-change']
  latestart = job['nagios']['max-late-start']
  latefinwarn = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-warning'] # Minute is ceiling'd up to the next hour
  latefincrit = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-critical'] # Minute is ceiling'd up to the next hour
  servicename = "rdiff-backup_#{job['fqdn']}_#{sd}"
  nrpecheckname = "check_rdiff-backup_#{job['fqdn']}_#{sd.gsub("/", "-")}"

  # Create the base directory that this backup will go to (enough so that the rdiff-backup server user has write permission).
  directory dd do
    owner suser
    group suser
    mode '0775'
    recursive true
    action :create
  end

  # Set run times for each job, distributing them evenly across a certain time period every day.
  job['minute'] = (minutesbetweenjobs * setjobs) % 60
  job['hour'] = ((hoursbetweenjobs * setjobs) + node['rdiff-backup']['server']['start-hour']) % 24
  setjobs += 1

  # Create the exclude files for each job.
  template "/home/#{suser}/exclude/#{fqdn}-#{sd}" do
    source "exclude.sh.erb"
    mode "0774"
    variables({
        :fqdn => fqdn,
        :src => sd,
        :paths => job['exclude-dirs'],
      })
    action :create
  end

  # Create scripts for each job.
  template "/home/#{suser}/scripts/#{fqdn}-#{sd}" do
    source "job.sh.erb"
    mode "0664"
    variables({
        :fqdn => fqdn,
        :src => sd,
        :dest => dd,
        :period => job['retention-period'],
        :user => job['user'],
        :port => job['ssh-port'],
        :args => job['additional-args']
      })
    action :create
  end
  
  # If nagios alerts are enabled and the job didn't already exist, create nagios alerts for the job.
  if node['rdiff-backup']['server']['nagios']['alerts'] and job['nagios']['alerts']
    if existingjobs.include?("#{fqdn} #{sd}")

    # TODO: But what about if nagios attributes get updated? How do we detect it? Maybe we should just always run the lwrps to update them? Or do we need to delete them first? Won't that reset the alert so it has no history?

    nagios_service servicename do
      command_line "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{nrpecheckname}"
      host_name node['fqdn']
      action :add
    end
    nagios_nrpecheck nrpecheckname do
      command "sudo #{node['nagios']['plugin_dir']}/check_rdiff -r #{dd} -w #{latefinwarn} -c #{latefincrit} -l #{maxchange} -p #{latestart}"
      action :add
    end
  else # Remove the nagios alerts if alerts are disabled.
    nagios_nrpecheck "check_rdiff-backup_#{job['fqdn']}_#{job['source-dir'].gsub("/", "-")}" do
      action :remove
    end
    nagios_service "rdiff-backup_#{job['fqdn']}_#{job['source-dir']}" do
      action :remove
    end
  end
end

# Create the crontab for all the jobs.
template CRON_FILE do
  source "cron.d.erb"
  mode "0664"
  variables({
      :fqdn => job['fqdn'],
      :src => job['source-dir'],
      :dest => job['destination-dir'],
      :period => job['retention-period'],
      :user => job['user'],
      :port => job['ssh-port'],
      :args => job['additional-args']
    })
  action :create
end

# Remove the exclude files, job scripts, and nagios alerts for each job to be removed.
removejobs.each do |job|
  File.delete("/home/#{node['rdiff-backup']['server']['user']}/exclude/#{job['fqdn']}-#{job['source-dir']}")
  File.delete("/home/#{node['rdiff-backup']['server']['user']}/scripts/#{job['fqdn']}-#{job['source-dir']}")
  nagios_nrpecheck "check_rdiff-backup_#{job['fqdn']}_#{job['source-dir'].gsub("/", "-")}" do
    action :remove
  end
  nagios_service "rdiff-backup_#{job['fqdn']}_#{job['source-dir']}" do
    action :remove
  end
end

# Recursive copy
def deep_copy(object)
  return Marshal.load(Marshal.dump(object))
end

# Recursive bot.merge!(top) for hashes.
def deep_merge!(bot, top)
  top.keys.each do |key|
    if top[key].is_a?(Hash)
      if !bot[key].is_a?(Hash) # Make a new subhash in bot if top has one there.
        bot[key] = Hash.new
      end
      deep_merge!(bot[key], top[key])
    else
      bot[key] = top[key]
    end
  end
end
