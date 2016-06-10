#!/usr/bin/ruby -S rspec
#
#  Test the class structure of the module as used.
#
#   Copyright 2016 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
require 'spec_helper_acceptance'

describe 'subscription_manager class' do

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      class { 'subscription_manager': }
      EOS

      it_behaves_like "a idempotent resource"
    end

    describe package('subscription-manager') do
      it { should be_installed }
    end

    describe package('katello-ca-consumer') do
      it { should be_installed }
    end

    describe service('goferd') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context 'given parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
      class { 'subscription_manager':
          repo            => 'repo::subscription_manager',
          server_hostname => 'my_katello.example.com',
          activationkey   => '1-2-3-example.com-key',
          force           => true,
          org             => 'My_Example_Org',
        }
      }
      EOS

      # Run it twice and test for idempotency
       it_behaves_like "a idempotent resource"
    end

    describe package('subscription-manager') do
      it { should be_installed }
    end

    describe package('katello-ca-consumer') do
      it { should be_installed }
    end

    describe service('goferd') do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
