require_relative 'spec_helper'

describe 'rdiff-backup::default' do
  ALL_PLATFORMS.each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(pltfrm).converge(described_recipe)
      end

      it do
        expect(chef_run).to create_yum_epel('default')
      end

      it do
        expect(chef_run).to install_package('rdiff-backup')
      end

      context 'manage_epel disabled' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(pltfrm) do |node|
            node.normal['rdiff-backup']['manage_epel'] = false
          end.converge(described_recipe)
        end

        it do
          expect(chef_run).to_not create_yum_epel('default')
        end

        it do
          expect(chef_run).to install_package('rdiff-backup')
        end
      end
    end
  end
end
