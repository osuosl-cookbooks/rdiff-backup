require_relative '../spec_helper'

describe 'workstation::hosts' do
    let(:chef_run) do
        ChefSpec::Runner.new do |node|
            node.automatic['hostname'] = 'fakehost'
        end.converge(described_recipe)
    end

    context 'when using default parameters' do
        it 'should create a hosts file' do
            expect(chef_run).to create_template('/etc/hosts')
        end
        it 'should create a hosts file with the correct fqdn' do
            expect(chef_run).to render_file('/etc/hosts').with_content('fakehost.workstation.osuosl.bak')
        end
    end
end
