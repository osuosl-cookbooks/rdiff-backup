require 'chef/provisioning'
require 'chef/provisioning/vagrant_driver'

with_driver "vagrant:#{File.dirname(__FILE__)}/../../../vms"

machine_batch do
  [%w(client 11), %w(server 12)].each do |name, ip_suff|
    machine name do
      machine_options vagrant_options: {
        'vm.box' => 'bento/centos-7.2',
        'vm.box_version' => '2.2.9',
      },
                      convergence_options: {
                        chef_version: '12.10.24',
                      }
      add_machine_options vagrant_config: <<-EOF
    config.vm.network "private_network", ip: "192.168.60.#{ip_suff}"
EOF
      recipe "rdiff-backup-test::#{name}"
      file('/etc/chef/encrypted_data_bag_secret',
           File.dirname(__FILE__) +
           '/../encrypted_data_bag_secret')
      converge true
    end
  end
end
