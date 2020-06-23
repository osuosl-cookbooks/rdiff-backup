name             'rdiff-backup'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 14'
description      'Installs/Configures rdiff-backup'
version          '3.2.0'
issues_url       'https://github.com/osuosl-cookbooks/rdiff-backup/issues'
source_url       'https://github.com/osuosl-cookbooks/rdiff-backup'

depends 'nrpe'
depends 'sudo'
depends 'yum'
depends 'yum-epel'

supports 'centos', '~> 6.0'
supports 'centos', '~> 7.0'
