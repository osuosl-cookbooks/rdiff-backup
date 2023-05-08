require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

CENTOS_7 = {
  platform: 'centos',
  version: '7',
}.freeze

ALL_PLATFORMS = [
  ALMA_8,
  CENTOS_7,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end
