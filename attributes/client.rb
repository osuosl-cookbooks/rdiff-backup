# Default attributes.
node.default['rdiff-backup']['client']['default']['ssh-port'] = "22"
node.default['rdiff-backup']['client']['default']['user'] = "rdiff-backup-client"
node.default['rdiff-backup']['client']['default']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['client']['default']['exclude-dirs'] = []
node.default['rdiff-backup']['client']['default']['retention-period'] = "3M"
node.default['rdiff-backup']['client']['default']['additional-args'] = ""
node.default['rdiff-backup']['client']['default']['nagios']['alerts'] = true
node.default['rdiff-backup']['client']['default']['nagios']['max-change'] = 1024
node.default['rdiff-backup']['client']['default']['nagios']['max-late-start'] = 2
node.default['rdiff-backup']['client']['default']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['client']['default']['nagios']['max-late-finish-critical'] = 8

# This is required for sudo access to work.
node.default['authorization']['sudo']['include_sudoers_d'] = true
