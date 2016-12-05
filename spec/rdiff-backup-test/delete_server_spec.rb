require_relative '../spec_helper'

describe 'rdiff-backup-test::server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup']) # , ['nrpe-check'])
        )
      end
      let(:chef_run) { runner.converge(described_recipe) }

      before do
        stub_command('secrets').and_return(true)
        Chef::EncryptedDataBagItem.stub(:load).with('rdiff-backup-secrets',
                                                    'secrets').and_return(
                                                      key: 'secret-key'
                                                    )
      end

      # Delete
      context 'Delete: nrpe is true' do
        it do
          expect(chef_run).to remove_nrpe_check('check_rdiff_job_test2')
        end

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
          expect(chef_run).to delete_cron('test2')
        end
        %w(/home/rdiff-backup-server/exclude/192.168.60.11
           /home/rdiff-backup-server/scripts/192.168.60.11).each do |d|
          it do
            expect(chef_run).to delete_directory(d)
          end
        end
      end
    end
  end
end
