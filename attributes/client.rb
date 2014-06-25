# Default attributes.
node.default['rdiff-backup']['client']['ssh-port'] = "22"
node.default['rdiff-backup']['client']['user'] = "rdiff-backup-client"
node.default['rdiff-backup']['client']['jobs']['default']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['client']['jobs']['default']['exclude-dirs'] = []
node.default['rdiff-backup']['client']['jobs']['default']['retention-period'] = "3M"
node.default['rdiff-backup']['client']['jobs']['default']['additional-args'] = ""
node.default['rdiff-backup']['client']['jobs']['default']['nagios']['alerts'] = true
node.default['rdiff-backup']['client']['jobs']['default']['nagios']['max-change'] = 1024
node.default['rdiff-backup']['client']['jobs']['default']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['client']['jobs']['default']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['client']['jobs']['default']['nagios']['max-late-finish-critical'] = 8

# This is required for sudo access to work.
node.default['authorization']['sudo']['include_sudoers_d'] = true
