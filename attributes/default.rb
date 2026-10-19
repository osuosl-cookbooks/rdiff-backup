# Set to false where another cookbook already manages EPEL
default['rdiff-backup']['manage_epel'] = true

# EPEL comes from manage_epel above; nrpe 4's include_recipe 'yum-epel' fails on yum-epel 6
default['nrpe']['install_yum-epel'] = false
