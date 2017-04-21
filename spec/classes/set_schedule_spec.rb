require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'clamav::set_schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        it { is_expected.to create_class('clamav::set_schedule') }
        it { is_expected.to compile.with_all_deps }

        context 'base' do
          it { is_expected.to create_cron('clamscan').with_ensure('present') }
        end

        context 'with logrotate = true' do
          let(:hieradata) { "logrotate_true" }
          if ['RedHat','CentOS'].include?(facts[:operatingsystem])
            if facts[:operatingsystemmajrelease].to_s < '7'
              it { should create_file('/etc/logrotate.d/clamscan').with_content(/#{file_content_6}/)}
            else
              it { should create_file('/etc/logrotate.d/clamscan').with_content(/#{file_content_7}/)}
            end
          end
        end

        context 'with enable => false' do
          let (:params) {{
            :enable => false
          }}
          it { is_expected.to create_cron('clamscan').with_ensure('absent') }
        end
      end
    end
  end
end
