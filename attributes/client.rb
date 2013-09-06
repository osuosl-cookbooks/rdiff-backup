# Default attributes
node.default['rdiff-backup']['client']['ssh-port'] = "22"
node.default['rdiff-backup']['client']['source-dirs'] = [""]
node.default['rdiff-backup']['client']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['client']['retention-period'] = "3M"
node.default['rdiff-backup']['client']['additional-args'] = ""
node.default['rdiff-backup']['client']['user'] = "rdiff-backup-client"

# If there are environment-specific databag entries, use them. Otherwise, use the generic one.
if data_bag_item("users", "#{node['rdiff-backup']['client']['user']}-#{node['chef_environment']}")
  node.default['users'] = ["#{node['rdiff-backup']['client']['user']}-#{node['chef_environment']}"]
else
  node.default['users'] = ["#{node['rdiff-backup']['client']['user']}"]
end

node.default['authorization']['sudo']['users'] = [node['rdiff-backup']['client']['user']]
