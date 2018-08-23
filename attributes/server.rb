# Default attributes.
default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
default['rdiff-backup']['server']['user'] = 'rdiff-backup-server'
default['rdiff-backup']['server']['group'] = 'rdiff-backup-server'
default['rdiff-backup']['server']['lock_dir'] = '/var/rdiff-backup/locks'
default['rdiff-backup']['server']['sudo'] = true
default['rdiff-backup']['server']['restrict-to-own-environment'] = true
default['rdiff-backup']['server']['restrict-to-environments'] = []
default['rdiff-backup']['server']['mailto'] = ''
default['rdiff-backup']['server']['nagios'] = {
  'alerts' => true,
  'plugin-dir' => '/usr/lib64/nagios/plugins',
}
default['rdiff-backup']['server']['nrpe'] = true

override['authorization']['sudo']['include_sudoers_d'] = true
