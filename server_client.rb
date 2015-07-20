require 'chef/provisioning'

# temporary workaround for a bug with chef-provisioning
with_chef_server Chef::Config[:chef_server_url].sub('chefzero', 'http')

machine_batch do
  [%w(client 11), %w(server 12)].each do |name, ip_suff|
    machine name do
      add_machine_options vagrant_config: <<-EOF
    config.vm.network "private_network", ip: "192.168.60.#{ip_suff}"
EOF
      recipe "rdiff-backup-test::#{name}"
      file('/etc/chef/encrypted_data_bag_secret',
           "#{File.dirname(__FILE__)}/test/integration/" \
           'encrypted_data_bag_secret')
      converge true
    end
  end
end
