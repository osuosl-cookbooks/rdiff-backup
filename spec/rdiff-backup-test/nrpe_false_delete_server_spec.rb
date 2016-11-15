require_relative '../spec_helper'

describe 'rdiff-backup-test::nrpe_false_delete_server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup']) # , ['nrpe-check'])
        )
      end
      cached(:chef_run) { runner.converge(described_recipe) }
      before do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with(
          'rdiff-backup-secrets', 'secrets'
        ).and_return(
          key: 'secret-key'
        )
      end

      it do
        expect(chef_run).to delete_rdiff_backup('delete_tatooine')
      end
      # nrpe has been set to false
      it do
        expect(chef_run).to_not remove_nrpe_check(
          'check_rdiff_job_delete_tatooine'
        )
      end
      it do
        expect(chef_run).to delete_file(
          '/home/jarjarbinks/exclude/192.168.60.25/_help_me_boba_fett'
        )
      end
      it do
        expect(chef_run).to delete_file(
          '/home/jarjarbinks/scripts/192.168.60.25/_help_me_boba_fett'
        )
      end
      it do
        expect(chef_run).to delete_cron('delete_tatooine')
      end
      %w(/home/jarjarbinks/exclude/192.168.60.25
         /home/jarjarbinks/scripts/192.168.60.25).each do |d|
        it do
          expect(chef_run).to delete_directory(d)
        end
      end
    end
  end
end
