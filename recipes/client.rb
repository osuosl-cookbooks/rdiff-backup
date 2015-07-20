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
include_recipe 'yum'
include_recipe 'yum-epel'
package 'rdiff-backup'

client_user = node['rdiff-backup']['client']['user']

# Create the server backup user.
user client_user do
  comment 'User for rdiff-backup client backups'
  shell '/bin/bash'
  supports manage_home: true
  action :nothing
end.run_action(:create)

ohai 'reload_passwd' do
  action :nothing
  plugin 'etc'
end.run_action(:reload)

sudo client_user do
  user client_user
  group client_user
  commands ['/usr/bin/rdiff-backup --server --restrict-read-only /']
  nopasswd true
end
node.override['ssh_keys'][client_user] = ['rdiff-backup-client']
include_recipe 'ssh-keys'
