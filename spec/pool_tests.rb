#!/usr/bin/ruby -S rspec
#
# Common tests for pools or subscriptions
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

# stub facter_cacheable
module Facter::Util::Facter_cacheable
  class <<self
    def cached?
    end
  end
end

consumed_cases = {
  :one   => {
    :desc => 'a single active pool',
    :data => '
    +-------------------------------------------+
       Consumed Subscriptions
    +-------------------------------------------+
    Subscription Name:   CentOS 7
    Provides:            CentOS 7
    SKU:                 1459623384080
    Contract:
    Account:
    Serial:              5055794266217739415
    Pool ID:             402881af53cc3cc00153d85560d4001a
    Provides Management: No
    Active:              True
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical


',
    :expected =>
     { :enabled => ['402881af53cc3cc00153d85560d4001a'],
       :disabled => []}
  },
  :two   => {
    :desc => 'two active subscription pools',
    :data => '
    +-------------------------------------------+
       Consumed Subscriptions
    +-------------------------------------------+
    Subscription Name:   CentOS 7
    Provides:            CentOS 7
    SKU:                 1459623384080
    Contract:
    Account:
    Serial:              5055794266217739415
    Pool ID:             402881af53cc3cc00153d85560d4001a
    Provides Management: No
    Active:              True
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical

    Subscription Name:   Puppet
    Provides:
    SKU:                 1457412916057
    Contract:
    Pool ID:             402881af5354120801535494568c0003
    Provides Management: No
    Active:              True
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical
',
    :expected => { :enabled =>  ['402881af53cc3cc00153d85560d4001a', '402881af5354120801535494568c0003'],
      :disabled => []}
  },
  :three  => {
    :desc => 'no subscription pools available',
    :data => '',
    :expected => { :enabled =>  [], :disabled => []}

  },
  :four  => {
    :desc => 'two subscription pools available, one inactive',
    :data => '
    +-------------------------------------------+
       Consumed Subscriptions
    +-------------------------------------------+
    Subscription Name:   CentOS 7
    Provides:            CentOS 7
    SKU:                 1459623384080
    Contract:
    Account:
    Serial:              5055794266217739415
    Pool ID:             402881af53cc3cc00153d85560d4001a
    Provides Management: No
    Active:              True
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical

    Subscription Name:   Puppet
    Provides:
    SKU:                 1457412916057
    Contract:
    Pool ID:             402881af5354120801535494568c0003
    Provides Management: No
    Active:              False
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical
',
:expected => { :disabled =>  ['402881af5354120801535494568c0003'],
  :enabled =>  ['402881af53cc3cc00153d85560d4001a']}
  },
  :five  => {
    :desc => 'two subscription pools available, both inactive',
    :data => '
    +-------------------------------------------+
       Consumed Subscriptions
    +-------------------------------------------+
    Subscription Name:   CentOS 7
    Provides:            CentOS 7
    SKU:                 1459623384080
    Contract:
    Account:
    Serial:              5055794266217739415
    Pool ID:             402881af53cc3cc00153d85560d4001a
    Provides Management: No
    Active:              False
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical

    Subscription Name:   Puppet
    Provides:
    SKU:                 1457412916057
    Contract:
    Pool ID:             402881af5354120801535494568c0003
    Provides Management: No
    Active:              False
    Quantity Used:       1
    Service Level:
    Service Type:
    Status Details:      Subscription is current
    Subscription Type:   Standard
    Starts:              04/02/2016
    Ends:                03/26/2046
    System Type:         Physical
',
:expected => { :enabled =>  [],
  :disabled => ['402881af53cc3cc00153d85560d4001a', '402881af5354120801535494568c0003']}
  }
}

shared_examples_for 'consumed pools' do |mod, function, label|
  before :each do
    allow(File).to receive(:exist?).with(
    '/usr/sbin/subscription-manager') { true }
    allow(Facter::Util::Facter_cacheable).to receive(:cached?) { false }
  end
  it "should return nothing when there is an error" do
    expect(Facter::Util::Resolution).to receive(:exec).with(
      '/usr/sbin/subscription-manager list --consumed') { throw Error }
    expect(mod.send(function)).to eq([])
  end
  it "should return nothing when there is an error with output" do
    expect(Facter::Util::Resolution).to receive(:exec).with(
      '/usr/sbin/subscription-manager list --consumed') { nil }
    expect(mod).to receive(:get_output) { throw Error }
    expect(Facter).to receive(:debug)
    expect(mod.send(function)).to eq([])
  end
  consumed_cases.keys.each { |key|
    desc = consumed_cases[key][:desc]
    it "should process with get_input #{desc}" do
      expect(mod.send('get_output', consumed_cases[key][:data])).to  eq(
        consumed_cases[key][:expected][label] )
    end
    it "should return results for #{desc}" do
      expect(Facter::Util::Resolution).to receive(:exec).with(
        '/usr/sbin/subscription-manager list --consumed') {
          consumed_cases[key][:data]}
        expect(mod.send(function)).to eq(
          consumed_cases[key][:expected][label] )
    end
  }
end

shared_examples_for 'cached pools' do  |mod, function, label, source|
  options = {
    :rhsm_disabled_pools => '--consumed',
    :rhsm_enabled_pools => '--consumed',
    :rhsm_available_pools => '--available'
  }
  data = {
    :rhsm_disabled_pools => "Pool ID: 402881af5354120801535494568c0003\nActive: False",
    :rhsm_enabled_pools => "Pool ID: 402881af5354120801535494568c0003\nActive: True",
    :rhsm_available_pools => "Pool ID: 402881af5354120801535494568c0003\n"
  }
  results = {
    :rhsm_disabled_pools => {"rhsm_disabled_pools" => ['402881af5354120801535494568c0003']},
    :rhsm_enabled_pools => {"rhsm_enabled_pools"=>['402881af5354120801535494568c0003']},
    :rhsm_available_pools => {"rhsm_available_pools"=>['402881af5354120801535494568c0003']}
  }
  let(:fake_class) { Class.new }
  before :each do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(
    '/usr/sbin/subscription-manager') { true }
    allow(Puppet.features).to receive(:facter_cacheable?) { true }
    Facter.clear
  end
  it 'should return and save a computed value with an empty cache' do
    option = options[label]
    stub_const("Facter::Util::Facter_cacheable", fake_class)
    expect(results[label][label.to_s]).to_not eq(nil)
    expect(Facter::Util::Facter_cacheable).to receive(:cached?).with(
      label, mod::CACHE_TTL, source) { nil }
    expect(Facter::Util::Resolution).to receive(:exec).with(
    "/usr/sbin/subscription-manager list #{option}") { data[label] }
    expect(Facter::Util::Facter_cacheable).to receive(:cache).with(
      label,
      results[label][label.to_s],
      source)
    expect(Facter.value(label)).to eq(results[label][label.to_s])
  end
  it 'should return a cached value with a full cache' do
    stub_const("Facter::Util::Facter_cacheable", fake_class)
    expect(Facter::Util::Facter_cacheable).to receive(:cached?).with(
      label, mod::CACHE_TTL, mod::CACHE_FILE) { results[label] }
    expect(mod).to_not receive(label)
    expect(results[label][label.to_s]).to_not eq(nil)
    expect(Facter.value(label)).to eq(results[label][label.to_s])
  end
  #
  #  This is actually a problem since Facter 2.0
  #
  it 'should return a cached value with a full cache when cache is not a hash' do
    stub_const("Facter::Util::Facter_cacheable", fake_class)
    expect(Facter::Util::Facter_cacheable).to receive(:cached?).with(
      label, mod::CACHE_TTL, mod::CACHE_FILE) { results[label][label.to_s] }
    expect(mod).to_not receive(label)
    expect(results[label][label.to_s]).to_not eq(nil)
    expect(Facter.value(label)).to eq(results[label][label.to_s])
  end
end
