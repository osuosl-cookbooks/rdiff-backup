# default attributes
node.default['rdiff-backup']['client']['ssh-port'] = "22"
node.default['rdiff-backup']['client']['source-dirs'] = ["/etc", "/var/log"]
node.default['rdiff-backup']['client']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['client']['retention-period'] = "3M"
node.default['rdiff-backup']['client']['additional-args'] = ""
node.default['rdiff-backup']['client']['user'] = "rdiff-backup-client"
node.default['users'] = [node['rdiff-backup']['client']['user']]
node.default['authorization']['sudo']['users'] = [node['rdiff-backup']['client']['user']]

# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the client backup group and user
group node['rdiff-backup']['client']['user'] do
  system true
end

user node['rdiff-backup']['client']['user'] do
  comment 'User for rdiff-backup client backups'
  gid node['rdiff-backup']['client']['user']
  system true
  shell '/bin/bash'
  home '/home/' + node['rdiff-backup']['client']['user']
  supports :manage_home => true
end

# copy over the client backup user's ssh pubkey from the node['users'] attribute and its corresponding databag
include_recipe "user::data_bag"
