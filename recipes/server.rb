#
# Cookbook:: rdiff-backup
# Recipe:: server
#
# Copyright:: 2013-2021, Oregon State University
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

include_recipe 'rdiff-backup'

if node['rdiff-backup']['server']['nrpe']
  include_recipe 'nrpe'

  cookbook_file ::File.join(node['nrpe']['plugin_dir'], 'check_rdiff') do
    mode '0755'
    cookbook 'rdiff-backup'
    owner node['nrpe']['user']
    group node['nrpe']['group']
    source 'nagios/plugins/check_rdiff'
  end

  sudo 'check_rdiff' do
    user node['nrpe']['user']
    nopasswd true
    commands [
      '/usr/lib64/nagios/plugins/check_rdiff',
      '/usr/lib64/nagios/plugins/check_rdiff_log',
    ]
  end
end

user node['rdiff-backup']['server']['user']

group node['rdiff-backup']['server']['group'] unless node['rdiff-backup']['server']['user'] == node['rdiff-backup']['server']['group']

sudo node['rdiff-backup']['server']['user'] do
  user node['rdiff-backup']['server']['user']
  group node['rdiff-backup']['server']['group']
  nopasswd true
  commands ['/usr/bin/sudo rdiff-backup --server --restrict-read-only /']
end

directory node['rdiff-backup']['server']['lock_dir'] do
  owner node['rdiff-backup']['server']['user']
  group node['rdiff-backup']['server']['group']
  mode '0755'
  recursive true
end

is_root = node['rdiff-backup']['server']['user'] == 'root'
ssh_dir = is_root ? '/root/.ssh' : "/home/#{node['rdiff-backup']['server']['user']}/.ssh"

directory ssh_dir do
  owner node['rdiff-backup']['server']['user']
  group node['rdiff-backup']['server']['group']
  mode '0700'
  recursive true
end

secrets = data_bag_item('rdiff-backup-secrets', 'secrets')

file "#{ssh_dir}/id_rsa" do
  content secrets['ssh-key']
  mode '0600'
  owner node['rdiff-backup']['server']['user']
end

directory '/var/log/rdiff-backup' do
  owner node['rdiff-backup']['server']['user']
  group node['rdiff-backup']['server']['group']
  mode '0755'
  recursive true
end
