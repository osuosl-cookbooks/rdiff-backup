provides :rdiff_backup
unified_mode true

default_action :create

property :source, String, default: '/'
property :destination, String, default: '/data/rdiff-backup'
property :fqdn, String
property :cookbook, String, default: 'rdiff-backup'
property :remote_user, String, default: 'rdiff-backup-client'
property :ssh_port, [String, Integer], default: 22
property :retention_period, String, default: '1W'
property :args, String, default: ''
property :data_bag, String, default: 'rdiff-backup-ssh'
property :nrpe_warning, String, default: '16'
property :nrpe_critical, String, default: '18'
property :nrpe_period, String, default: '24'
property :nrpe_transferred, String, default: '800000000'
property :exclude, Array, default: []
property :cron_minute, [String, Integer], default: '0'
property :cron_hour, [String, Integer], default: '0'
property :cron_day, [String, Integer], default: '*'
property :cron_weekday, [String, Integer], default: '*'
property :cron_month, [String, Integer], default: '*'

action :create do
  include_recipe 'rdiff-backup::server'

  if node['rdiff-backup']['server']['nrpe']
    include_recipe 'nrpe'

    nrpe_check "check_rdiff_job_#{new_resource.name}" do
      command '/usr/bin/sudo ' + ::File.join(
        node['nrpe']['plugin_dir'], 'check_rdiff '
      ) + "-w #{new_resource.nrpe_warning} "\
          "-c #{new_resource.nrpe_critical} "\
          "-r #{new_resource.destination} "\
          "-p #{new_resource.nrpe_period} "\
          "-l #{new_resource.nrpe_transferred}"
    end
  end

  [
    new_resource.destination,
    ::File.join('/home', node['rdiff-backup']['server']['user'], 'exclude', new_resource.fqdn),
    ::File.join('/home', node['rdiff-backup']['server']['user'], 'scripts', new_resource.fqdn),
  ].each do |d|
    directory d do
      owner node['rdiff-backup']['server']['user']
      group node['rdiff-backup']['server']['group'] || node['rdiff-backup']['server']['user']
      recursive true
    end
  end

  file ::File.join('/home',
                   node['rdiff-backup']['server']['user'],
                   'exclude',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    owner node['rdiff-backup']['server']['user']
    group node['rdiff-backup']['server']['group'] || node['rdiff-backup']['server']['user']
    mode '0644'
    content new_resource.exclude.join("\n")
  end

  filename = ::File.join('/home',
                         node['rdiff-backup']['server']['user'],
                         'scripts',
                         new_resource.fqdn,
                         new_resource.source.tr('/', '_'))

  template filename do
    source 'job.sh.erb'
    mode '0775'
    owner node['rdiff-backup']['server']['user']
    group node['rdiff-backup']['server']['group']
    cookbook new_resource.cookbook
    variables(
      fqdn: new_resource.fqdn,
      src: new_resource.source,
      dest: new_resource.destination,
      period: new_resource.retention_period,
      server_user: node['rdiff-backup']['server']['user'],
      client_user: new_resource.remote_user,
      port: new_resource.ssh_port,
      args: new_resource.args
    )
  end

  cron new_resource.name do
    minute new_resource.cron_minute
    hour new_resource.cron_hour
    day new_resource.cron_day
    weekday new_resource.cron_weekday
    month new_resource.cron_month
    user node['rdiff-backup']['server']['user']
    command [
      '/usr/bin/flock',
      node['rdiff-backup']['server']['lock_dir'] + '/' + new_resource.name,
      filename,
    ].join(' ')
  end
end

action :delete do
  if node['rdiff-backup']['server']['nrpe']
    nrpe_check "check_rdiff_job_#{new_resource.name}" do
      action :remove
    end
  end

  file ::File.join('/home',
                   node['rdiff-backup']['server']['user'],
                   'exclude',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    action :delete
  end

  file ::File.join('/home',
                   node['rdiff-backup']['server']['user'],
                   'scripts',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    action :delete
  end

  cron new_resource.name do
    user node['rdiff-backup']['server']['user']
    command [
        '/usr/bin/flock',
        node['rdiff-backup']['server']['lock_dir'] + '/' + new_resource.name,
        filename,
    ].join(' ')
    action :delete
  end

  [
    ::File.join('/home', node['rdiff-backup']['server']['user'], 'exclude', new_resource.fqdn),
    ::File.join('/home', node['rdiff-backup']['server']['user'], 'scripts', new_resource.fqdn),
  ].each do |d|
    directory d do
      recursive true
      action :delete
    end
  end
end
