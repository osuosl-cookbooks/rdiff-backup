require_relative '../spec_helper'

describe 'rdiff-backup-test::create_server' do
  ALL_PLATFORMS.each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup'])
        )
      end
      cached(:chef_run) { runner.converge(described_recipe) }

      before do
        stub_data_bag_item('users', 'rdiff-backup-client').and_return(nil)
        stub_data_bag_item('rdiff-backup-secrets', 'secrets').and_return(
          key: 'secret-key'
        )
      end

      it do
        expect(chef_run).to create_rdiff_backup('test1').with(
          fqdn: '192.168.60.11',
          source: '/help/me/obiwan',
          destination: '/you/are/my/only/hope',
          exclude: ['**/darth-vader', '/help/me/obiwan/emperor-palpatine']
        )
      end

      it do
        expect(chef_run).to create_rdiff_backup('test2').with(
          fqdn: '192.168.60.12',
          source: '/test2',
          destination: '/backups/test2',
          exclude: ['**/foo', '/bar/foo']
        )
      end

      %w(
        yum-epel
        rdiff-backup::server
      ).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end

      it do
        expect(chef_run).to include_recipe('nrpe')
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

      it do
        expect(chef_run).to add_nrpe_check('check_rdiff_job_test2').with(
          command: '/usr/bin/sudo /usr/lib64/nagios/plugins/check_rdiff' \
            ' -w 16 '\
            '-c 18 '\
            '-r /backups/test2 '\
            '-p 24 '\
            '-l 800000000'
        )
      end

      %w(/you/are/my/only/hope
         /backups/test2
         /home/rdiff-backup-server/exclude/192.168.60.11
         /home/rdiff-backup-server/scripts/192.168.60.11
         /home/rdiff-backup-server/exclude/192.168.60.12
         /home/rdiff-backup-server/scripts/192.168.60.12).each do |d|
        it do
          expect(chef_run).to create_directory(d).with(
            owner: 'rdiff-backup-server',
            group: 'rdiff-backup-server' || 'rdiff-backup-server',
            recursive: true
          )
        end
      end

      it do
        expect(chef_run).to create_file(
          '/home/rdiff-backup-server/exclude/192.168.60.11/_help_me_obiwan'
        ).with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: '0644',
          content: [
            '**/darth-vader', '/help/me/obiwan/emperor-palpatine'
          ].join("\n")
        )
      end

      it do
        expect(chef_run).to create_file(
          '/home/rdiff-backup-server/exclude/192.168.60.12/_test2'
        ).with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: '0644',
          content: [
            '**/foo', '/bar/foo'
          ].join("\n")
        )
      end

      it do
        expect(chef_run).to create_template(
          '/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan'
        ).with(
          source: 'job.sh.erb',
          mode: '0775',
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
            args: '',
          }
        )
      end

      it do
        expect(chef_run).to create_template(
          '/home/rdiff-backup-server/scripts/192.168.60.12/_test2'
        ).with(
          source: 'job.sh.erb',
          mode: '0775',
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          cookbook: 'rdiff-backup',
          variables: {
            fqdn: '192.168.60.12',
            src: '/test2',
            dest: '/backups/test2',
            period: '1W',
            server_user: 'rdiff-backup-server',
            client_user: 'rdiff-backup-client',
            port: 22,
            args: '',
          }
        )
      end

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

      it do
        expect(chef_run).to create_cron('test2').with(
          minute: '0',
          hour: '0',
          day: '*',
          weekday: '*',
          month: '*',
          user: 'rdiff-backup-server',
          command: '/usr/bin/flock /var/rdiff-backup/locks/test2 '\
          '/home/rdiff-backup-server/scripts/192.168.60.12/_test2'
        )
      end
    end
  end
end
