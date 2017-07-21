rdiff_backup 'delete_tatooine' do
  owner 'jarjarbinks'
  fqdn '192.168.60.25'
  source '/help/me/boba_fett'
  action :delete
end

file '/home/rdiff-backup-server/exclude/192.168.60.12/bar' do
  content '/var'
end

file '/home/rdiff-backup-server/scripts/192.168.60.12/bar' do
  content '/var'
end

rdiff_backup 'test2' do
  fqdn '192.168.60.12'
  source '/test2'
  destination '/backups/test2'
  action :delete
end
