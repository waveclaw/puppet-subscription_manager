#!/usr/bin/ruby -S rspec
require 'spec_helper'
provider_class = Puppet::Type.type(:rhsm_register).provider(:subscrption_manager)

describe provider_class, 'provider' do

end
