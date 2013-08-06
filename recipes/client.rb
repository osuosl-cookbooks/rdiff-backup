# default attributes
default['users'] = ['rdiff-backup-client']
default['authorization']['sudo']['users'] = ["rdiff-backup-client"]
default['rdiff-backup']['backup-dirs'] = []

# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the client backup group and user
group 'rdiff-backup-client' do
  system true
end

user 'rdiff-backup-client' do
  comment 'User for rdiff-backup client backups'
  gid 'rdiff-backup-client'
  system true
  shell '/bin/bash'
  home '/home/rdiff-backup-client'
  supports :manage_home => true
end

# copy over the client backup user's ssh pubkey from the node['users'] attribute and its corresponding databag
include_recipe "user::data_bag"
