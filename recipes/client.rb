rdiff_user = ['rdiff-backup-client']
rdiff_user << node['users']
node.default['users'] = rdiff_user

# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the client backup user and copy over its ssh pubkey from the node['users'] attribute and its corresponding databag
include_recipe "user::data_bag"
