require_relative '../spec_helper'

describe 'rdiff-backup-test::client' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end
      before do
        stub_data_bag_item('users', 'rdiff-backup-client')
      end
      it do
        expect(chef_run).to include_recipe('rdiff-backup::client')
      end
      it do
        expect(chef_run).to create_directory('/help/me/obiwan').with(
          mode: 0755,
          recursive: true
        )
      end
      it do
        expect(chef_run).to create_file('/help/me/obiwan/r2d2').with(
          content: 'test',
          mode: 0644
        )
      end
      # it do
      #   expect(chef_run).to create_user('rdiff-backup-client').with(
      #     comment: 'User for rdiff-backup client backups',
      #     shell: '/bin/bash',
      #     supports: { manage_home: true },
      #     action: [:nothing]
      #   )
      # end
      # it do
      #   expect(chef_run).to reload_ohai('reload_passwd').with(
      #     plugin: 'etc',
      #     action: [:nothing]
      #   )
      # end
      # it do
      #   expect(chef_run).to install_package('rdiff-backup')
      # end
      # it do
      #   expect(chef_run).to install_sudo('rdiff-backup-client').with(
      #     user: 'rdiff-backup-client',
      #     group: 'rdiff-backup-client',
      #     commands: ['/usr/bin/rdiff-backup --server --restrict-read-only /'],
      #     nopasswd: true
      #   )
      # end
    end
  end
end
