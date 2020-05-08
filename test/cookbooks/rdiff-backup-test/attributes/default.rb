default['rdiff-backup-test']['ip'] =
  if node['fqdn'].start_with?('client')
    11
  else
    12
  end
