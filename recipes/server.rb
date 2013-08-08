# default attributes
node.default['rdiff-backup']['starthour'] = 13 #(9pm PST) 
node.default['rdiff-backup']['endhour'] = 23 #(7am PST) 

# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the server backup group
group 'rdiff-backup-server' do
  system true
end

# create the server backup user
user 'rdiff-backup-server' do
  comment 'User for rdiff-backup server backups'
  gid 'rdiff-backup-server'
  system true
  shell '/bin/bash'
  home '/home/rdiff-backup-server'
  supports :manage_home => true
end

# (the server backup user's private key must be copied over manually)

# find nodes to back up
Chef::Log.info("Beginning search for nodes.  This may take some time depending on your node count")
nodes = Array.new
nodes = search(:node, 'run_list:recipe\[rdiff-backup\:\:client\]')

if nodes.empty?
  Chef::Log.info("No nodes returned from search")
else
  # sort nodes alphabetically
  nodes.sort! {|a,b| a.name <=> b.name }

  # distribute backups across a certain time period every day
  minutesbetweenbackups = ((node['rdiff-backup']['endhour'] - node['rdiff-backup']['starthour'] + 24) % 24 * 60 ) / nodes.size
  hoursbetweenbackups = minutesbetweenbackups / 60

  finishedbackups = 0

  nodes.each do |n|
    minute = (minutesbetweenbackups * finishedbackups) % 60
    hour = (hoursbetweenbackups * finishedbackups) % 24 + node['rdiff-backup']['starthour']

    if not n.node['rdiff-backup']['source-dirs'].empty?

      # format the list of paths to back up
      pathlist = String.new
      n.node['rdiff-backup']['source-dirs'].each do |path|
        pathlist += " \"" + path + "\""
      end

      # create cron job for each node to back them up and then remove old backups
      cron_d "rdiff-backup-#{n.name}" do
        action :create
        minute "#{minute}"
        hour "#{hour}"
        user "rdiff-backup-server"
        mailto "root@osuosl.org"
        command "
          for path in#{pathlist};
            do rdiff-backup --force --create-full-path #{n.node['rdiff-backup']['additional-args']} \"#{n.node['fqdn']}\:${path}\" \"#{n.node['rdiff-backup']['destination-dir']}/filesystem/#{n.node['fqdn']}/${path}\";
          done;
          for path in#{pathlist};
            do rdiff-backup --force --remove-older-than #{n.node['rdiff-backup']['retention-period']} \"#{n.node['rdiff-backup']['destination-dir']}/filesystem/#{n.node['fqdn']}/${path}\";
          done;
        "
      end
    end

    finishedbackups += 1
  end
end

