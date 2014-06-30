# Default attributes.
node.default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
node.default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
node.default['rdiff-backup']['server']['user'] = "rdiff-backup-server"
node.default['rdiff-backup']['server']['restrict-to-own-environment'] = true
node.default['rdiff-backup']['server']['mailto'] = ""
node.default['rdiff-backup']['server']['nagios']['alerts'] = true
node.default['rdiff-backup']['server']['nagios']['plugin-dir'] = "/usr/lib64/nagios/plugins"
node.default['rdiff-backup']['server']['jobs']['default']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['server']['jobs']['default']['exclude-dirs'] = []
node.default['rdiff-backup']['server']['jobs']['default']['retention-period'] = "3M"
node.default['rdiff-backup']['server']['jobs']['default']['additional-args'] = ""
node.default['rdiff-backup']['server']['jobs']['default']['nagios']['alerts'] = true
node.default['rdiff-backup']['server']['jobs']['default']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['jobs']['default']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['jobs']['default']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['jobs']['default']['nagios']['max-late-finish-critical'] = 8

# This is required for sudo access to work and should not be changed/overridden.
node.force_override['authorization']['sudo']['include_sudoers_d'] = true
