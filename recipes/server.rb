# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the backup user (its private key must be copied over manually)
include_recipe "user::data_bag"
node['users'] = ['rdiff-backup-server']

# find nodes to back up
Chef::Log.info("Beginning search for nodes.  This may take some time depending on your node count")
nodes = Array.new

nodes = search(:node, "hostname:[* TO *] AND recipe:rdiff-backup-client")

if nodes.empty?
  Chef::Log.info("No nodes returned from search")
end

# sort nodes alphabetically
nodes.sort! {|a,b| a.name <=> b.name }

# distribute backups across a certain time period every day
minutesbetweenbackups = ((node['rdiff-backup']['endhour'] - node['rdiff-backup']['starthour'] + 24) % 24 * 60 ) / nodes.size
hoursbetweenbackups = minutesbetweenbackups / 60

finishedbackups = 0

nodes.each do |n|
  minute = (minutesbetweenbackups * finishedbackups) % 60
  hour = (hoursbetweenbackups * finishedbackups) % 24 + node['rdiff-backup']['starthour']

  cron "rdiff-backup-#{n.name}" do
    action :create
    minute "#{minute}"
    hour "#{hour}"
    user "rdiff-backup-server"
    mailto "root@osuosl.org"
    command "rdiff-backup #{n.fqdn}:#{n['rdiff-backup']['backup-dirs']} #{node['rdiff-backup']['backup-target']}"
  end

  finishedbackups += 1
end
