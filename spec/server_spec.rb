require_relative 'spec_helper'

describe 'rdiff-backup::server' do
  ALL_PLATFORMS.each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end

      before do
        stub_data_bag_item('users', 'rdiff-backup-client').and_return(nil)
        stub_data_bag_item('rdiff-backup-secrets', 'secrets').and_return(
          'ssh-key' => 'secret-key'
        )
      end

      it do
        expect(chef_run).to include_recipe('rdiff-backup')
      end

      it do
        expect(chef_run).to create_cookbook_file('/usr/lib64/nagios/plugins/check_rdiff').with(
          mode: '0755',
          cookbook: 'rdiff-backup',
          owner: 'nrpe',
          group: 'nrpe',
          source: 'nagios/plugins/check_rdiff'
        )
      end

      it do
        expect(chef_run).to create_sudo('check_rdiff').with(
          user: %w(nrpe),
          nopasswd: true,
          commands: [
            '/usr/lib64/nagios/plugins/check_rdiff',
            '/usr/lib64/nagios/plugins/check_rdiff_log',
          ]
        )
      end

      it do
        expect(chef_run).to create_user('rdiff-backup-server')
      end

      it do
        expect(chef_run).to_not create_group('rdiff-backup-server')
      end

      it do
        expect(chef_run).to create_sudo('rdiff-backup-server').with(
          user: %w(rdiff-backup-server),
          group: %w(%rdiff-backup-server),
          nopasswd: true,
          commands: ['/usr/bin/sudo rdiff-backup '\
                     '--server --restrict-read-only /']
        )
      end

      it do
        expect(chef_run).to create_directory('/var/rdiff-backup/locks').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: '0755',
          recursive: true
        )
      end

      it do
        expect(chef_run).to create_directory('/home/rdiff-backup-server/.ssh').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: '0700',
          recursive: true
        )
      end

      it do
        expect(chef_run).to create_file('/home/rdiff-backup-server/.ssh/id_rsa').with(
          content: 'secret-key',
          mode: '0600',
          owner: 'rdiff-backup-server'
        )
      end

      it do
        expect(chef_run).to create_directory('/var/log/rdiff-backup').with(
          owner: 'rdiff-backup-server',
          group: 'rdiff-backup-server',
          mode: '0755',
          recursive: true
        )
      end

      context 'nrpe disabled' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(pltfrm) do |node|
            node.normal['rdiff-backup']['server']['nrpe'] = false
          end.converge(described_recipe)
        end

        it do
          expect(chef_run).to_not create_cookbook_file('/usr/lib64/nagios/plugins/chef_rdiff')
        end
        it do
          expect(chef_run).to_not create_sudo('check_rdiff')
        end
      end
    end
  end
end
