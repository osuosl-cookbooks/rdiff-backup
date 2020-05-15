node.default['rdiff-backup']['server']['nrpe'] = false

rdiff_backup 'delete_tatooine' do
  fqdn '192.168.60.25'
  source '/help/me/boba_fett'
  action :delete
end
