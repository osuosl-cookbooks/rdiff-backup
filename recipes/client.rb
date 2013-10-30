#
# Cookbook Name:: rdiff-backup
# Recipe:: client
#
# Copyright 2013, Oregon State University
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
