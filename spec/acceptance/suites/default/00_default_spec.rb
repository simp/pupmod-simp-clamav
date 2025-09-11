require 'spec_helper_acceptance'

test_name 'clamav class'

describe 'clamav class' do
  clients = hosts_with_role(hosts, 'client')

  # We won't have an rsync server set up by default to test the usual rsync
  # case.
  let(:default_hieradata) do
    {
      'clamav::enable_freshclam' => true,
    }
  end

  let(:disable_hieradata) do
    {
      'clamav::enable'           => false,
      'clamav::enable_freshclam' => true,
    }
  end

  let(:manifest) do
    <<~EOS
      include 'clamav'
    EOS
  end

  # We need this for our tests to run properly!
  clients.each do |client|
    on client, puppet('config set stringify_facts false')

    client['repos']&.each_pair do |repo, metadata|
      repo_manifest = <<~EOS
        yumrepo { #{repo}:
          baseurl => '#{metadata[:url]}',
          gpgkey  => '#{metadata[:gpgkeys].join(' ')}',
        }
      EOS
      apply_manifest_on(client, repo_manifest, catch_failures: true)
    end

    context 'with defaults' do
      it 'sets the context hieradata' do
        set_hieradata_on(client, default_hieradata)
      end

      # Using puppet_apply as a helper
      it 'works with no errors' do
        apply_manifest_on(client, manifest, catch_failures: true)
      end

      it 'is idempotent' do
  apply_manifest_on(client, manifest, catch_changes: true)
      end

      # rubocop:disable RSpec/RepeatedExample
      describe user('clam') {
        it { is_expected.to exist }
      }

      describe group('clam') {
        it { is_expected.to exist }
      }
      # rubocop:enable RSpec/RepeatedExample

      describe package('clamav') {
        it { is_expected.to be_installed }
      }

      describe file('/etc/cron.daily/freshclam') {
        it { is_expected.to be_file }
      }

      it 'creates a crontab entry' do
        stdout = on(client, 'crontab -l').stdout
        expect(stdout).to include('/usr/bin/clamscan -l /var/log/clamscan.log')
      end

      if on(client, '/usr/sbin/selinuxenabled', accept_all_exit_codes: true).exit_code == 0
        it 'has the selinux boolean "antivirus_can_scan_system" set' do
          result = on(client, '/usr/sbin/getsebool antivirus_can_scan_system')
          expect(result.output).to match(%r{.*--> on})
        end
      end
    end

    context 'when disabled' do
      it 'sets the context hieradata' do
        set_hieradata_on(client, disable_hieradata)
      end

      # Using puppet_apply as a helper
      it 'works with no errors' do
        apply_manifest_on(client, manifest, catch_failures: true)
      end

      it 'is idempotent' do
  apply_manifest_on(client, manifest, catch_changes: true)
      end

      describe package('clamav') {
        it { is_expected.not_to be_installed }
      }

      describe file('/etc/cron.daily/freshclam') {
        it { is_expected.not_to be_file }
      }

      it 'does not create a crontab entry' do
        stdout = on(client, 'crontab -l').stdout
        expect(stdout).not_to include('/usr/bin/clamscan -l /var/log/clamscan.log')
      end

      if on(client, '/usr/sbin/selinuxenabled', accept_all_exit_codes: true).exit_code == 0
        it 'has the selinux boolean "antivirus_can_scan_system" set' do
          result = on(client, '/usr/sbin/getsebool antivirus_can_scan_system')
          expect(result.output).to match(%r{.*--> off})
        end
      end
    end
  end
end
