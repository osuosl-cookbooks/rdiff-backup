# Default filesystem job attributes
node.default['rdiff-backup']['server']['fs']['job-defaults']['enable'] = true
node.default['rdiff-backup']['server']['fs']['job-defaults']['destination-dir'] = '/data/rdiff-backup'
node.default['rdiff-backup']['server']['fs']['job-defaults']['retention-period'] = '3M'
node.default['rdiff-backup']['server']['fs']['job-defaults']['additional-args'] = ''
node.default['rdiff-backup']['server']['fs']['job-defaults']['exclude-dirs'] = []
node.default['rdiff-backup']['server']['fs']['job-defaults']['nagios']['enable'] = true
node.default['rdiff-backup']['server']['fs']['job-defaults']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['fs']['job-defaults']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['fs']['job-defaults']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['fs']['job-defaults']['nagios']['max-late-finish-critical'] = 8

# Default MySQL job attributes
node.default['rdiff-backup']['server']['mysql']['job-defaults']['enable'] = true
node.default['rdiff-backup']['server']['mysql']['job-defaults']['destination-dir'] = '/data/rdiff-backup'
node.default['rdiff-backup']['server']['mysql']['job-defaults']['retention-period'] = '3M'
node.default['rdiff-backup']['server']['mysql']['job-defaults']['additional-args'] = ''
node.default['rdiff-backup']['server']['mysql']['job-defaults']['single-transaction'] = ''
node.default['rdiff-backup']['client']['mysql']['job-defaults']['mysql-user'] = 'rdiff-backup'
node.default['rdiff-backup']['client']['mysql']['job-defaults']['mysql-password'] = 'rdiff-backup'
node.default['rdiff-backup']['server']['mysql']['job-defaults']['nagios']['enable'] = true
node.default['rdiff-backup']['server']['mysql']['job-defaults']['nagios']['max-change'] = 8192
node.default['rdiff-backup']['server']['mysql']['job-defaults']['nagios']['max-late-start'] = 24
node.default['rdiff-backup']['server']['mysql']['job-defaults']['nagios']['max-late-finish-warning'] = 4
node.default['rdiff-backup']['server']['mysql']['job-defaults']['nagios']['max-late-finish-critical'] = 8
