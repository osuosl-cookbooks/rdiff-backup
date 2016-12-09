rdiff_backup 'delete_tatooine' do
  nrpe false
  owner 'jarjarbinks'
  fqdn '192.168.60.25'
  source '/help/me/boba_fett'
  action :delete
end
