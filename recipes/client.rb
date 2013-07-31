# install rdiff-backup
package "rdiff-backup" do
  action :install
end

# create the backup user and copy over its ssh pubkey
include_recipe "user::data_bag"
node['users'] = ['rdiff-backup-client']

# give the backup user sudo access so it can read all the files
node['authorization']['sudo']['users'] = ["rdiff-backup-client"]
