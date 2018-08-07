resource_name :rdiff_backup

default_action :create

property :owner, String, default: 'rdiff-backup-server'
property :group, String, default: 'rdiff-backup-server'
property :source, String, default: '/'
property :destination, String, default: '/data/rdiff-backup'
property :fqdn, String
property :cookbook, String, default: 'rdiff-backup'
property :remote_user, String, default: 'rdiff-backup-client'
property :ssh_port, [String, Integer], default: 22
property :retention_period, String, default: '1W'
property :args, String, default: ''
property :lock_dir, String, default: '/var/rdiff-backup/locks'
property :data_bag, String, default: 'rdiff-backup-ssh'
property :nrpe, [true, false], default: true
property :nrpe_warning, String, default: '16'
property :nrpe_critical, String, default: '18'
property :nrpe_period, String, default: '24'
property :nrpe_transferred, String, default: '800000000'
property :exclude, Array, default: []
property :cron_minute, [String, Integer], default: 0
property :cron_hour, [String, Integer], default: 0
property :cron_day, [String, Integer], default: '*'
property :cron_weekday, [String, Integer], default: '*'
property :cron_month, [String, Integer], default: '*'

def resource_exists(type, name)
  !::ObjectSpace.each_object(::Chef::Resource).select do |r|
    r.run_context.equal?(run_context) && r.resource_name == type && r.name == name
  end.empty?
end

action :create do
  include_recipe 'yum-epel'

  %w(rdiff-backup cronolog).each do |p|
    package p unless resource_exists(:yum_package, p) # ~FC023
  end

  if new_resource.nrpe
    include_recipe 'nrpe'

    plugin_file = ::File.join(node['nrpe']['plugin_dir'], 'check_rdiff')
    unless resource_exists(:cookbook_file, plugin_file) # ~FC023
      cookbook_file plugin_file do
        mode 0755
        cookbook 'rdiff-backup'
        owner node['nrpe']['user']
        group node['nrpe']['group']
        source 'nagios/plugins/check_rdiff'
        cookbook 'rdiff-backup'
      end
    end

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

  secrets = ::Chef::EncryptedDataBagItem.load('rdiff-backup-secrets',
                                              'secrets')

  user new_resource.owner unless resource_exists(:linux_user, new_resource.owner) # ~FC023

  unless resource_exists(:group, new_resource.group) || new_resource.owner == new_resource.group # ~FC023
    group new_resource.group
  end

  unless resource_exists(:sudo, new_resource.owner) # ~FC023
    sudo new_resource.owner do
      user new_resource.owner
      group new_resource.group
      nopasswd true
      commands ['/usr/bin/sudo rdiff-backup '\
                '--server --restrict-read-only /']
    end
  end

  unless resource_exists(:directory, new_resource.lock_dir) # ~FC023
    directory new_resource.lock_dir do
      owner new_resource.owner
      group new_resource.group || new_resource.owner
      mode 0755
      recursive true
    end
  end

  dir_path = ::File.join('/home', new_resource.owner, '.ssh')
  unless resource_exists(:directory, dir_path) # ~FC023
    directory dir_path do
      owner new_resource.owner
      group new_resource.group || new_resource.owner
      recursive true
      mode 0700
    end
  end

  key_path = new_resource.owner == 'root' ? '/root/.ssh' : "/home/#{new_resource.owner}/.ssh"
  unless resource_exists(:file, "#{key_path}/id_rsa") # ~FC023
    file "#{key_path}/id_rsa" do
      content secrets['ssh-key']
      mode 0600
      owner new_resource.owner
    end
  end

  unless resource_exists(:directory, '/var/log/rdiff-backup') # ~FC023
    directory '/var/log/rdiff-backup' do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      recursive true
    end
  end

  [
    new_resource.destination,
    ::File.join('/home',
                new_resource.owner,
                'exclude',
                new_resource.fqdn),
    ::File.join('/home',
                new_resource.owner,
                'scripts',
                new_resource.fqdn),
  ].each do |d|
    directory d do
      owner new_resource.owner
      group new_resource.group || new_resource.owner
      recursive true
    end
  end

  file ::File.join('/home',
                   new_resource.owner,
                   'exclude',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    owner new_resource.owner
    group new_resource.group || new_resource.owner
    mode 0644
    content new_resource.exclude.join("\n")
  end

  filename = ::File.join('/home',
                         new_resource.owner,
                         'scripts',
                         new_resource.fqdn,
                         new_resource.source.tr('/', '_'))

  template filename do
    source 'job.sh.erb'
    mode 0775
    owner new_resource.owner
    group new_resource.group
    cookbook new_resource.cookbook
    variables(
      fqdn: new_resource.fqdn,
      src: new_resource.source,
      dest: new_resource.destination,
      period: new_resource.retention_period,
      server_user: new_resource.owner,
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
    user new_resource.owner
    command ['/usr/bin/flock',
             new_resource.lock_dir + '/' + new_resource.name,
             filename].join(' ')
  end
end

action :delete do
  if new_resource.nrpe # ~FC023
    nrpe_check "check_rdiff_job_#{new_resource.name}" do
      action :remove
    end
  end

  file ::File.join('/home',
                   new_resource.owner,
                   'exclude',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    action :delete
  end

  file ::File.join('/home',
                   new_resource.owner,
                   'scripts',
                   new_resource.fqdn,
                   new_resource.source.tr('/', '_')) do
    action :delete
  end

  cron new_resource.name do
    action :delete
  end

  [
    ::File.join('/home',
                new_resource.owner,
                'exclude',
                new_resource.fqdn),
    ::File.join('/home',
                new_resource.owner,
                'scripts',
                new_resource.fqdn),
  ].each do |d|
    directory d do
      recursive true
      action :delete
    end
  end
end
