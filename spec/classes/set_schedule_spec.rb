require 'spec_helper'

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
          it { is_expected.to create_logrotate__rule('clamscan').with_log_files(['/var/log/clamscan.log' ]) }
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
