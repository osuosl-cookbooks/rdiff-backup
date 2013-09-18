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
if data_bag("users").include?(node['rdiff-backup']['client']['user'])
  # Copy over the user's ssh pubkey.
  node.set['users'] = [node['rdiff-backup']['client']['user']].concat(node['users'])
  include_recipe "user::data_bag"
end

# Give the user sudo access for the rdiff-backup command.
sudo node['rdiff-backup']['client']['user'] do
  user      node['rdiff-backup']['client']['user']
  runas     'root'
  nopasswd  true
  commands  ['/usr/bin/rdiff-backup --server --restrict-read-only /']
end
