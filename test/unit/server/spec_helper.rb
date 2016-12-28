require 'chefspec'
require 'chefspec/server'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start!

RSpec.configure do |config|
    config.platform = 'debian'
    config.version = '7'
end
