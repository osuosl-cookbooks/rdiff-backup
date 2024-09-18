name             'rdiff-backup'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Installs/Configures rdiff-backup'
version          '5.4.0'
issues_url       'https://github.com/osuosl-cookbooks/rdiff-backup/issues'
source_url       'https://github.com/osuosl-cookbooks/rdiff-backup'

depends          'nrpe'
depends          'sudo'
depends          'yum-epel'

supports         'almalinux', '~> 8.0'
supports         'almalinux', '~> 9.0'
