require 'spec_helper_acceptance'

test_name 'clamav class'

describe 'clamav class' do
  # The clamav package lives in EPEL on Enterprise Linux.
  enable_epel_on(hosts)

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

  hosts.each do |client|
    # SELinux booleans can only be inspected/toggled when the host is running
    # SELinux in a mode that exposes the policy.  Docker containers generally
    # run with SELinux disabled (the daemon manages confinement on the host),
    # so we detect the live state on the SUT rather than assuming it.
    selinux_enabled = on(
      client,
      '/usr/sbin/selinuxenabled',
      accept_all_exit_codes: true,
    ).exit_code == 0

    # We need this for our tests to run properly!
    on client, 'puppet config set stringify_facts false'

    # The clamav module drops a freshclam job into /etc/cron.daily and relies
    # on a working cron provider.  Full EL installs ship `cronie`, but the
    # minimal container images used for Docker-based acceptance testing do not,
    # so install it here.  This is a no-op on hosts where it is already present
    # (e.g. Vagrant boxes).
    on client, 'puppet resource package cronie ensure=installed'

    context "on #{client}" do
      # Exercise noop from a clean (uninstalled) state: on a fresh node the Sicura
      # console previews the module with `puppet apply --noop`, which must not error
      # even though nothing clamav manages exists yet. Real idempotence is covered
      # by the applies below. A post-convergence noop check is deliberately omitted:
      # `puppet apply --noop --detailed-exitcodes` always exits 0, so it could never
      # fail and would test nothing.
      context 'in noop mode from a clean state' do
        # Setup, not an assertion: as before(:context) a failure errors this context
        # rather than aborting the whole suite under .rspec's --fail-fast. `puppet
        # resource` exits 0 whether it removes the package or finds it already absent
        # (no --detailed-exitcodes), so no acceptable_exit_codes override is needed.
        before(:context) do
          on(client, 'puppet resource package clamav ensure=absent')
        end

        it 'applies without errors in noop mode' do
          apply_manifest_on(client, manifest, catch_failures: true, noop: true)
        end

        # Proof noop engaged nothing: clamav is EL-only, so rpm -q exits 1 when the
        # package is absent; beaker raises on any other exit code.
        it 'does not install the clamav package' do
          on(client, 'rpm -q clamav', acceptable_exit_codes: [1])
        end
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

        if selinux_enabled
          it 'has the selinux boolean "antivirus_can_scan_system" set' do
            result = on(client, '/usr/sbin/getsebool antivirus_can_scan_system')
            expect(result.output).to match(%r{.*--> on})
          end
        else
          it 'skips the selinux boolean check (SELinux not enabled on this SUT)' do
            skip 'SELinux is not enabled on this SUT (expected under Docker)'
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

        if selinux_enabled
          it 'has the selinux boolean "antivirus_can_scan_system" set' do
            result = on(client, '/usr/sbin/getsebool antivirus_can_scan_system')
            expect(result.output).to match(%r{.*--> off})
          end
        else
          it 'skips the selinux boolean check (SELinux not enabled on this SUT)' do
            skip 'SELinux is not enabled on this SUT (expected under Docker)'
          end
        end
      end
    end
  end
end
