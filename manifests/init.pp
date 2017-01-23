# This class installs the command line ClamAV anti-virus scanner and configures
# updates to be pulled from rsync.
#
# If you wish to schedule a virus scan, you will need to create a cron job that
# is appropriate, or drop a script into the cron.* directory that is
# appropriate.
#
# @param enable
#     Disables/Enables clamav.  Toggles freshclam/clamscan cronjobs, selbooleans,
#     rsync, and package installation.
#
# @param manage_group_and_user
#     Optionally manage the clamav user and group.
#
# @param clamav_user
#     The clamav user.
#
# @param clamav_group
#     The clamav group.
#
# @param package_name
#     The name of clamav rpm package.
#
# @param enable_freshclam
#     If true, will enable the freshclam cron job, otherwise rsync will be used.
#
# @param schedule_scan
#     If true, will enable the scheduled system scan.
#     The default targets are *extremely* conservative so you'll probably want to
#     adjust this.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class clamav (
  Boolean       $enable                = true,
  Boolean       $manage_group_and_user = true,
  String        $clamav_user           = 'clam',
  String        $clamav_group          = 'clam',
  String        $package_name          = 'clamav',
  Boolean       $enable_freshclam      = false,
  Boolean       $schedule_scan         = true,
  String        $rsync_source          = "clamav_${::environment}/",
  Simplib::Host $rsync_server          = simplib::lookup('simp_options::rsync::server', { 'default_value'  => '127.0.0.1' }),
  Integer       $rsync_timeout         = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 }),
) {

  # If the catalyst is disabled, don't manage anything
  if simplib::lookup('simp_options::clamav', { 'default_value' =>  true }) {

    if $schedule_scan {
      include '::clamav::set_schedule'
    }

    if $manage_group_and_user {
      group { $clamav_group:
        ensure    =>  'present',
        allowdupe => false,
        gid       => '409'
      }
      user { $clamav_user:
        ensure     => 'present',
        allowdupe  => false,
        comment    => 'Clam Anti Virus Checker',
        uid        => '409',
        shell      => '/sbin/nologin',
        gid        => $clamav_group,
        home       => '/var/lib/clamav',
        membership => 'inclusive',
        require    => Group[$clamav_group]
      }
    }

    # Require the user and group if managing them, otherwise don't.
    $_clamav_package_enable = $enable ? { true =>  'latest', default => 'absent' }
    $_clamav_package_requires = $manage_group_and_user ? { true => [User[$clamav_user],Group[$clamav_group]], default => [] }
    package { $package_name:
      ensure  => $_clamav_package_enable,
      require => $_clamav_package_requires,
    }

    # This is hackery to fix an update issue from the past.
    if $::hardwaremodel == 'x86_64' {
      package { 'clamav.i386':
        ensure => 'absent',
        notify => Package['clamav-lib.i386']
      }
      package { 'clamav-lib.i386':
        ensure => 'absent',
        notify => Package[$package_name]
      }
    }

    if $enable_freshclam {
      $_fresclam_ensure = $enable ? {true =>'file', default => 'absent'}
      file { '/etc/cron.daily/freshclam':
        ensure => $_fresclam_ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/clamav/freshclam.cron'
      }
    }
    else {
      file { '/etc/cron.daily/freshclam': ensure => 'absent' }

      if $enable {
        rsync { 'clamav':
          source  => $rsync_source,
          target  => '/var/lib/clamav',
          server  => $rsync_server,
          timeout => $rsync_timeout,
          delete  => true,
          require => Package[$package_name]
        }
      }
    }

    if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
      $_selboolean_value = $enable ? {true =>  'on', default => 'off'}
      selboolean { 'antivirus_can_scan_system':
        persistent => true,
        value      => $_selboolean_value
      }
    }
  }
}
