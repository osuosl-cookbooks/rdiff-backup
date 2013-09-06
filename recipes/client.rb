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

# Copy over the client backup user's ssh pubkey from the node['users'] attribute and its corresponding databag
include_recipe "user::data_bag"
