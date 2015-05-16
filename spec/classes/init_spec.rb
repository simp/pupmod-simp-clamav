require 'spec_helper'

describe 'clamav' do
  let(:facts) {{
    :hardwaremodel    => 'x86_64',
    :selinux_enforced => false
  }}

  it { should create_class('clamav') }

  context 'base' do
    it { should compile.with_all_deps }

    it { should create_group('clam').with_ensure('present') }

    it { should create_user('clam').with({
        :ensure    => 'present',
        :allowdupe => false,
        :uid       => '409',
        :shell     => '/sbin/nologin',
        :gid       => 'clam',
        :home      => '/var/lib/clamav',
        :require   => 'Group[clam]'
      })
    }

    it { should contain_package('clamav').with({
        :ensure  => 'latest',
        :require => ['User[clam]', 'Group[clam]']
      })
    }

    it { should contain_package('clamav-lib.i386').with({
        :ensure => 'absent',
        :notify => 'Package[clamav]'
      })
    }

    it { should contain_file('/etc/cron.daily/freshclam').with_ensure('absent') }
    it { should contain_rsync('clamav') }
  end
end
