require 'puppet/property/boolean'
require 'puppet/type'

Puppet::Type.newtype(:rhsm_repo) do
  @doc = <<-EOD
  A software channel subscribed to by the server.

  Example

  rhsm_repo { 'rhel-server6-epel':
    ensure        => present,
    enabled       => false,
    updated       => 2015-07-17T14:26:35.064+0000,
    created       => 2015-07-17T14:26:35.064+0000,
    content_label => 'rhel-server6-epel'
}
EOD

  ensurable do

  newvalue(:present) do
    provider.create
  end

  newvalue(:absent) do
    provider.destroy
  end

  def insync?(is)

    @should.each do |should|
      case should
      when :present
        return true if is == :present
      when :absent
        return true if is == :absent
      end
    end
    return false
  end
  defaultto :present
end

  newparam(:content_label, :namevar => true) do
    desc "The rhsm channel to subscribe to."
  end

  newproperty(:updated) do
    desc "The last time this repostory was updated."
    validate do |value|
     fail("Updated should be a date.  Given #{value}") unless value.is_a Date
    end
  end

  newproperty(:created) do
    desc "The time when this repostory was created."
    validate do |value|
     fail("Created should be a date.  Given #{value}") unless value.is_a Date
    end
  end

  newproperty(:enabled) do
    desc "Is this repository enabled for use?"
    newvalues(true, false)
  end


end
