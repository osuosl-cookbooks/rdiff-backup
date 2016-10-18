require_relative '../spec_helper'

describe 'rdiff-backup-test::server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup'])#, ['nrpe-check'])
        )
      end
      cached(:chef_run) { runner.converge(described_recipe) }

      before do
        stub_command('secrets').and_return(false)
        Chef::EncryptedDataBagItem.stub(:load).with('rdiff-backup-secrets',
                                                    'secrets').and_return(
                                                      key: 'secret-key'
                                                    )
      end

      #Delete
      # it do
      #   expect(chef_run).to remove_nrpe_check('check_rdiff_job_test1')
      # end
      # context 'Delete: nrpe is false' do
      #   let(:runner) do
      #     ChefSpec::SoloRunner.new(
      #       pltfrm.dup.merge(step_into: ['nrpe-check'])
      #     )
      #   end
      #   before do
      #     chef_run.node.default['rdiff-backup']['nrpe'] = false
      #     stub_command('secrets').and_return(false)
      #     Chef::EncryptedDataBagItem.stub(:load).with('rdiff-backup-secrets',
      #                                                 'secrets').and_return(
      #                                                   key: 'secret-key'
      #                                                 )
      #   end
      #   it do
      #     expect(chef_run).to_not remove_nrpe_check('check_rdiff_job_test1')
      #   end
      # end

      it do
        expect(chef_run).to delete_file(
          '/home/rdiff-backup-server/exclude/192.168.60.11/_help_me_obiwan'
        )
      end
      it do
        expect(chef_run).to delete_file(
          '/home/rdiff-backup-server/scripts/192.168.60.11/_help_me_obiwan'
        )
      end
      it do
        expect(chef_run).to delete_cron('test1')
      end
      %w(/home/rdiff-backup-server/exclude/192.168.60.11
         /home/rdiff-backup-server/scripts/192.168.60.11).each do |d|
        it do
          expect(chef_run).to delete_directory(d)
        end
      end


      #Create
      it do
        expect(chef_run).to include_recipe('yum-epel')
      end

      %w(rdiff-backup cronolog).each do |r|
        it do
          expect(chef_run).to install_package(r)
        end
      end

      it do
        expect(chef_run).to include_recipe('nrpe')
      end
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
      # it do
      #   expect(chef_run).to create_nrpe_check('check_rdiff_job_test1').with(
      #   command: '/usr/bin/sudo/' + chef_run.node['nrpe']['plugin_dir'] +
      #            'check_rdiff' + "-w 16 "\
      #                            "-c 18 "\
      #                            "-r /data/rdiff-backup "\
      #                            "-p 24 "\
      #                            "-l 800000000"
      #   )
      # end

        # context 'Create: nrpe is false' do
        #   let(:runner) do
        #     ChefSpec::SoloRunner.new(
        #       pltfrm.dup.merge(step_into: ['rdiff-backup', 'nrpe_check'])
        #     )
        #   end
        #   before do
        #     chef_run.node.default['rdiff-backup']['nrpe'] = false
        #     stub_command('secrets').and_return(false)
        #     Chef::EncryptedDataBagItem.stub(:load).with('rdiff-backup-secrets',
        #                                                 'secrets').and_return(
        #                                                   key: 'secret-key'
        #                                                 )
        #   end
          # %w(rdiff-backup cronolog).each do |r|
          #   it do
          #     expect(chef_run).to_not install_package(r)
          #   end
          # end
          # it do
          #   expect(chef_run).to_not include_recipe('nrpe')
          # end
          # it do
          #   expect(chef_run).to_not create_cookbook_file(
          #     chef_run.node['nrpe']['plugin_dir'] + '/check_rdiff'
          #     ).with(
          #     mode: 0755,
          #     owner: chef_run.node['nrpe']['user'],
          #     group: chef_run.node['nrpe']['group'],
          #     source: 'nagios/plugins/check_rdiff',
          #     cookbook: 'rdiff-backup'
          #     )
          # end
          # it do
          #   expect(chef_run).to create_nrpe_check('check_rdiff_job_test1').with(
          #   command: '/usr/bin/sudo/' + chef_run.node['nrpe']['plugin_dir'] +
          #            'check_rdiff' + "-w 16 "\
          #                            "-c 18 "\
          #                            "-r /data/rdiff-backup "\
          #                            "-p 24 "\
          #                            "-l 800000000"
          #   )
          # end
      # end

      it do
        expect(chef_run).to create_user('rdiff-backup-server')
      end
      it do
        expect(chef_run).to install_sudo('rdiff-backup-server').with(
          user: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          nopasswd: true,
          commands: ['/usr/bin/sudo rdiff-backup '\
                     '--server --restrict-read-only /']
        )
      end
      it do
        expect(chef_run).to create_directory('/var/rdiff-backup/locks').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: 0755,
          recursive: true
        )
      end
      it do
        expect(chef_run).to create_directory(
          '/home/rdiff-backup-server/.ssh'
        ).with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server' || 'rdiff-backup-server',
          mode: 0700
        )
      end
      # it do
      #   expect(chef_run).to create_ssh_user('id_rsa').with(
      #   user: 'rdiff-backup-server'
      #   key: secrets['ssh-key']
      #   )
      # end
      it do
        expect(chef_run).to create_directory('/var/log/rdiff-backup').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: 0755,
          recursive: true
        )
      end
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
      it do
        expect(chef_run).to create_rdiff_backup('test1').with(
          fqdn: '192.168.60.11',
          source: '/help/me/obiwan',
          destination: '/you/are/my/only/hope',
          exclude: %w(**/darth-vader /help/me/obiwan/emperor-palpatine)
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
    end
  end
end