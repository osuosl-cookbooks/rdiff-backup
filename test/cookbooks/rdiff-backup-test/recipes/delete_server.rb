rdiff_backup 'delete_tatooine' do
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

rdiff_backup 'test3' do
  fqdn '192.168.60.13'
  source '/test3'
  destination '/backups/test3'
  action :delete
end
