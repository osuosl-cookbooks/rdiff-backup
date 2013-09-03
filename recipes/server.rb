# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the server backup group
group node['rdiff-backup']['server']['user'] do
  system true
end

# create the server backup user
user node['rdiff-backup']['server']['user'] do
  comment 'User for rdiff-backup server backups'
  gid node['rdiff-backup']['server']['user']
  system true
  shell '/bin/bash'
  home '/home/' + node['rdiff-backup']['server']['user']
  supports :manage_home => true
end

# (the server backup user's private key must be copied over manually)

# search for nodes to back up
Chef::Log.info("Beginning search for nodes.  This may take some time depending on your node count")
nodes = Array.new
nodes = search(:node, 'run_list:recipe\[rdiff-backup\:\:client\]')

# get nodes to back up from the unmanagedhosts databag too
unmanagedhosts = Array.new
unmanagedhosts = data_bag('rdiff-backup_unmanagedhosts')
unmanagedhosts.each do |host|
  
  hostbag = Hash.new
  hostbag = data_bag_item('rdiff-backup_unmanagedhosts', host)
  
  # Create a new "node" hash for each unmanaged host and populate it with the default client attributes (assuming that the client attributes on the rdiff-backup server are in fact the default attributes; the rdiff-backup server should not also be an rdiff-backup client and therefore should not have had its attributes modified).
  newnode = Hash.new
  newnode['rdiff-backup'] = Hash.new
  newnode['rdiff-backup']['client'] = Hash.new
  node['rdiff-backup']['client'].each do |k,v|
    newnode['rdiff-backup']['client'].merge!({ k => v })
  end
  newnode['fqdn'] = hostbag['fqdn']

  # Only continue if the fqdn is present.
  if 1
  #if newnode['fqdn'] != nil

    # Override the the default attributes with any other properties present in the databag.
    hostbag.each do |k,v|
      if k != "id" && k != "fqdn"
        newnode['rdiff-backup']['client'][k] = v
      end
    end
    
    # Add the new node to the list of nodes to back up.
    nodes << newnode

  end
end

if nodes.empty?
  Chef::Log.info("No nodes returned from search or rdiff-backup/unmanagedclients databag item")
else

  # distribute backups across a certain time period every day
  minutesbetweenbackups = ((node['rdiff-backup']['server']['endhour'] - node['rdiff-backup']['server']['starthour'] + 24) % 24 * 60 ) / nodes.size
  hoursbetweenbackups = minutesbetweenbackups / 60
  finishedbackups = 0
  nodes.each do |n|
    minute = (minutesbetweenbackups * finishedbackups) % 60
    hour = (hoursbetweenbackups * finishedbackups) % 24 + node['rdiff-backup']['server']['starthour']

    if !n['rdiff-backup']['client']['source-dirs'].empty?

      # format the list of paths to back up
      pathlist = String.new
      n['rdiff-backup']['client']['source-dirs'].each do |path|
        pathlist += " \"" + path + "\""
      end

      # Shortening the variables here to make the giant rdiff-backup command more readable
      fqdn = n['fqdn']
      port = n['rdiff-backup']['client']['ssh-port']
      src = n['rdiff-backup']['client']['source-dirs']
      dest = n['rdiff-backup']['client']['destination-dir']
      period = n['rdiff-backup']['client']['retention-period']
      args = n['rdiff-backup']['client']['additional-args']
      user = n['rdiff-backup']['client']['user']
      destpath = "#{dest}/filesystem/#{fqdn}/${path}"

      # create cron job for each node to back them up and then remove old backups
      cron_d "rdiff-backup-#{fqdn}" do
        action :create
        minute "#{minute}"
        hour "#{hour}"
        user node['rdiff-backup']['server']['user']
        mailto "root@osuosl.org"
        command "for path in#{pathlist}; do rdiff-backup --force --create-full-path --remote-schema \"ssh -Cp #{port} %s sudo rdiff-backup --server --restrict-read-only /\" #{args} \"#{user}\@#{fqdn}\:\:${path}\" \"#{destpath}\"; rdiff-backup --force --remove-older-than #{period} \"#{destpath}\"; done"
      end
    end

    finishedbackups += 1
  end
end

