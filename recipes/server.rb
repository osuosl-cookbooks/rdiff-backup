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
nodes = Array.new # Can this line be removed?  It seems pointless to someone who is new to Ruby.
nodes = search(:node, 'run_list:recipe\[rdiff-backup\:\:client\]')

# get nodes to back up from the unmanagedclients databag item too
#clientobjects = Hash.new # Can this line be removed?  It seems pointless to someone who is new to Ruby.
#clientobjects = data_bag_item('rdiff-backup', 'unmanagedclients')['clientobjects']
#clientobjects.each do |client|
#  client.each do |fqdn,properties| # there is really only one client per clientobject, fyi
#    newnode = ['fqdn' => fqdn, 'rdiff-backup' => node['rdiff-backup']['client']]
#    properties.each do |key,value|
#      newnode = Hash.new
#      newnode['rdiff-backup'] = Hash.new
#      newnode['rdiff-backup']['client'] = Hash.new
#      newnode['rdiff-backup']['client'][key] = value
#    end
#  end
#end

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

    if !n.node['rdiff-backup']['client']['source-dirs'].empty?

      # format the list of paths to back up
      pathlist = String.new
      n.node['rdiff-backup']['client']['source-dirs'].each do |path|
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
      cron_d "rdiff-backup-#{n.fqdn}" do
        action :create
        minute "#{minute}"
        hour "#{hour}"
        user node['rdiff-backup']['server']['user']
        mailto "root@osuosl.org"
        command "for path in#{pathlist}; do rdiff-backup --force --create-full-path --remote-schema \"ssh -Cp #{port} %s rdiff-backup --server --restrict-read-only /\" #{args} \"#{user}\@#{fqdn}\:\:${path}\" \"#{destpath}\"; rdiff-backup --force --remove-older-than #{period} \"#{destpath}\"; done;"
      end
    end

    finishedbackups += 1
  end
end

