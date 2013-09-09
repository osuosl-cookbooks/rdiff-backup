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
rawnodes = search(:node, 'run_list:recipe\[rdiff-backup\:\:client\]')

# Convert the nodes to hashes for easy management.
nodes = Array.new
rawnodes.each do |rawnode|
  nodes << rawnode.to_hash
end

# Get nodes to back up from the unmanagedhosts databag too.
unmanagedhosts = Array.new
unmanagedhosts = data_bag('rdiff-backup_unmanagedhosts')
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

# Filter out clients not in our environment, if applicable.
nodestodelete = Array.new
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
  Chef::Log.info("No nodes returned from search or found in rdiff-backup_unmanagedclients databag. Exiting.")
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

      # Create cron job for each node to back them up and then remove old backups.
      cron_d "rdiff-backup-#{fqdn}" do
        action :create
        minute minute
        hour hour
        user node['rdiff-backup']['server']['user']
        mailto "root@osuosl.org"
        command "for path in#{pathlist}; do rdiff-backup --force --create-full-path --remote-schema \"ssh -Cp #{port} %s sudo rdiff-backup --server --restrict-read-only /\" #{args} \"#{user}\@#{fqdn}\:\:${path}\" \"#{destpath}\"; rdiff-backup --force --remove-older-than #{period} \"#{destpath}\"; done"
      end
    end

    finishedbackups += 1
  end
end

