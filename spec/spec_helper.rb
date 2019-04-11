require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

ChefSpec::Coverage.start! { add_filter 'rdiff-backup' }

CENTOS_7_OPTS = {
  platform: 'centos',
  version: '7.4.1708',
  log_level: :fatal,
}.freeze

CENTOS_6_OPTS = {
  platform: 'centos',
  version: '6.9',
  log_level: :fatal,
}.freeze
