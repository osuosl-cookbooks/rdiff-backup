require_relative 'spec_helper'

describe 'rdiff-backup::client' do
  ALL_PLATFORMS.each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm) do |node|
          node.normal['rdiff-backup']['client']['ssh_keys'] = %w(ssh-key)
        end.converge(described_recipe)
      end
      before do
        stub_data_bag_item('users', 'rdiff-backup-client')
      end
      it do
        expect(chef_run).to create_user('rdiff-backup-client').with(
          comment: 'User for rdiff-backup client backups',
          shell: '/bin/bash',
          manage_home: true
        )
        expect(chef_run.user('rdiff-backup-client')).to notify('ohai[reload_passwd]').to(:reload).immediately
      end
      it do
        expect(chef_run).to nothing_ohai('reload_passwd').with(
          plugin: 'etc',
          action: [:nothing]
        )
      end
      it do
        expect(chef_run).to include_recipe('rdiff-backup')
      end
      it do
        expect(chef_run).to create_sudo('rdiff-backup-client').with(
          user: %w(rdiff-backup-client),
          group: %w(%rdiff-backup-client),
          commands: ['/usr/bin/rdiff-backup --server --restrict-read-only /'],
          nopasswd: true
        )
      end
      it do
        expect(chef_run).to create_directory('/home/rdiff-backup-client/.ssh')
          .with(
            mode: '0700',
            owner: 'rdiff-backup-client',
            group: 'rdiff-backup-client'
          )
      end
      it do
        expect(chef_run).to create_template('/home/rdiff-backup-client/.ssh/authorized_keys')
          .with(
            mode: '0600',
            owner: 'rdiff-backup-client',
            group: 'rdiff-backup-client'
          )
      end
      it do
        expect(chef_run).to render_file('/home/rdiff-backup-client/.ssh/authorized_keys').with_content('ssh-key')
      end
    end
  end
end
