require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

CENTOS_8_OPTS = {
  platform: 'centos',
  version: '8',
}.freeze

CENTOS_7_OPTS = {
  platform: 'centos',
  version: '7',
}.freeze

CENTOS_6_OPTS = {
  platform: 'centos',
  version: '6',
}.freeze

RSpec.configure do |config|
  config.log_level = :warn
end
