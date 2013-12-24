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

# Search for nodes to back up.
Chef::Log.info("Beginning search for nodes. This may take some time depending on your node count.")
rawnodes = search(:node, 'recipes:rdiff-backup\:\:client')

# Convert the nodes to hashes for easy management.
nodes = Set.new
rawnodes.each do |rawnode|
  nodes << rawnode.to_hash
end

# Get nodes to back up from the unmanagedhosts databag too.
unmanagedhosts = Set.new
unmanagedhosts = data_bag('rdiff-backup_unmanagedhosts').to_set
unmanagedhosts.each do |host|
  
  hostbag = Hash.new
  hostbag = data_bag_item('rdiff-backup_unmanagedhosts', host)
  
  # Create a new "node" hash for each unmanaged host and populate it with the default client attributes (assuming that the client attributes on the rdiff-backup server are in fact intended to be the default attributes).
  newnode = Hash.new
  newnode['rdiff-backup'] = Hash.new
  newnode['rdiff-backup']['client'] = Hash.new
  node['rdiff-backup']['client'].each do |k,v|
    newnode['rdiff-backup']['client'].merge!({ k => v })
  end
  newnode['chef_environment'] = "_default" # Environment is set manually because it's not an rdiff-backup client attribute.

  newnode['fqdn'] = hostbag['id'].gsub('_', '.') # We can assume the id exists because otherwise it's not a valid databag and wouldn't be returned by the data_bag_item function. The gsub is because periods can't be used in IDs, so we use underscores instead.

  # Override the the default attributes with any other properties present in the databag.
  hostbag.each do |k,v|
    if k != "id"
      if k != "environment"
        newnode['rdiff-backup']['client'][k] = v
      else
        newnode['chef_environment'] = v
      end
    end 
  end
  
  # Add the new node to the list of nodes.
  nodes << newnode
end

# Keep track of nodes that we are no longer backing up so we can make sure to remove jobs and/or nagios checks for them.
nodestodelete = Set.new

# Filter out clients not in our environment, if applicable.
if node['rdiff-backup']['server']['restrict-to-own-environment']
  nodes.each do |n|
    if n['chef_environment'] != node.chef_environment
      nodestodelete << n
    end
  end

  nodestodelete.each do |n|
    nodes.delete(n)
  end
end

if nodes.empty?
  Chef::Log.info("WARNING: No nodes returned from search or found in rdiff-backup_unmanagedclients databag.")
else

  # Distribute backups across a certain time period every day.
  minutesbetweenbackups = ((node['rdiff-backup']['server']['endhour'] - node['rdiff-backup']['server']['starthour'] + 24) % 24 * 60 ) / nodes.size
  hoursbetweenbackups = minutesbetweenbackups / 60
  finishedbackups = 0
  nodes.each do |n|
    minute = (minutesbetweenbackups * finishedbackups) % 60
    hour = (hoursbetweenbackups * finishedbackups) % 24 + node['rdiff-backup']['server']['starthour']

    if !n['rdiff-backup']['client']['source-dirs'].empty?

      # Format the list of paths to back up.
      pathlist = String.new
      n['rdiff-backup']['client']['source-dirs'].each do |path|
        pathlist += " \"" + path + "\""
      end

      # Shorten the variables here to make the giant rdiff-backup command more readable.
      fqdn = n['fqdn']
      port = n['rdiff-backup']['client']['ssh-port']
      src = n['rdiff-backup']['client']['source-dirs']
      dest = n['rdiff-backup']['client']['destination-dir']
      period = n['rdiff-backup']['client']['retention-period']
      args = n['rdiff-backup']['client']['additional-args']
      user = n['rdiff-backup']['client']['user']
      destpath = "#{dest}/filesystem/#{fqdn}/${path}"

      # Create the base directory that this node's backups will go to (enough so that the rdiff-backup server user have write permission).
      directory dest do
        owner node['rdiff-backup']['server']['user']
        group node['rdiff-backup']['server']['user']
        mode '0775'
        recursive true
        action :create
      end

      # If there are any paths to back up...
      if pathlist != " \"\""
        # Create cron job for the node to back them up and then remove old backups.
        cron_d "rdiff-backup-#{fqdn}" do
          action :create
          minute minute
          hour hour
          user node['rdiff-backup']['server']['user']
          mailto "root@osuosl.org"
          command "for path in#{pathlist}; do rdiff-backup #{args} --force --create-full-path --exclude-device-files --exclude-fifos --exclude-sockets --remote-schema \"ssh -Cp #{port} -o StrictHostKeyChecking=no \\%s sudo rdiff-backup --server --restrict-read-only /\" \"#{user}\@#{fqdn}\:\:${path}\" \"#{destpath}\"; rdiff-backup --force --remove-older-than #{period} \"#{destpath}\"; done"
        end
      else
        # Delete this node from the array of hosts to keep jobs for, so that its job will be deleted.
        nodestodelete << n
      end
    end

    finishedbackups += 1
  end
end

# Delete all rdiff-backup cron jobs that we didn't just enforce the existence of (useful for when you disable backups for a host). The reason why we don't just delete all cron jobs at the beginning of the recipe is so that valid cron jobs are always available, so that backups will run on time regardless of when the chef-client runs.
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

# Set up Nagios checks for the backups if the server has the nagios::client recipe and node['rdiff-backup']['server']['nagios-alerts'] = true.
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
      end
    end

  # Remove all rdiff-backup checks if node['rdiff-backup']['server']['nagios'] == false
  else
    nodes.merge(nodestodelete).each do |n|
      n['rdiff-backup']['client']['source-dirs'].each do |sd|
        nagios_nrpecheck "check_rdiff-backup_#{n['fqdn']}_#{sd.gsub("/", "-")}" do
          action :remove
        end
      end
    end
  end
end
