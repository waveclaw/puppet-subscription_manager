require 'puppet/property/boolean'
require 'puppet/type'

Puppet::Type.newtype(:rhsm_repo) do
  @doc = <<-EOD
  A software channel subscribed to by the server.

  Example

  rhsm_repo { 'rhel-server6-epel':
    ensure        => present, # equal to the enabled property
    updated       => 2015-07-17T14:26:35.064+0000,
    created       => 2015-07-17T14:26:35.064+0000,
    content_label => 'rhel-server6-epel'
}
EOD

  ensurable

  newparam(:content_label, :namevar => true) do
    desc "The rhsm channel to subscribe to."
#    validate do |value|
#     fail("Updated should be a date.  Given #{value}") unless value =~ /\S+/
#    end
  end

  newproperty(:updated) do
    desc "The last time this repostory was updated."
    validate do |value|
     fail("Updated should be a date.  Given #{value}") unless value.is_a? Date
    end
  end

  newproperty(:created) do
    desc "The time when this repostory was created."
    validate do |value|
     fail("Created should be a date.  Given #{value}") unless value.is_a? Date
    end
  end

end
