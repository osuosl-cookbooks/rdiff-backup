name             'rdiff-backup'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Installs/Configures rdiff-backup'
version          '5.2.1'
issues_url       'https://github.com/osuosl-cookbooks/rdiff-backup/issues'
source_url       'https://github.com/osuosl-cookbooks/rdiff-backup'

depends 'nrpe'
depends 'sudo'
depends 'yum-epel'

supports 'almalinux', '~> 8.0'
supports 'centos', '~> 7.0'
supports 'centos_stream', '~> 8.0'
