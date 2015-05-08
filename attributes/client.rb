# Default client attributes
node.default['rdiff-backup']['client']['ssh-port'] = '22'
node.default['rdiff-backup']['client']['user'] = 'rdiff-backup-client'
node.default['rdiff-backup']['client']['sudo'] = true
node.default['rdiff-backup']['client']['fs']['enable'] = true
node.default['rdiff-backup']['client']['fs']['job-defaults'] = {}
node.default['rdiff-backup']['client']['fs']['jobs'] = {}
node.default['rdiff-backup']['client']['fs']['ssh-key'] = '~/.ssh/id_rsa_fs'
node.default['rdiff-backup']['client']['mysql']['enable'] = false
node.default['rdiff-backup']['client']['mysql']['job-defaults'] = {}
node.default['rdiff-backup']['client']['mysql']['jobs'] = {}
node.default['rdiff-backup']['client']['mysql']['ssh-key'] = '~/.ssh/id_rsa_mysql'
node.default['rdiff-backup']['client']['mysql']['mysql-user'] = 'rdiff-backup'
node.default['rdiff-backup']['client']['mysql']['mysql-password'] = 'rdiff-backup'
