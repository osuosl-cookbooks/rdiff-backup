#
# Cookbook Name:: rdiff-backup
# Recipe:: server
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

HOSTS_DATABAG = 'rdiff-backup_hosts'
CRON_FILE = '/etc/cron.d/rdiff-backup'
LOG_DIR = '/var/log/rdiff-backup'

# Recursive copy for objects like nested Hashes.
def deep_copy(object)
  Marshal.load(Marshal.dump(object))
end

# Recursive copy for Chef node hashes; only copies attributes relevant to rdiff-backup.
def deep_copy_node(oldhash)
  newhash = {}
  newhash['fqdn'] = oldhash['fqdn'] || oldhash['id'].gsub('_', '.') # Fix the fqdn, since periods couldn't be used in the databag ID.
  newhash['chef_environment'] = oldhash['chef_environment']
  begin
    newhash['chef_environment'] ||= oldhash.chef_environment # In case it's an actual Chef node and not a hash emulating one.
  rescue
  end
  newhash['rdiff-backup'] = oldhash['rdiff-backup'].to_hash
  return newhash
end

# Recursive bot.merge!(top) for hashes.
def deep_merge!(bot, top)
  bot.merge!(top) { |k, botv, topv| (botv.class == Hash and topv.class == Hash) ? deep_merge!(botv, topv) : topv}
end

# Recursive bot.merge(top) for hashes; returns new hash rather than modifying the bottom one.
def deep_merge(bot, top)
  deep_merge!(deep_copy(bot), top)
end

# Attribute hashes. These store the various levels of attributes so they can be merged together properly once we have determined all of them. See the README for explanation of attribute precedence.
# 'node' covers level 1 (cookbook default attributes) and level 2 (server node attributes).
servernode = deep_copy_node(node) # Covers level 3 (server databag attributes) once the contents of the server databag item are merged over it (if it exists).
clientsearchnodes = {} # Covers level 4 (client node attributes) once it is filled with client nodes from chef search, keyed by fqdn.
clientdatabagnodes = {} # Covers level 5 (client databag attributes) once it is filled with client nodes from the databag, keyed by fqdn.
clientnodes = [] # Merges clientdatabagnodes over clientsearchnodes, not keyed.

# Removes a job, deleting the files associated with it.
def remove_job(job, servernode)

  # Remove the script.
  scriptpath = File.join('/home', servernode['rdiff-backup']['server']['user'], 'scripts', job['name'])
  File.delete(scriptpath) if File.exists?(scriptpath)

  # Remove the exclusion file if it's an fs job.
  if job['type'] == 'fs'
    excludepath = File.join('/home', servernode['rdiff-backup']['server']['user'], 'exclude', job['name'])
    File.delete(excludepath) if File.exists?(excludepath)
  end

  # Remove the Nagios check.
  nagios_nrpecheck "check_rdiff-backup_#{job['name']}" do
    action :remove
  end
end

# Find nodes to back up by searching.
Chef::Log.info("Beginning search for nodes. This may take some time depending on your node count.")
query = 'recipes:rdiff-backup\:\:client'
keys = {
  'fqdn'              => [ 'fqdn' ],
  'chef_environment'  => [ 'chef_environment' ],
  'rdiff-backup'      => [ 'rdiff-backup' ]
}
begin
  searchnodes = partial_search(:node, query, :keys => keys)
rescue
  begin
    Chef::Log.warn("Partial search failed; reverting to normal search.")
    searchnodes = search(:node, query)
  rescue
    Chef::Log.warn("Normal search failed; not searching.")
    searchnodes = []
  end
end
searchnodes.each do |n|
  searchnode = deep_copy_node(n)
  clientsearchnodes[searchnode['fqdn']] = searchnode
end

# Find nodes to back up from the hosts databag too.
begin
  databaghosts = data_bag(HOSTS_DATABAG).to_set
  databaghosts.each do |databagitem|
    databagnode = deep_copy_node(data_bag_item(HOSTS_DATABAG, databagitem)) # Read a "node" from the databag.
    if databagnode.fetch('rdiff-backup',{})['server'] and servernode['fqdn'] == databagnode['fqdn']
      deep_merge!(servernode, databagnode) # If we found the server databag, merge that over the servernode hash.
    end
    if databagnode.fetch('rdiff-backup',{})['client']
      clientdatabagnodes[databagnode['fqdn']] = databagnode # If it's a client, keep it in our list of databag nodes.
    end
  end
rescue
  Chef::Log.warn("Unable to load databag '#{HOSTS_DATABAG}'")
end

# Merge clientdatabagnodes over clientsearchnodes.
clientdatabagnodes.each do |dfqdn, dnode|
  if clientsearchnodes[dfqdn]
    deep_merge!(clientsearchnodes[dfqdn], dnode)
  else
    clientsearchnodes[dfqdn] = dnode
  end
end
clientnodes = clientsearchnodes.values

# Filter out clients in the wrong environments, if applicable.
if servernode['rdiff-backup']['server']['restrict-to-own-environment']
  filterenvs = [servernode['chef_environment']]
else
  filterenvs = servernode['rdiff-backup']['server']['restrict-to-environments']
end
if not filterenvs.empty?
  clientnodes.dup.each do |n|
    if not filterenvs.include?(n['chef_environment'])
      clientnodes.delete(n)
    end
  end
end

# Merge all client nodes over the server node so they get server defaults.
newclientnodes = []
clientnodes.each do |n|
  newclientnodes << deep_merge(servernode, n)
end
clientnodes = newclientnodes

if clientnodes.empty?
  Chef::Log.warn("No nodes returned from search or found in the '#{HOSTS_DATABAG}' databag.")
end

# Install required packages.
include_recipe 'yum'
include_recipe 'yum-epel'
%w[ rdiff-backup cronolog ].each do |p|
  package p
end

# Create the server backup group.
group servernode['rdiff-backup']['server']['user'] do
  system true
end

# Create the server backup user.
user servernode['rdiff-backup']['server']['user'] do
  comment 'User for rdiff-backup server backups'
  gid servernode['rdiff-backup']['server']['user']
  system true
  shell '/bin/bash'
  home File.join('/home', servernode['rdiff-backup']['server']['user'])
  supports :manage_home => true
end

# Note: The server backup user's private key must be copied over manually.

# Copy over and set up the Nagios nrpe plugin, if applicable.
if servernode['rdiff-backup']['server']['nagios']['enable']

  # Copy over the check_rdiff and check_rdiff_log nrpe plugins.
  directory servernode['rdiff-backup']['server']['nagios']['plugin-dir'] do
    mode '775'
    recursive true
    action :create
  end
  cookbook_file File.join(servernode['rdiff-backup']['server']['nagios']['plugin-dir'], 'check_rdiff') do
    source File.join('nagios', 'plugins', 'check_rdiff')
    mode '775'
    action :create
  end
  cookbook_file File.join(servernode['rdiff-backup']['server']['nagios']['plugin-dir'], 'check_rdiff_log') do
    source File.join('nagios', 'plugins', 'check_rdiff_log')
    mode '775'
    action :create
  end

  # Give the user sudo access for the nrpe plugins.
  if servernode['rdiff-backup']['server']['sudo']
    begin
      sudo 'nrpe' do
        user      'nrpe'
        runas     'root'
        nopasswd  true
        commands  [File.join(node['nagios']['plugin_dir'], 'check_rdiff'), File.join(node['nagios']['plugin_dir'], 'check_rdiff_log')]
      end
    rescue
      Chef::Log.warn("Unable to provide sudo access to nrpe user 'nrpe'")
    end
  end

end

jobs = []

# For each node, create a new job object for each job by merging attributes.
clientnodes.each do |n|

  Chef::Log.info("Creating jobs for host '#{n['fqdn']}'.")

  srcs = Set.new
  if servernode['rdiff-backup']['server']['fs']['enable'] and n['rdiff-backup']['client']['fs']['enable']
    srcs.merge(servernode['rdiff-backup']['server']['fs']['jobs'].keys)
    srcs.merge(n['rdiff-backup']['client']['fs']['jobs'].keys)
    srcs.each do |src|
      if src.start_with?("/") # Only work with absolute paths.

        job = deep_copy(servernode['rdiff-backup']['server']['fs']['job-defaults']) # Start with the server's default attributes. (Levels 1, 2, and 3)
        deep_merge!(job, n['rdiff-backup']['client']['fs']['job-defaults'] || {}) # Merge the client's default attributes over the top. (Levels 4 and 5)
        deep_merge!(job, servernode['rdiff-backup']['server']['fs']['jobs'][src] || {}) # Merge the server's job-specific attributes over the top. (Levels 6 and 7)
        deep_merge!(job, n['rdiff-backup']['client']['fs']['jobs'][src] || {}) # Merge the client's job-specific attributes over the top. (Levels 8 and 9)

        job['type'] = 'fs'
        # Keep higher-level attributes in the job object for convenience.
        job['source'] = src
        job['fqdn'] = n['fqdn']
        job['name'] = "#{job['type']}_#{job['fqdn']}_#{job['source'].gsub("/", "-")}" # Name is used for referencing this job and is unique.
        job['user'] = n['rdiff-backup']['client']['user']
        job['ssh-port'] = n['rdiff-backup']['client']['ssh-port']
        job['ssh-key'] = n['rdiff-backup']['client']['fs']['ssh-key']

        # Remove exclusion rules that don't apply to this job
        relevantdirs = []
        job['exclude-dirs'].each do |dir|
          relevantdirs << dir if dir.start_with?(src) or dir.start_with?('*')
        end
        job['exclude-dirs'] = relevantdirs

        jobs << job
      end
    end
  end

  mysqldbs = Set.new
  if servernode['rdiff-backup']['server']['mysql']['enable'] and n['rdiff-backup']['client']['mysql']['enable']
    mysqldbs.merge(servernode['rdiff-backup']['server']['mysql']['jobs'].keys)
    mysqldbs.merge(n['rdiff-backup']['client']['mysql']['jobs'].keys)

    # If there are no databases specified, create jobs for each database.
    if mysqldbs.empty?
      include_recipe 'mysql::client'
      #TODO: Use mysql2 gem instead of shelling out?
      #chef_gem 'mysql2'
      #mysqlconn = Mysql2::Client.new(:host => n['fqdn'], :username => "rdiff-backup")
      #mysqldbs = mysqlconn.query("SHOW DATABASES")
      command = "ssh -i #{File.join('/home', servernode['rdiff-backup']['server']['user'], '.ssh', 'id_rsa')} -p #{n['rdiff-backup']['client']['ssh-port']} #{n['rdiff-backup']['client']['user']}@#{n['fqdn']} mysql -e 'SHOW\\ DATABASES' -u #{n['rdiff-backup']['client']['mysql']['mysql-user']} -p'#{n['rdiff-backup']['client']['mysql']['mysql-password']}' --column-names=0"
      mysqldbs = `#{command}`.split()
      if mysqldbs.empty?
        Chef::Log.warn("Unable to connect to database '#{n['rdiff-backup']['client']['mysql']['mysql-user']}@#{n['fqdn']}'")
      end
    end

    mysqldbs.each do |db|
      job = deep_copy(servernode['rdiff-backup']['server']['mysql']['job-defaults']) # Start with the server's default attributes. (Levels 1, 2, and 3)
      deep_merge!(job, n['rdiff-backup']['client']['mysql']['job-defaults'] || {}) # Merge the client's default attributes over the top. (Levels 4 and 5)
      deep_merge!(job, servernode['rdiff-backup']['server']['mysql']['jobs'][db] || {}) # Merge the server's job-specific attributes over the top. (Levels 6 and 7)
      deep_merge!(job, n['rdiff-backup']['client']['mysql']['jobs'][db] || {}) # Merge the client's job-specific attributes over the top. (Levels 8 and 9)

      job['type'] = 'mysql'
      # Keep higher-level attributes in the job object for convenience.
      job['source'] = db
      job['fqdn'] = n['fqdn']
      job['name'] = "#{job['type']}_#{job['fqdn']}_#{job['source']}" # Name is used for referencing this job and is unique.
      job['user'] = n['rdiff-backup']['client']['user']
      job['ssh-port'] = n['rdiff-backup']['client']['ssh-port']
      job['ssh-key'] = n['rdiff-backup']['client']['mysql']['ssh-key']

      jobs << job
    end
  end
end

# Keep the set of jobs in "bare" format too so we can compare with the "bare" pre-existing jobs.
specifiedjobs = Set.new
jobs.each do |job|
  newjob = {} # Create a new "bare" job with just enough information to identify it.
  newjob['name'] = job['name']
  specifiedjobs << newjob
end

# Get the set of jobs which already exist so we can decide which ones to remove.
existingjobs = Set.new
if File.exists?(CRON_FILE)
  File.open(CRON_FILE, "r") do |file|
    file.each_line do |line|
      if line.match(/^\D.*/) == nil # Only parse lines that start with numbers, i.e. actual jobs.
        newjob = {} # Create a new "bare" job with just enough information to identify it.
        newjob['name'] = line.gsub(/.*\/(.*?)/, '\1').strip
      end
    end
  end
end

# Get the set of jobs that need to be removed by subtracting the set of specified jobs by the set of existing jobs.
removejobs = existingjobs.dup.subtract(specifiedjobs)

# Sort jobs by name to provide stable ordering
jobs.sort! {|a,b| a['name'] <=> b['name'] }

# Figure out how much time to wait between starting jobs.
unless jobs.empty?
  minutesbetweenjobs = ((servernode['rdiff-backup']['server']['end-hour'] - servernode['rdiff-backup']['server']['start-hour'] + 24) % 24 * 60.0 ) / jobs.size
end

services = []

# Set up each job.
setjobs = 0
jobs.each do |job|

  # Shorten some long variables for readability.
  type = job['type']
  fqdn = job['fqdn']
  suser = servernode['rdiff-backup']['server']['user']
  maxchange = job['nagios']['max-change']
  latestart = job['nagios']['max-late-start']
  if type == 'fs'
    sd = job['source']
    dd = File.join(job['destination-dir'], 'fs', fqdn, sd)
    servicename = "rdiff-backup_#{job['name']}"
  elsif type == 'mysql'
    db = job['source']
    tmpd = File.join(job['destination-dir'], 'tmp', 'mysql', fqdn, db)
    dd = File.join(job['destination-dir'], 'mysql', fqdn, db)
    servicename = "rdiff-backup_#{job['name']}"
  end
  nrpecheckname = "check_rdiff-backup_#{job['name']}"

  # Ensure the base directory that this backup will go to exists and provides write permission to the rdiff-backup user.
  directory job['destination-dir'] do
    owner suser
    group suser
    mode '775'
    recursive true
    action :create
  end

  # Set run times for each job, distributing them evenly across a certain time period every day.
  job['minute'] = (minutesbetweenjobs * setjobs) % 60
  job['hour'] = ((minutesbetweenjobs * setjobs / 60).floor + servernode['rdiff-backup']['server']['start-hour']) % 24
  setjobs += 1

  # Create the exclude files for each job.
  if type == 'fs'
    directory File.join('/home', suser, 'exclude') do
      owner suser
      group suser
      mode '775'
      recursive true
      action :create
    end
    template File.join('/home', suser, 'exclude', job['name']) do
      source 'exclude.erb'
      owner suser
      group suser
      mode '664'
      variables({
        :src => sd,
        :paths => job['exclude-dirs'],
      })
      action :create
    end
  end

  # Create scripts for each job.
  directory File.join('/home', suser, 'scripts') do
    owner suser
    group suser
    mode '775'
    recursive true
    action :create
  end

  if type == 'fs'
    template File.join('/home', suser, 'scripts', job['name']) do
      source 'fs-job.sh.erb'
      owner suser
      group suser
      mode '774'
      variables({
        :name => job['name'],
        :fqdn => fqdn,
        :src => sd,
        :dest => dd,
        :period => job['retention-period'],
        :suser => suser,
        :cuser => job['user'],
        :port => job['ssh-port'],
        :key => job['ssh-key'],
        :args => job['additional-args']
      })
      action :create
    end
  elsif type == 'mysql'
    template File.join('/home', suser, 'scripts', job['name']) do
      source 'mysql-job.sh.erb'
      owner suser
      group suser
      mode '774'
      variables({
        :fqdn => fqdn,
        :db => db,
        :tempdest => tmpd,
        :dest => dd,
        :period => job['retention-period'],
        :suser => suser,
        :cuser => job['user'],
        :muser => job['mysql-user'],
        :mpass => job['mysql-password'],
        :port => job['ssh-port'],
        :key => job['ssh-key'],
        :args => job['additional-args']
      })
      action :create
    end
  end
  
  # If nagios alerts are enabled and the backup directory exists, ensure there are nagios alerts for the job.
  if servernode['rdiff-backup']['server']['nagios']['enable'] and job['nagios']['enable'] and File.exists?(File.join(dd, 'rdiff-backup-data'))

    latefinwarn = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-warning'] # Minute is ceiling'd up to the next hour
    latefincrit = job['hour'] + (job['minute']+59)/60 + job['nagios']['max-late-finish-critical'] # Minute is ceiling'd up to the next hour

    newservice = {
      'id' => servicename,
      'command_line' => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{nrpecheckname}",
      'host_name' => servernode['fqdn']
    }
    services << newservice

    nagios_nrpecheck nrpecheckname do
      command "sudo #{servernode['rdiff-backup']['server']['nagios']['plugin-dir']}/check_rdiff -r #{dd} -w #{latefinwarn} -c #{latefincrit} -l #{maxchange} -p #{latestart}"
      action :add
    end

  end
end

# If nagios alerts are enabled, create the log check alert.
servicename = 'rdiff-backup_log'
nrpecheckname = 'check_rdiff-backup_log'
if servernode['rdiff-backup']['server']['nagios']['enable']

  newservice = {
    'id' => servicename,
    'command_line' => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{nrpecheckname}",
    'host_name' => servernode['fqdn']
  }
  services << newservice

  nagios_nrpecheck nrpecheckname do
    command "sudo #{servernode['rdiff-backup']['server']['nagios']['plugin-dir']}/check_rdiff_log"
    action :add
  end
else
  nagios_nrpecheck nrpecheckname do
    action :remove
  end
end

# Set up Nagios remote attributes.
node.set['nagios']['remote_services'] = services

# Create the crontab for all the jobs.
template CRON_FILE do
  source 'cron.d.erb'
  mode '644'
  variables({
    :shour => servernode['rdiff-backup']['server']['start-hour'],
    :ehour => servernode['rdiff-backup']['server']['end-hour'],
    :mailto => servernode['rdiff-backup']['server']['mailto'],
    :suser => servernode['rdiff-backup']['server']['user'],
    :jobs => jobs
  })
  action :create
end

# Create the log directory.
directory LOG_DIR do
  owner servernode['rdiff-backup']['server']['user']
  group servernode['rdiff-backup']['server']['user']
  mode '775'
  recursive true
  action :create
end

# Create a symlink to the log directory from the home directory.
link File.join('/home', servernode['rdiff-backup']['server']['user'], 'logs') do
  owner servernode['rdiff-backup']['server']['user']
  group servernode['rdiff-backup']['server']['user']
  mode '775'
  link_type :symbolic
  to LOG_DIR
  action :create
end

# Give the server user sudo access for su-ing to the rdiff-backup-client user in case the server is also a client.
if servernode['rdiff-backup']['server']['sudo']
  node.force_override['authorization']['sudo']['include_sudoers_d'] = true
  user = servernode['rdiff-backup']['server']['user']
  begin
    sudo user do
      user      user
      runas     servernode['rdiff-backup']['client']['user']
      nopasswd  true
      commands  ['/usr/bin/sudo rdiff-backup --server --restrict-read-only /']
      defaults  ['!requiretty']
    end
  rescue
    Chef::Log.warn("Unable to provide sudo access to rdiff-backup user '#{user}'")
  end
end

# Remove all jobs that need to be removed.
removejobs.each do |job|
  remove_job(job, servernode)
end
