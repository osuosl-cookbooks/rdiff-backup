# Default attributes.
node.default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
node.default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
node.default['rdiff-backup']['server']['user'] = "rdiff-backup-server"
node.default['rdiff-backup']['server']['restrict-to-own-environment'] = true
node.default['rdiff-backup']['server']['mailto'] = true
node.default['rdiff-backup']['client']['nagios']['alerts'] = true

# This is required for sudo access to work and should not be changed/overridden.
node.default['authorization']['sudo']['include_sudoers_d'] = true
