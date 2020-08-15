require_relative '../spec_helper'

describe 'rdiff-backup-test::client' do
  ALL_PLATFORMS.each do |pltfrm|
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
          mode: '0755',
          recursive: true
        )
      end
      it do
        expect(chef_run).to create_file('/help/me/obiwan/r2d2').with(
          content: 'test',
          mode: '0644'
        )
      end
    end
  end
end
