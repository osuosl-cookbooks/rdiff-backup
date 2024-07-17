osl_ifconfig 'eth1' do
  ipv4addr "192.168.60.#{node['rdiff-backup-test']['ip']}"
  mask '255.255.255.0'
  network '192.168.60.0'
end
