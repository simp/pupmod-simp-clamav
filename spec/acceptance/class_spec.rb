require 'spec_helper_acceptance'

test_name 'clamav class'

describe 'clamav class' do
  clients = hosts_with_role( hosts, 'client' )

  # We won't have an rsync server set up by default to test the usual rsync
  # case.
  let(:default_hieradata) {{
    'clamav::enable_freshclam' => true
  }}

  let(:disable_hieradata) {{
    'clamav::enable' => false,
    'clamav::enable_freshclam' => true
  }}

  let(:manifest) {
    <<-EOS
      include '::clamav'
    EOS
  }

  # We need this for our tests to run properly!
  clients.each do |client|
    context 'with defaults' do
      it 'should set the context hieradata' do
        set_hieradata_on(client, default_hieradata)
      end

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(client, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(client, manifest, {:catch_changes => true})
      end

      describe user('clam') {
        it { is_expected.to exist }
      }

      describe group('clam') {
        it { is_expected.to exist }
      }

      describe package('clamav') {
        it { is_expected.to be_installed }
      }

      describe file('/etc/cron.daily/freshclam') {
        it { is_expected.to be_file }
      }

      if on(client, '/usr/sbin/selinuxenabled', :accept_all_exit_codes => true).exit_code == 0
        it 'should have the selinux boolean "antivirus_can_scan_system" set' do
          expect {
            on(client, '/usr/sbin/getsebool antivirus_can_scan_system') =~ /.*--> on/
          }.to be_true
        end
      end
    end

    context 'when disabled' do
      it 'should set the context hieradata' do
        set_hieradata_on(client, disable_hieradata)
      end

      # Using puppet_apply as a helper
      it 'should work with no errors' do
        apply_manifest_on(client, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(client, manifest, {:catch_changes => true})
      end

      describe package('clamav') {
        it { is_expected.to_not be_installed }
      }

      describe file('/etc/cron.daily/freshclam') {
        it { is_expected.to_not be_file }
      }

      if on(client, '/usr/sbin/selinuxenabled', :accept_all_exit_codes => true).exit_code == 0
        it 'should have the selinux boolean "antivirus_can_scan_system" set' do
          expect {
            on(client, '/usr/sbin/getsebool antivirus_can_scan_system') =~ /.*--> off/
          }.to be_true
        end
      end
    end
  end
end
