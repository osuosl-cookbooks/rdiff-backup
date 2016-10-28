rdiff_backup 'test1' do
  fqdn '192.168.60.11'
  source '/help/me/obiwan'
  destination '/you/are/my/only/hope'
  exclude ['**/darth-vader', '/help/me/obiwan/emperor-palpatine']
  action :create
end

rdiff_backup 'test2' do
  fqdn '192.168.60.11'
  source '/help/me/obiwan'
  destination '/you/are/my/only/hope'
  exclude ['**/darth-vader', '/help/me/obiwan/emperor-palpatine']
  action :delete
end
