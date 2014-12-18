name             'rdiff-backup'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures rdiff-backup'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'

depends 'yum'
depends 'yum-epel'
depends 'user'
depends 'partial_search'
recommends 'sudo'
recommends 'nagios'
recommends 'nrpe'

supports 'centos'
