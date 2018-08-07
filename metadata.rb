name             'rdiff-backup'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 12.18' if respond_to?(:chef_version)
description      'Installs/Configures rdiff-backup'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.12'
issues_url       'https://github.com/osuosl-cookbooks/rdiff-backup/issues'
source_url       'https://github.com/osuosl-cookbooks/rdiff-backup'

depends 'ssh-keys'
depends 'yum'
depends 'yum-epel'
depends 'user'
depends 'sudo'
depends 'nagios'
depends 'nrpe'

supports 'centos', '~> 6.0'
supports 'centos', '~> 7.0'
