include_recipe 'rdiff-backup::server'

rdiff_backup 'test1' do
  fqdn '192.168.60.11'
  source '/help/me/obiwan'
  destination '/you/are/my/only/hope'
  exclude ['**/darth-vader', '/help/me/obiwan/emperor-palpatine']
end

rdiff_backup 'test2' do
  fqdn '192.168.60.12'
  source '/test2'
  destination '/backups/test2'
  exclude ['**/foo', '/bar/foo']
end
