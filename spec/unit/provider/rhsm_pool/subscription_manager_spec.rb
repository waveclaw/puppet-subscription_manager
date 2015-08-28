#!/usr/bin/ruby -S rspec
require 'spec_helper'

provider_class = Puppet::Type.type(:rhsm_pool).provider(:subscrption_manager)

describe provider_class, 'provider' do
  let(:resource) do
    {
        :name              => 'Extra Packages for Enterprise Linux',
        :ensure            => :present,
        :provides          => 'EPEL',
        :sku               => 1234536789012,
        :contract          => 'Fancy Widgets, LTD',
        :account           => '1234-12-3456-0001',
        :serial            => '1234567890123456789',
        :id                => '1a2b3c4d5e6f1234567890abcdef12345',
        :active            => true,
        :quantity_used     => 1,
        :service_level     => 'STANDARD',
        :service_type      => 'EOL',
        :status_details    => 'expired',
        :subscription_type => 'permanent',
        :starts            => Date.parse('06/01/2015'),
        :ends              => Date.parse('05/24/2045'),
        :system_type       => :physical,
    }
  end
  let(:provider) do
    provider_class.new(resource)
  end

end
