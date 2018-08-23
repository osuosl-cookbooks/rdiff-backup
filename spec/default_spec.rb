require_relative 'spec_helper'

describe 'rdiff-backup::default' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end

      %w(
        yum
        yum-epel
      ).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end

      it do
        expect(chef_run).to install_package('rdiff-backup')
      end
    end
  end
end
