# Default attributes

# Server attributes
node.default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
node.default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
node.default['rdiff-backup']['server']['user'] = "rdiff-backup-server"
node.default['rdiff-backup']['server']['sudo'] = true
node.default['rdiff-backup']['server']['restrict-to-own-environment'] = true
node.default['rdiff-backup']['server']['restrict-to-environments'] = []
node.default['rdiff-backup']['server']['mailto'] = ""
node.default['rdiff-backup']['server']['nagios']['alerts'] = true
node.default['rdiff-backup']['server']['nagios']['plugin-dir'] = "/usr/lib64/nagios/plugins"

# Job attributes (filesystem)
node.default['rdiff-backup']['server']['jobs']['']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['server']['jobs']['']['retention-period'] = "3M"
node.default['rdiff-backup']['server']['jobs']['']['additional-args'] = ""
node.default['rdiff-backup']['server']['jobs']['']['exclude-dirs'] = []
node.default['rdiff-backup']['server']['jobs']['']['nagios']['alerts'] = true
node.default['rdiff-backup']['server']['jobs']['']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['jobs']['']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['jobs']['']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['jobs']['']['nagios']['max-late-finish-critical'] = 8

# Job attributes (MySQL)
node.default['rdiff-backup']['server']['mysql-jobs']['']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['server']['mysql-jobs']['']['retention-period'] = "3M"
node.default['rdiff-backup']['server']['mysql-jobs']['']['additional-args'] = ""
node.default['rdiff-backup']['server']['mysql-jobs']['']['single-transaction'] = ""
node.default['rdiff-backup']['server']['mysql-jobs']['']['nagios']['alerts'] = true
node.default['rdiff-backup']['server']['mysql-jobs']['']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['mysql-jobs']['']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['mysql-jobs']['']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['mysql-jobs']['']['nagios']['max-late-finish-critical'] = 8

node.force_override['authorization']['sudo']['include_sudoers_d'] = true
