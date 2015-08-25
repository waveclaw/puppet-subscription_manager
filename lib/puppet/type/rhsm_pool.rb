require 'puppet/property/boolean'
require 'puppet/type'

Puppet::Type.newtype(:rhsm_pool) do
  @doc = "Abstract the concept of an Entitlement Pool from which active subscriptions can be drawn"

  ensurable

  newparam(:id, :namevar => true) do
    desc "An Entitlement Pool to which the server is subscribed"
  end

end
