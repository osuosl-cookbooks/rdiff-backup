# Install rdiff-backup.
package "rdiff-backup" do
  action :install
end

# Create the server backup group.
group node['rdiff-backup']['client']['user'] do
  system true
end

# Create the server backup user.
user node['rdiff-backup']['client']['user'] do
  comment 'User for rdiff-backup client backups'
  gid node['rdiff-backup']['client']['user']
  system true
  shell '/bin/bash'
  home '/home/' + node['rdiff-backup']['client']['user']
  supports :manage_home => true
end

# As long as the pubkey databag exists for the user...
if data_bag("users").include?("#{node['rdiff-backup']['client']['user']}")
  # Copy over the user's ssh pubkey.
  node.default['users'] = ["#{node['rdiff-backup']['client']['user']}"]
  include_recipe "user::data_bag"
end

# Give the user sudo access.
node.default['authorization']['sudo']['users'] = [node['rdiff-backup']['client']['user']]
