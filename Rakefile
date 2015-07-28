task default: ['test']

desc 'Default gate tests to run'
task test: [:rubocop, :berks_vendor]

def run_command(command)
  if File.exist?('Gemfile.lock')
    sh %(bundle exec #{command})
  else
    sh %(chef exec #{command})
  end
end

task :destroy_all do
  Rake::Task[:destroy_machines].invoke
  run_command('rm -rf Gemfile.lock && rm -rf Berksfile.lock && ' \
    'rm -rf cookbooks/')
end

desc 'Destroy machines'
task :destroy_machines do
  run_command('chef-client --force-formatter -z destroy_all.rb')
end

desc 'Vendor your cookbooks/'
task :berks_vendor do
  run_command('berks vendor cookbooks')
end

desc 'Create Chef Key'
task :create_key do
  unless File.exist?('.chef/validator.pem')
    sh %(chef exec ruby -e "require 'openssl';
File.binwrite('.chef/validator.pem', OpenSSL::PKey::RSA.new(2048).to_pem)")
  end
end

desc 'Master/Slave FTP Cluster'
task server_client: [:create_key, :berks_vendor] do
  run_command('chef-client --force-formatter -z vagrant_linux.rb ' \
    'server_client.rb')
end

desc 'Blow everything away'
task clean: [:destroy_all]

# CI tasks
require 'rubocop/rake_task'
desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop)