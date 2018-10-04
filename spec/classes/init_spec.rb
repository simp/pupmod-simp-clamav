require 'spec_helper'

describe 'clamav' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end
      let(:environment) {'production'}

      context "on #{os}" do
        it { is_expected.to create_class('clamav') }
        it { is_expected.to compile.with_all_deps }

        context 'base' do

          it { is_expected.to create_group('clam').with_ensure('present') }
          it { is_expected.to create_user('clam').with({
            :ensure    => 'present',
            :allowdupe => false,
            :uid       => '409',
            :shell     => '/sbin/nologin',
            :gid       => 'clam',
            :home      => '/var/lib/clamav',
            :require   => 'Group[clam]'
            })
          }
          it { is_expected.to contain_package('clamav').with({
              :ensure  => 'installed',
              :require => ['User[clam]', 'Group[clam]']
            })
          }
          it { is_expected.to contain_package('clamav-lib.i386').with({
              :ensure => 'absent',
              :notify => 'Package[clamav]'
            })
          }
          it { is_expected.to contain_file('/etc/cron.daily/freshclam').with_ensure('absent') }
          it { is_expected.to contain_rsync('clamav').with({
            :source => 'clamav_production/'
            })
          }
        end

        context 'with manage_group_and_user => false' do
          let(:params) {{
            :manage_group_and_user => false
          }}
          it { is_expected.not_to contain_group('clam') }
          it { is_expected.not_to contain_user('clam') }
          it { is_expected.to contain_package('clamav').with({
              :require => []
            })
          }
        end

        context 'with enable_freshclam => true' do
          let(:params) {{
            :enable_freshclam => true
          }}
          it { is_expected.to contain_file('/etc/cron.daily/freshclam').with_ensure('file') }
          it { is_expected.not_to contain_rsync('clamav') }
        end

        context 'with enable_freshclam => false' do
          let(:params) {{
            :enable_freshclam => false
          }}
          it { is_expected.to contain_file('/etc/cron.daily/freshclam').with_ensure('absent') }
          it { is_expected.to contain_rsync('clamav') }

          context 'and rsync_source is empty' do
            let(:params) {{
              :enable_freshclam => false,
              :rsync_source => ''
            }}
            it { is_expected.to contain_file('/etc/cron.daily/freshclam').with_ensure('absent') }
            it { is_expected.not_to contain_rsync('clamav') }
          end
        end
        context 'with enable => false' do
          let(:params) {{
            :enable => false
          }}
          it { is_expected.to contain_package('clamav').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/cron.daily/freshclam').with_ensure('absent') }
          it { is_expected.not_to contain_rsync('clamav') }
        end
      end
    end
  end
end
