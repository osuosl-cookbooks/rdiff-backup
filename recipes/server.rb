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




# pseudocode

#search for clients and get them from databags
#take client default attributes and merge them with each backup\'s attributes to get all backups, using cookbook defaults where attributes are not specified
#get group of backups that already exist by searching for cron jobs
#get list of backups to remove by doing "exists" - "specified" and then remove their cron jobs and nagios alerts
#get a list of backups to add by doing "specified" - "exists" and then create their cron jobs and nagios alerts





nodes = Set.new

# Get nodes to back up by searching.
Chef::Log.info("Beginning search for nodes. This may take some time depending on your node count.")
hosts = search(:node, 'recipes:rdiff-backup\:\:client')
hosts.each do |host|
  host = host.to_hash # Convert the node to a deep hash for easy management.

  # Create a new "node" hash for each unmanaged host.
  newnode = deep_copy(node) # Use the rdiff-backup server's attributes as the defaults.
  deep_merge!(newnode, host) # Override the defaults with the client node's attributes.

  nodes << newnode # Add the new node to the list of nodes.
end

# Get nodes to back up from the unmanagedhosts databag too.
unmanagedhosts = data_bag(UNMANAGED_HOSTS_DATABAG).to_set
unmanagedhosts.each do |bagitem|
  host = data_bag_item(UNMANAGED_HOSTS_DATABAG, bagitem) # Read a "node" from the databag.
  
  # Create a new "node" hash for each unmanaged host.
  newnode = deep_copy(node) # Use the rdiff-backup server's attributes as the defaults.
  deep_merge!(newnode, host) # Override the defaults with the client node's attributes.
  newnode['fqdn'].gsub!('_', '.') # Fix the fqdn, since periods couldn't be used in the databag ID.

  nodes << newnode # Add the new node to the list of nodes.
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

jobs = Hash.new

# For each node, create a new job object for each job by merging job-specific attributes over node-specific ones.
nodes.each do |n|
  n['rdiff-backup']['client']['jobs'].keys.each do |src-dir|
    if src-dir.start_with?("/") # Only work with absolute paths. Also excludes the default hash.
      job = n['rdiff-backup']['client']['jobs']['default'] || Hash.new # Start with the client's default attributes if they are specified.
      deep_merge!(job, n['rdiff-backup']['client']['jobs'][src-dir]) # Merge the job-specific attributes over the top.
      jobs["#{n['fqdn']} #{src-dir}"] = job # Add the job to the hash, with its key being of the form "fqdn dir".
    end
  end
end

existingjobs = Set.new

# Get a list of jobs which already exist.
File.open(CRON_FILE, "r") do |file|
  file.each_line do |line|
    if line.match(/^\D.*/) == nil # Only parse lines that start with numbers, i.e. actual jobs.
      existingjobs << "#{line.split[7]} #{line.split[8]}" # Add the job name of the form "fqdn dir" to the list of existing jobs.
    end
  end
end

jobs.each do |jobname, job|

  crontab = "MAILTO=#{}\n# Crontab for rdiff-backup managed by Chef. Changes will be overwritten.\n"

  # Put each job in the cron file.

  
  # Create the exclusion files for each job.


  # If the job didn't already exist, create nagios alerts for it (if they're enabled).
  if existingjobs.has_key?(jobname)
    # But what about if nagios attributes get updated? How do we detect it? Maybe we should just always run the lwrps to update them? Or do we need to delete it first?
  end
end

# Distribute jobs across a certain time period every day.
minutesbetweenjobs = ((node['rdiff-backup']['server']['endhour'] - node['rdiff-backup']['server']['starthour'] + 24) % 24 * 60 ) / nodes.size
hoursbetweenjobs = minutesbetweenjobs / 60
finishedjobs = 0
nodes.each do |n|
  minute = (minutesbetweenjobs * finishedjobs) % 60
  hour = (hoursbetweenjobs * finishedjobs) % 24 + node['rdiff-backup']['server']['starthour']

  if !n['rdiff-backup']['client']['source-dirs'].empty?

    # Format the list of paths to back up.
    pathlist = String.new
    n['rdiff-backup']['client']['source-dirs'].reject{ |dir| dir == "" }.each do |path| # Don't let blank lines be source dirs.
      pathlist += " \"" + path + "\""
    end

    # Shorten the variables here to make the giant rdiff-backup command more readable.
    fqdn = n['fqdn']
    port = n['rdiff-backup']['client']['ssh-port']
    dest = n['rdiff-backup']['client']['destination-dir']
    period = n['rdiff-backup']['client']['retention-period']
    args = n['rdiff-backup']['client']['additional-args']
    user = n['rdiff-backup']['client']['user']
    destpath = "#{dest}/filesystem/#{fqdn}/${path}"
    
    e = n['rdiff-backup']['client']['exclude-dirs']
    exclude = e ? e.join("\\n") : ""

    # Create the base directory that this node's jobs will go to (enough so that the rdiff-backup server user have write permission).
    directory dest do
      owner node['rdiff-backup']['server']['user']
      group node['rdiff-backup']['server']['user']
      mode '0775'
      recursive true
      action :create
    end

    # If there are any paths to back up...
    if pathlist != " \"\""
      # Create cron job for the node to back them up and then remove old jobs.
      cron_d "rdiff-backup-#{fqdn}" do
        action :create
        minute minute
        hour hour
        user node['rdiff-backup']['server']['user']
        mailto "root@osuosl.org"
        command "echo #{exclude} | for path in#{pathlist}; do rdiff-backup #{args} --force --create-full-path --exclude-device-files --exclude-fifos --exclude-sockets --exclude-globbing-filelist-stdin --remote-schema \"ssh -Cp #{port} -o StrictHostKeyChecking=no \\%s sudo rdiff-backup --server --restrict-read-only /\" \"#{user}\@#{fqdn}\:\:${path}\" \"#{destpath}\"; rdiff-backup --force --remove-older-than #{period} \"#{destpath}\"; done"
      end
    else
      # Delete this node from the array of hosts to keep jobs for, so that its job will be deleted.
      nodestodelete << n
    end
  end

  finishedjobs += 1
end

# Delete all rdiff-backup cron jobs that we didn't just enforce the existence of (useful for when you disable jobs for a host). The reason why we don't just delete all cron jobs at the beginning of the recipe is so that valid cron jobs are always available, so that jobs will run on time regardless of when the chef-client runs.
nodestodelete.each do |n|
  nodes.delete(n)
end
files = Dir.glob("/etc/cron.d/rdiff-backup-*")
nodes.each do |n|
  if files.include?(n['fqdn'])
    files.delete(n['fqdn'])
  end
end
files.each do |f|
  File.delete(f)
end

# Set up Nagios checks for the jobs if the server has the nagios::client recipe and node['rdiff-backup']['server']['nagios-alerts'] = true.
if node.recipes.include?("nagios::client")
  if node['rdiff-backup']['server']['nagios-alerts']

    # Copy over the check_rdiff nrpe plugin.
    cookbook_file "#{node['nagios']['plugin_dir']}/check_rdiff" do
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

    # For each node...
    nodes.each do |n|
      
      # For each directory to be backed up...
      n['rdiff-backup']['client']['source-dirs'].each do |sd|

        if sd != ""
          # Shorten the variables to make the check command more readable.
          dd = "#{n['rdiff-backup']['client']['destination-dir']}/filesystem/#{n['fqdn']}#{sd}"
          warn = node['rdiff-backup']['server']['endhour'] + node['rdiff-backup']['server']['nagios-warning']
          crit = node['rdiff-backup']['server']['endhour'] + node['rdiff-backup']['server']['nagios-critical']
          nrpecheck = "check_rdiff-backup_#{n['fqdn']}_#{sd.gsub("/", "-")}"
          maxchange = n['rdiff-backup']['client']['nagios-maxchange'] || 500
          maxtime = n['rdiff-backup']['client']['nagios-maxtime'] || 24
          
          # Create the check.
          nagios_service "rdiff-backup_#{n['fqdn']}_#{sd}" do
            command_line "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{nrpecheck}"
            host_name node['fqdn']
            action :add
          end
          nagios_nrpecheck nrpecheck do
            command "sudo #{node['nagios']['plugin_dir']}/check_rdiff -r #{dd} -w #{warn} -c #{crit} -l #{maxchange} -p #{maxtime}"
            action :add
          end
        end
      end
    end
    
    # Delete checks for hosts we no longer back up.
    nodestodelete.each do |n|
      n['rdiff-backup']['client']['source-dirs'].each do |sd|
        nagios_nrpecheck "check_rdiff-backup_#{n['fqdn']}_#{sd.gsub("/", "-")}" do
          action :remove
        end
        nagios_service "rdiff-backup_#{n['fqdn']}_#{sd}" do
          action :remove
        end
      end
    end

  # Remove all rdiff-backup checks if node['rdiff-backup']['server']['nagios'] == false
  else
    nodes.merge(nodestodelete).each do |n|
      n['rdiff-backup']['client']['source-dirs'].each do |sd|
        nagios_nrpecheck "check_rdiff-backup_#{n['fqdn']}_#{sd.gsub("/", "-")}" do
          action :remove
        end
        nagios_service "rdiff-backup_#{n['fqdn']}_#{sd}" do
          action :remove
        end
      end
    end
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
