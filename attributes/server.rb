# Default attributes.
node.default['rdiff-backup']['server']['starthour'] = 5 # (9pm PST) 
node.default['rdiff-backup']['server']['endhour'] = 13 # (5am PST) 
node.default['rdiff-backup']['server']['user'] = "rdiff-backup-server"
node.default['rdiff-backup']['server']['restrict-to-own-environment'] = true
node.default['rdiff-backup']['server']['nagios-alerts'] = true
node.default['rdiff-backup']['server']['nagios-warning'] = 2 # 2 hours after endhour
node.default['rdiff-backup']['server']['nagios-critical'] = 4 # 4 hours after endhour
