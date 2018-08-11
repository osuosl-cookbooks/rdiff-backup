require_relative '../spec_helper'

describe 'rdiff-backup-test::delete_server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup'])
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

      # nrpe defaults to true
      it do
        expect(chef_run).to remove_nrpe_check(
          'check_rdiff_job_delete_tatooine'
        )
      end

      %w(
        /home/rdiff-backup-server/exclude/192.168.60.25/_help_me_boba_fett
        /home/rdiff-backup-server/scripts/192.168.60.25/_help_me_boba_fett
        /home/rdiff-backup-server/exclude/192.168.60.12/_test2
        /home/rdiff-backup-server/scripts/192.168.60.12/_test2
      ).each do |f|
        it do
          expect(chef_run).to delete_file(f)
        end
      end

      it do
        expect(chef_run).to delete_cron('delete_tatooine')
      end

      %w(/home/rdiff-backup-server/exclude/192.168.60.25
         /home/rdiff-backup-server/scripts/192.168.60.25).each do |d|
        it do
          expect(chef_run).to delete_directory(d)
        end
      end

      %w(
        /home/rdiff-backup-server/exclude/192.168.60.12/bar
        /home/rdiff-backup-server/scripts/192.168.60.12/bar
      ).each do |f|
        it do
          expect(chef_run).to create_file(f)
        end
      end
    end
  end
end
