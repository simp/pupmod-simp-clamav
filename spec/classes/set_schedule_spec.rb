require 'spec_helper'

describe 'clamav::set_schedule' do

  it { should create_class('clamav::set_schedule') }
  it { should compile.with_all_deps }
  it { should create_cron('clamscan') }
end
