require_relative 'spec_helper'

describe 'rdiff-backup::default' do
  ALL_PLATFORMS.each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end

      it do
        expect(chef_run).to include_recipe('yum-epel')
      end

      it do
        expect(chef_run).to install_package('rdiff-backup')
      end
    end
  end
end
