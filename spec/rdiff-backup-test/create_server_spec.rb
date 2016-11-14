require_relative '../spec_helper'

describe 'rdiff-backup-test::server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup'])
        )
      end
      cached(:chef_run) { runner.converge(described_recipe) }
      before do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with(
          'rdiff-backup-secrets', 'secrets'
        ).and_return(
          key: 'secret-key'
        )
      end
      # Tests lines [74:end] of the libraries/rdiff-backup.rb file
      it do
        expect(chef_run).to include_recipe('yum-epel')
      end
      # line 76
      %w(rdiff-backup cronolog).each do |p|
        it do
          expect(chef_run).to install_package(p)
        end
      end
      # lines 77:97, because new_resource.nrpe defaults to true
      it do
        expect(chef_run).to create_cookbook_file(
          chef_run.node['nrpe']['plugin_dir'] + '/check_rdiff'
        ).with(
          mode: 0755,
          owner: chef_run.node['nrpe']['user'],
          group: chef_run.node['nrpe']['group'],
          source: 'nagios/plugins/check_rdiff',
          cookbook: 'rdiff-backup'
        )
      end
      it do
        expect(chef_run).to add_nrpe_check('check_rdiff_job_test1').with(
          command: '/usr/bin/sudo /usr/lib64/nagios/plugins/check_rdiff' \
            ' -w 16 '\
            '-c 18 '\
            '-r /you/are/my/only/hope '\
            '-p 24 '\
            '-l 800000000'
        )
      end
      # line 100
      it do
        expect(chef_run).to create_user('rdiff-backup-server')
      end
      # line 101
      it do
        # group == owner, so group is NOT created here
        expect(chef_run).to_not create_group('rdiff-backup-server')
      end
      # lines 102:108
      it do
        expect(chef_run).to install_sudo('rdiff-backup-server').with(
          user: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          nopasswd: true,
          commands: ['/usr/bin/sudo rdiff-backup '\
                     '--server --restrict-read-only /']
        )
      end
      # lines 109:114
      it do
        expect(chef_run).to create_directory('/var/rdiff-backup/locks').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: 0755,
          recursive: true
        )
      end
      # lines 115:119
      it do
        expect(chef_run).to create_directory(
          '/home/rdiff-backup-server/.ssh'
        ).with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: 0700
        )
      end
      # lines 120:123
      # undefined method create_ssh_user
      it do
        expect(chef_run).to create_ssh_user('id_rsa').with(
          user: 'rdiff-backup-server'
        )
      end
      # lines 124:129
      it do
        expect(chef_run).to create_directory('/var/log/rdiff-backup').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: 0755,
          recursive: true
        )
      end
      # lines 130:146
      %w(/you/are/my/only/hope
         /home/rdiff-backup-server/exclude/192.168.60.11
         /home/rdiff-backup-server/scripts/192.168.60.11).each do |d|
        it do
          expect(chef_run).to create_directory(d).with(
            owner: 'rdiff-backup-server',
            group: 'rdiff-backup-server' || 'rdiff-backup-server',
            recursive: true
          )
        end
      end
      # lines 147:156
      it do
        expect(chef_run).to create_file(
          '/home/rdiff-backup-server/exclude/192.168.60.11/_help_me_obiwan'
        ).with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: 0644,
          content: [
            '**/darth-vader', '/help/me/obiwan/emperor-palpatine'
          ].join("\n")
        )
      end
      # lines 157:178
      it do
        expect(chef_run).to create_template(
          '/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan'
        ).with(
          source: 'job.sh.erb',
          mode: 0775,
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          cookbook: 'rdiff-backup',
          variables: {
            fqdn: '192.168.60.11',
            src: '/help/me/obiwan',
            dest: '/you/are/my/only/hope',
            period: '1W',
            server_user: 'rdiff-backup-server',
            client_user: 'rdiff-backup-client',
            port: 22,
            args: ''
          }
        )
      end
      # lines 179:189
      it do
        expect(chef_run).to create_cron('test1').with(
          minute: '0',
          hour: '0',
          day: '*',
          weekday: '*',
          month: '*',
          user: 'rdiff-backup-server',
          command: '/usr/bin/flock /var/rdiff-backup/locks/test1 '\
          '/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan'
        )
      end
    end
  end
end
