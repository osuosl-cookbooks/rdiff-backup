osl_ifconfig "192.168.60.#{node['rdiff-backup-test']['ip']}" do
  onboot 'yes'
  mask '255.255.255.0'
  network '192.168.60.0'
  device 'eth1'
end
