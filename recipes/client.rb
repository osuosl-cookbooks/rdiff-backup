# Install rdiff-backup
package "rdiff-backup" do
  action :install
end

# Create the server backup group
group node['rdiff-backup']['client']['user'] do
  system true
end

# Create the server backup user
user node['rdiff-backup']['client']['user'] do
  comment 'User for rdiff-backup client backups'
  gid node['rdiff-backup']['client']['user']
  system true
  shell '/bin/bash'
  home '/home/' + node['rdiff-backup']['client']['user']
  supports :manage_home => true
end

# Figure out which pubkey to give the user. If there are environment-specific databag entries, use them. Otherwise, use the generic one.
if data_bag_item("users", "#{node['rdiff-backup']['client']['user']}-#{node['chef_environment']}")
  node.default['users'] = ["#{node['rdiff-backup']['client']['user']}-#{node['chef_environment']}"]
else
  node.default['users'] = ["#{node['rdiff-backup']['client']['user']}"]
end

# Copy over the user's ssh pubkey from the node['users'] attribute and its corresponding databag
include_recipe "user::data_bag"

# Now give the user sudo access
node.default['authorization']['sudo']['users'] = [node['rdiff-backup']['client']['user']]

