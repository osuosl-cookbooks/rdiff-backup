# Default attributes.
default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
default['rdiff-backup']['server']['user'] = 'rdiff-backup-server'
default['rdiff-backup']['server']['sudo'] = true
default['rdiff-backup']['server']['restrict-to-own-environment'] = true
default['rdiff-backup']['server']['restrict-to-environments'] = []
default['rdiff-backup']['server']['mailto'] = ''
default['rdiff-backup']['server']['nagios']['alerts'] = true
default['rdiff-backup']['server'][
  'nagios']['plugin-dir'] = '/usr/lib64/nagios/plugins'
default['rdiff-backup']['server'][
  'jobs']['default']['destination-dir'] = '/data/rdiff-backup'
default['rdiff-backup']['server']['jobs']['default']['exclude-dirs'] = []
default['rdiff-backup']['server'][
  'jobs']['default']['retention-period'] = '3M'
default['rdiff-backup']['server'][
  'jobs']['default']['additional-args'] = ''
default['rdiff-backup']['server'][
  'jobs']['default']['nagios']['alerts'] = true
default['rdiff-backup']['server'][
  'jobs']['default']['nagios']['max-change'] = 8192
default['rdiff-backup']['server'][
  'jobs']['default']['nagios']['max-late-start'] = 24
default['rdiff-backup']['server'][
  'jobs']['default']['nagios']['max-late-finish-warning'] = 4
default['rdiff-backup']['server'][
  'jobs']['default']['nagios']['max-late-finish-critical'] = 8

override['authorization']['sudo']['include_sudoers_d'] = true
