require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

CENTOS_8 = {
  platform: 'centos',
  version: '8',
}.freeze

CENTOS_7 = {
  platform: 'centos',
  version: '7',
}.freeze

ALL_PLATFORMS = [
  CENTOS_7,
  CENTOS_8,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end
