# Default server attributes
node.default['rdiff-backup']['server']['start-hour'] = 5 # (9pm PST)
node.default['rdiff-backup']['server']['end-hour'] = 13 # (5am PST)
node.default['rdiff-backup']['server']['user'] = "rdiff-backup-server"
node.default['rdiff-backup']['server']['sudo'] = true
node.default['rdiff-backup']['server']['restrict-to-own-environment'] = true
node.default['rdiff-backup']['server']['restrict-to-environments'] = []
node.default['rdiff-backup']['server']['mailto'] = ""
node.default['rdiff-backup']['server']['nagios']['enable-alerts'] = true
node.default['rdiff-backup']['server']['nagios']['plugin-dir'] = "/usr/lib64/nagios/plugins"
node.default['rdiff-backup']['server']['fs']['enable'] = true
node.default['rdiff-backup']['server']['mysql']['enable'] = true

node.force_override['authorization']['sudo']['include_sudoers_d'] = true
