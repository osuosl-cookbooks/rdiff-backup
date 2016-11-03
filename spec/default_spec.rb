require_relative 'spec_helper'

describe 'rdiff-backup::default' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end
      it do
        expect{chef_run}.to_not raise_error
      end
      before do
        stub_data_bag_item('users', 'rdiff-backup-client')
      end
      # it do
      #   expect(chef_run).to include_recipe('rdiff-backup::client')
      # end
    end
  end
end
