#
# Cookbook Name:: rdiff-backup
# Recipe:: client-base
#
# Copyright 2014, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

HOSTS_DATABAG = 'rdiff-backup_hosts'
USERS_DATABAG = 'users'

begin
  hostsdatabag = data_bag(HOSTS_DATABAG)
rescue
  Chef::Log.warn("Unable to load databag '#{HOSTS_DATABAG}'")
  hostsdatabag = []
end
fqdn = node['fqdn'].gsub('.', '_')
# Use the user and sudo preferences from the host's databag if it exists and the attributes are specified, otherwise, use the attributes from the node definition.
if hostsdatabag.include?(fqdn)
  databagnode = data_bag_item(HOSTS_DATABAG, fqdn)
  user = databagnode.fetch('rdiff-backup', {}).fetch('client', {})['user']
  sudo = databagnode.fetch('rdiff-backup', {}).fetch('client', {})['sudo']
end
user ||= node['rdiff-backup']['client']['user']
sudo ||= node['rdiff-backup']['client']['sudo']

if user != 'root'
  # Create the client backup group.
  group user do
    system true
  end

  # Create the client backup user.
  user user do
    comment 'User for rdiff-backup client backups'
    gid user
    system true
    shell '/bin/bash'
    home File.join('/home', user)
    supports :manage_home => true
  end

  # Give the user sudo access for the rdiff-backup command.
  if sudo
    node.force_override['authorization']['sudo']['include_sudoers_d'] = true
    begin
      sudo user do
        user      user
        runas     'root'
        nopasswd  true
        commands  ['/usr/bin/rdiff-backup --server --restrict-read-only /']
        defaults  ['!requiretty']
      end
    rescue
      Chef::Log.warn("Unable to provide sudo access to rdiff-backup user '#{user}'")
    end
  end
end

begin
  usersdatabag = data_bag(USERS_DATABAG)
rescue
  Chef::Log.warn("Unable to load databag '#{USERS_DATABAG}'")
  usersdatabag = []
end
# As long as the pubkey databag exists for the user...
if usersdatabag.include?(user)
  # Copy over the user's ssh pubkey if they're not already set up.
  if not (node.fetch('users',{}).include?(user))
    node.set['users'] = [user].concat(node['users']) # Add the user to the list of users to set up for this node.
  end
  include_recipe 'user::data_bag'
end
