require_relative '../spec_helper'

describe 'rdiff-backup-test::server' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |pltfrm|
    context "on #{pltfrm[:platform]} #{pltfrm[:version]}" do
      let(:runner) do
        ChefSpec::SoloRunner.new(
          pltfrm.dup.merge(step_into: ['rdiff-backup'])
        )
      end
      cached(:chef_run) { runner.converge(described_recipe) }

      before do
        stub_command('secrets').and_return(false)
        Chef::EncryptedDataBagItem.stub(:load).with('rdiff-backup-secrets',
                                                    'secrets').and_return(
                                                      key: 'secret-key'
                                                    )
        runner.node.automatic['rdiff-backup']['nrpe'] = false
      end
      context 'Create: nrpe is false' do
        cached(:chef_run) { runner.converge(described_recipe) }
        it do
          expect(chef_run).to_not include_recipe('nrpe')
        end
        it do
          expect(chef_run).to_not create_cookbook_file(
            chef_run.node['nrpe']['plugin_dir'] + '/check_rdiff'
          ).with(
            mode: 0755,
            owner: chef_run.node['nrpe']['user'],
            group: chef_run.node['nrpe']['group'],
            source: 'nagios/plugins/check_rdiff',
            cookbook: 'rdiff-backup'
          )
        end
        it do
          expect(chef_run).to_not add_nrpe_check('check_rdiff_job_test1').with(
            command: '/usr/bin/sudo /usr/lib64/nagios/plugins/check_rdiff' \
                                    ' -w 16 '\
                                     '-c 18 '\
                                     '-r /you/are/my/only/hope '\
                                     '-p 24 '\
                                     '-l 800000000'
          )
        end
      end

      context 'Delete: nrpe is false' do
        cached(:chef_run) { runner.converge(described_recipe) }
        it do
          expect(chef_run.node['rdiff-backup']['nrpe']).to eq(false)
        end
        it do
          expect(chef_run).to_not remove_nrpe_check('check_rdiff_job_test1')
        end
      end
    end
  end
end
