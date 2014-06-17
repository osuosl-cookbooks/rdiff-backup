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

HOSTS_DATABAG = 'rdiff-backup_hosts'
CRON_FILE = '/etc/cron.d/rdiff-backup'

# Recursive copy for objects like nested Hashes.
def deep_copy(object)
  Marshal.load(Marshal.dump(object))
end

# Recursive copy for Chef node hashes; only copies stuff relevant to rdiff-backup.
def deep_copy_node(oldhash)
  newhash = Hash.new
  newhash['rdiff-backup'] = JSON.parse(oldhash['rdiff-backup'].to_json) # This is passed through JSON to convert it from an ImmutableMash to a plain old Hash.
  newhash['fqdn'] = oldhash['fqdn']
  newhash['chef_environment'] = oldhash['chef_environment']
  return newhash
end

# Recursive bot.merge!(top) for hashes.
def deep_merge!(bot, top)
  top.keys.each do |key|
    if top[key].is_a?(Hash)
      unless bot[key].is_a?(Hash) # Make a new subhash in bot if top has one there.
        bot[key] = Hash.new
      end
      deep_merge!(bot[key], top[key])
    else
      bot[key] = top[key]
    end
  end
  return bot
end

# Recursive bot.merge(top) for hashes; returns new hash rather than modifying the bottom one.
def deep_merge(bot, top)
  deep_merge!(deep_copy(bot), top)
end

servernode = deep_copy_node(node.to_hash); # This servernode hash that emulates a node definition allows rdiff-backup server attributes to be stored and modified without affecting the actual node definition.

# Removes a job, deleting all files and nagios checks associated with it.
def remove_job(job, servernode)
  excludepath = "/home/#{servernode['rdiff-backup']['server']['user']}/exclude/#{job['fqdn']}_#{job['source-dir']}"
  File.delete(excludepath) if File.exists?(excludepath)
  scriptpath = "/home/#{servernode['rdiff-backup']['server']['user']}/scripts/#{job['fqdn']}_#{job['source-dir']}"
  File.delete(scriptpath) if File.exists?(scriptpath)
end

nodes = Set.new

# Find nodes to back up by searching.
Chef::Log.info("Beginning search for nodes. This may take some time depending on your node count.")
searchhosts = search(:node, 'recipes:rdiff-backup\:\:client')
searchhosts.each do |host|
  hosthash = deep_copy_node(host.to_hash) # Convert the node to a deep hash for easy management.

  # Create a new "node" hash for each host.
  newnode = deep_copy_node(servernode) # Use the rdiff-backup server's attributes as the defaults.
  deep_merge!(newnode, hosthash) # Override the defaults with the client node's attributes.

  nodes << newnode # Add the new node to the set of nodes.
end

# Find nodes to back up from the hosts databag too.
baghosts = data_bag(HOSTS_DATABAG).to_set

# First pass to get the rdiff-backup server's databag first so we can use it for defaults if it exists.
baghosts.each do |bagitem|
  databagnode = data_bag_item(HOSTS_DATABAG, bagitem) # Read a "node" from the databag.
  databagnode['fqdn'] = databagnode['id'].gsub('_', '.') # Fix the fqdn, since periods couldn't be used in the databag ID.
  databagnode.delete('id')
  if servernode['fqdn'] == databagnode['fqdn']
    deep_merge!(servernode, databagnode) # Override the server's current attributes with attributes from its databag.
    break
  end
end

# Second pass for all the other hosts.
baghosts.each do |bagitem|
  databagnode = data_bag_item(HOSTS_DATABAG, bagitem) # Read a "node" from the databag.
  databagnode['fqdn'] = databagnode['id'].gsub('_', '.') # Fix the fqdn, since periods couldn't be used in the databag ID.
  databagnode.delete('id')

  clientnode = Hash.new
  
  # If the host is already being managed in Chef, use its node attributes as the defaults.
  nodes.each do |n|
    if databagnode['fqdn'] == n['fqdn']
      clientnode = n
      break
    end
  end

  deep_merge!(clientnode, databagnode) # Merge the client data bag attributes over the client node attributes.
  clientnode = deep_merge!(deep_copy_node(servernode), clientnode) # Merge the client attributes over the server attributes to get the final set of client attributes.

  nodes << clientnode # Add the new node to the set of nodes.
end

# Filter out clients not in our environment, if applicable.
if servernode['rdiff-backup']['server']['restrict-to-own-environment']
  nodes.each do |n|
    if n['chef_environment'] != servernode['chef_environment']
      nodes.delete(n)
    end
  end
end

if nodes.empty?
  Chef::Log.info("WARNING: No nodes returned from search or found in rdiff-backup_hosts databag.")
end

# Install rdiff-backup.
package "rdiff-backup" do
  action :install
end

# Create the server backup group.
group servernode['rdiff-backup']['server']['user'] do
  system true
end

# Create the server backup user.
user servernode['rdiff-backup']['server']['user'] do
  comment 'User for rdiff-backup server backups'
  gid servernode['rdiff-backup']['server']['user']
  system true
  shell '/bin/bash'
  home '/home/' + servernode['rdiff-backup']['server']['user']
  supports :manage_home => true
end

# Copy over and set up the Nagios nrpe plugin, if applicable.
if servernode['rdiff-backup']['server']['nagios']['alerts']

  # Copy over the check_rdiff nrpe plugin.
  cookbook_file "#{servernode['rdiff-backup']['server']['nagios']['plugin-dir']}/check_rdiff" do
    source "nagios/plugins/check_rdiff"
    mode '755'
    action :create
  end

  # Give the user sudo access for the nrpe plugin.
  sudo 'nrpe' do
    user      'nrpe'
    runas     'root'
    nopasswd  true
    commands  ["#{node['nagios']['plugin_dir']}/check_rdiff"]
  end

end

# Note: The server backup user's private key must be copied over manually.

jobs = Set.new

# For each node, create a new job object for each job by merging job-specific attributes over node-specific ones.
nodes.each do |n|

  if n['rdiff-backup']['client']['jobs'].empty?
    Chef::Log.info("WARNING: No jobs specified for host '#{n['fqdn']}'.")
  end
  n['rdiff-backup']['client']['jobs'].keys.each do |src|
    if src.start_with?("/") # Only work with absolute paths. Also excludes the "default" hash.
      job = deep_copy(n['rdiff-backup']['server']['jobs']['default']) || Hash.new # Start with the server's default attributes.
      deep_merge!(job, n['rdiff-backup']['client']['jobs']['default'] || Hash.new) # Merge the client's default attributes over the top.
      deep_merge!(job, n['rdiff-backup']['server']['jobs'][src] || Hash.new) # Merge the server's node-specific attributes over the top.
      deep_merge!(job, n['rdiff-backup']['client']['jobs'][src] || Hash.new) # Merge the job-specific attributes over the top.

      # Keep higher-level attributes in the job object for convenience.
      job['source-dir'] = src
      job['fqdn'] = n['fqdn']
      job['user'] = n['rdiff-backup']['client']['user']
      job['ssh-port'] = n['rdiff-backup']['client']['ssh-port']

      # Remove exclusion rules that don't apply to this job
      relevantdirs = Array.new
      job['exclude-dirs'].each do |dir|
        relevantdirs << dir if dir.start_with?(src)
      end
      job['exclude-dirs'] = relevantdirs

      jobs << job
    end
  end
end

# Keep the set of jobs in "bare" format too so we can compare with the "bare" pre-existing jobs.
specifiedjobs = Set.new
jobs.each do |job|
  newjob = Hash.new # Create a new "bare" job with just enough information to identify it.
  newjob['fqdn'] = job['fqdn']
  newjob['source-dir'] = job['source-dir'].gsub("/", "-")
  specifiedjobs << newjob
end

# Get the set of jobs which already exist so we can decide which ones to remove.
existingjobs = Set.new
if File.exists?(CRON_FILE)
  File.open(CRON_FILE, "r") do |file|
    file.each_line do |line|
      if line.match(/^\D.*/) == nil # Only parse lines that start with numbers, i.e. actual jobs.
        newjob = Hash.new # Create a new "bare" job with just enough information to identify it.
        newjob['fqdn'] = line.gsub(/.*\/(.*)_.*/, '\1').strip
        newjob['source-dir'] = line.split('_')[-1].strip
        existingjobs << newjob
      end
    end
  end
end

# Get the set of jobs that need to be removed by subtracting the set of specified jobs by the set of existing jobs.
removejobs = existingjobs.dup.subtract(specifiedjobs)

# Figure out how much time to wait between starting jobs.
unless jobs.empty?
  minutesbetweenjobs = ((servernode['rdiff-backup']['server']['end-hour'] - servernode['rdiff-backup']['server']['start-hour'] + 24) % 24 * 60 ) / jobs.size
end

services = []

# Set up each job.
setjobs = 0
jobs.each do |job|

  # Shorten some long variables for readability.
  fqdn = job['fqdn']
  sd = job['source-dir']
  dd = "#{job['destination-dir']}/filesystem/#{fqdn}#{sd}"
  suser = servernode['rdiff-backup']['server']['user']
  maxchange = job['nagios']['max-change']
  latestart = job['nagios']['max-late-start']
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
  job['hour'] = ((minutesbetweenjobs * setjobs / 60).floor + servernode['rdiff-backup']['server']['start-hour']) % 24
  setjobs += 1

  # Create the exclude files for each job.
  directory "/home/#{suser}/exclude" do
    owner suser
    group suser
    mode '0775'
    recursive true
    action :create
  end
  template "/home/#{suser}/exclude/#{fqdn}_#{sd.gsub("/", "-")}" do
    source "exclude.erb"
    owner suser
    group suser
    mode "0664"
    variables({
      :src => sd,
      :paths => job['exclude-dirs'],
    })
    action :create
  end

  # Create scripts for each job.
  directory "/home/#{suser}/scripts" do
    owner suser
    group suser
    mode '0775'
    recursive true
    action :create
  end
  template "/home/#{suser}/scripts/#{fqdn}_#{sd.gsub("/", "-")}" do
    source "job.sh.erb"
    owner suser
    group suser
    mode "0774"
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
  if servernode['rdiff-backup']['server']['nagios']['alerts'] and job['nagios']['alerts'] and not existingjobs.include?("#{fqdn} #{sd}")

    latefinwarn = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-warning'] # Minute is ceiling'd up to the next hour
    latefincrit = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-critical'] # Minute is ceiling'd up to the next hour

    newservice = {
      'id' => servicename,
      'command_line' => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{nrpecheckname}",
      'host_name' => servernode['fqdn']
    }
    services << newservice

    nagios_nrpecheck nrpecheckname do
      command "sudo #{servernode['rdiff-backup']['server']['nagios']['plugin-dir']}/check_rdiff -r #{dd} -w #{latefinwarn} -c #{latefincrit} -l #{maxchange} -p #{latestart}"
      action :add
    end

  end
end

# Set up Nagios remote attributes.
node.set['nagios']['remote_services'] = services

# Create the crontab for all the jobs.
template CRON_FILE do
  source "cron.d.erb"
  mode "0664"
  variables({
    :shour => servernode['rdiff-backup']['server']['start-hour'],
    :ehour => servernode['rdiff-backup']['server']['end-hour'],
    :mailto => servernode['rdiff-backup']['server']['mailto'],
    :suser => servernode['rdiff-backup']['server']['user'],
    :jobs => jobs
  })
  action :create
end

# Remove all jobs that need to be removed.
removejobs.each do |job|
  remove_job(job, servernode)
end
