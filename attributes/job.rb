# Default filesystem job attributes
node.default['rdiff-backup']['server']['fs']['jobs']['']['enable'] = true
node.default['rdiff-backup']['server']['fs']['jobs']['']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['server']['fs']['jobs']['']['retention-period'] = "3M"
node.default['rdiff-backup']['server']['fs']['jobs']['']['additional-args'] = ""
node.default['rdiff-backup']['server']['fs']['jobs']['']['exclude-dirs'] = []
node.default['rdiff-backup']['server']['fs']['jobs']['']['nagios']['enable-alerts'] = true
node.default['rdiff-backup']['server']['fs']['jobs']['']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['fs']['jobs']['']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['fs']['jobs']['']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['fs']['jobs']['']['nagios']['max-late-finish-critical'] = 8

# Default MySQL job attributes
node.default['rdiff-backup']['server']['mysql']['jobs']['']['enable'] = true
node.default['rdiff-backup']['server']['mysql']['jobs']['']['destination-dir'] = "/data/rdiff-backup"
node.default['rdiff-backup']['server']['mysql']['jobs']['']['retention-period'] = "3M"
node.default['rdiff-backup']['server']['mysql']['jobs']['']['additional-args'] = ""
node.default['rdiff-backup']['server']['mysql']['jobs']['']['single-transaction'] = ""
node.default['rdiff-backup']['server']['mysql']['jobs']['']['nagios']['enable-alerts'] = true
node.default['rdiff-backup']['server']['mysql']['jobs']['']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['mysql']['jobs']['']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['mysql']['jobs']['']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['mysql']['jobs']['']['nagios']['max-late-finish-critical'] = 8
