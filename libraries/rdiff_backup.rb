class Chef
  class Resource
    class RdiffBackup < LWRPBase
      self.resource_name = 'rdiff_backup'
      actions :create, :delete
      default_action :create

      attribute :owner, kind_of: String, default: 'rdiff-backup-server'
      attribute :group, kind_of: String, default: 'rdiff-backup-server'
      attribute :source, kind_of: String, default: '/'
      attribute :destination, kind_of: String, default: '/data/rdiff-backup'
      attribute :fqdn, kind_of: String
      attribute :cookbook, kind_of: String, default: 'rdiff-backup'
      attribute :remote_user, kind_of: String, default: 'rdiff-backup-client'
      attribute :ssh_port, kind_of: [String, Integer], default: 22
      attribute :retention_period, kind_of: String, default: '1W'
      attribute :args, kind_of: String, default: ''
      attribute :lock_dir, kind_of: String, default: '/var/rdiff-backup/locks'
      attribute :data_bag, kind_of: String, default: 'rdiff-backup-ssh'
      attribute :nrpe, kind_of: [TrueClass, FalseClass], default: true
      attribute :nrpe_warning, kind_of: String, default: '2'
      attribute :nrpe_critical, kind_of: String, default: '3'
      attribute :nrpe_period, kind_of: String, default: '24'
      attribute :nrpe_transferred, kind_of: String, default: '800000000'
      attribute :exclude, kind_of: Array, default: []
      attribute :cron_minute, kind_of: [String, Integer], default: 0
      attribute :cron_hour, kind_of: [String, Integer], default: 0
      attribute :cron_day, kind_of: [String, Integer], default: '*'
      attribute :cron_weekday, kind_of: [String, Integer], default: '*'
      attribute :cron_month, kind_of: [String, Integer], default: '*'
    end
  end
  class Provider
    class RdiffBackup < LWRPBase
      action :delete do
        if new_resource.nrpe # ~FC023
          nrpe_check "check_rdiff_job_#{new_resource.name}" do
            action :delete
          end
        end
        file ::File.join('/home',
                         new_resource.owner,
                         'exclude',
                         new_resource.fqdn,
                         new_resource.source.gsub('/', '_')) do
          action :delete
        end
        filename = ::File.join('/home',
                               new_resource.owner,
                               'scripts',
                               new_resource.fqdn,
                               new_resource.source.gsub('/', '_'))
        template filename do
          action :delete
        end

        cron new_resource.name do
          action :delete
        end
        [::File.join('/home',
                     new_resource.owner,
                     'exclude',
                     new_resource.fqdn),
         ::File.join('/home',
                     new_resource.owner,
                     'scripts',
                     new_resource.fqdn)
        ].each do |d|
          directory d do
            action :delete
          end
        end
      end
      action :create do
        include_recipe 'yum-epel'
        %w(rdiff-backup cronolog).each { |p| package p }
        if new_resource.nrpe
          include_recipe 'nrpe'
          cookbook_file ::File.join(node['nrpe']['plugin_dir'],
                                    'check_rdiff') do
            mode 0755
            cookbook 'rdiff-backup'
            owner node['nrpe']['user']
            group node['nrpe']['group']
            source 'nagios/plugins/check_rdiff'
            cookbook 'rdiff-backup'
          end
          nrpe_check "check_rdiff_job_#{new_resource.name}" do
            command ::File.join(node['nrpe']['plugin_dir'],
                                'check_rdiff '
                               ) + "-w #{new_resource.nrpe_warning} "\
                                   "-c #{new_resource.nrpe_critical} "\
                                   "-r #{new_resource.destination} "\
                                   "-p #{new_resource.nrpe_period} "\
                                   "-l #{new_resource.nrpe_transferred}"
          end
        end
        secrets = ::Chef::EncryptedDataBagItem.load('rdiff-backup-secrets',
                                                    'secrets')
        user new_resource.owner
        group new_resource.group unless new_resource.owner == new_resource.group
        sudo new_resource.owner do
          user new_resource.owner
          group new_resource.group
          commands ['/usr/bin/sudo rdiff-backup'\
                    '--server --restrict-read-only /']
        end
        directory new_resource.lock_dir do
          owner new_resource.owner
          group new_resource.group || new_resource.owner
          mode 0755
          recursive true
        end
        directory ::File.join('/home', new_resource.owner, '.ssh') do
          owner new_resource.owner
          group new_resource.group || new_resource.owner
          mode 0700
        end
        ssh_user_private_key 'id_rsa' do
          user new_resource.owner
          key secrets['ssh-key']
        end
        directory '/var/log/rdiff-backup' do
          owner new_resource.owner
          group new_resource.group
          mode 0755
          recursive true
        end
        [new_resource.destination, ::File.join('/home',
                                               new_resource.owner,
                                               'exclude',
                                               new_resource.fqdn),
         ::File.join('/home',
                     new_resource.owner,
                     'scripts',
                     new_resource.fqdn)
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
                         new_resource.source.gsub('/', '_')) do
          owner new_resource.owner
          group new_resource.group || new_resource.owner
          mode 0644
          content new_resource.exclude.join("\n")
        end
        filename = ::File.join('/home',
                               new_resource.owner,
                               'scripts',
                               new_resource.fqdn,
                               new_resource.source.gsub('/', '_'))
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
    end
  end
end
