require 'spec_helper'

describe 'subscription_manager' do
  let(:facts) { {} }
  let(:params) { {} }
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('subscription_manager') }
end
