# == Class: clamav
#
# This class installs the command line ClamAV anti-virus scanner and configures
# updates to be pulled from rsync.
#
# If you wish to schedule a virus scan, you will need to create a cron job that
# is appropriate, or drop a script into the cron.* directory that is
# appropriate.
#
# == Variables
#
# [*enable_clamav*]
#   Type: Boolean
#   Default: true
#     Disables/Enables clamav.  Toggles freshclam/clamscan cronjobs, selbooleans,
#     rsyc, and package installation.  Defaults to true.
#
# [*manage_group_and_user*]
#   Type: Boolean
#   Default: true
#     Optionally manage the clamav user and group.
#
# [*clamav_user*]
#   Type: String
#   Default: clam
#     The clamav user.
#
# [*clamav_group*]
#   Type: String
#   Default: clam
#     The clamav group.
#
# [*package_name*]
#   Type: String
#   Default: clamav
#     The name of clamav rpm package.
#
# [*enable_freshclam*]
#   Type: Boolean
#   Default: false
#     If true, will enable the freshclam cron job, otherwise rsync will be used.
#
# [*schedule_scan*]
#   Type: Boolean
#   Default: true
#     If true, will enable the scheduled system scan.
#     The default targets are *extremely* conservative so you'll probably want to
#     adjust this.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class clamav (
  $enable_clamav         = defined('$::enable_clamav') ? { true => $::enable_clamav, default => hiera('enable_clamav',true) },
  $manage_group_and_user = true,
  $clamav_user           = 'clam',
  $clamav_group          = 'clam',
  $package_name          = 'clamav',
  $enable_freshclam      = false,
  $schedule_scan         = true,
  $rsync_server          = hiera('rsync::server',''),
  $rsync_timeout         = hiera('rsync::timeout', '2')
) {

  # Validation.
  validate_bool($enable_clamav)
  validate_bool($manage_group_and_user)
  validate_string($package_name)
  validate_bool($enable_freshclam)
  validate_bool($schedule_scan)
  validate_integer($rsync_timeout)


  if $schedule_scan {
    include clamav::set_schedule
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
  $_clamav_package_ensure   = $enable_clamav ? { true => 'latest', default => 'absent' }
  $_clamav_package_requires = $manage_group_and_user ? { true => [User[$clamav_user],Group[$clamav_group]], default => [] }
  package { $package_name:
    ensure  => $_clamav_package_ensure,
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
    # Remove freshclam if clamav is not enabled.
    $_clamav_file_ensure   = $enable_clamav ? { true => 'file', default => 'absent' }
    file { '/etc/cron.daily/freshclam':
      ensure => $_clamav_file_ensure,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/clamav/freshclam.cron'
    }
  }
  else {
    if empty($rsync_server) {
      fail('You must supply a value for $rsync_server')
    }
    else {
      validate_net_list($rsync_server)
    }

    file { '/etc/cron.daily/freshclam': ensure => 'absent' }

    # Only rsync if clamav is enabled.
    if $enable_clamav {
      rsync { 'clamav':
        source  => 'clamav/',
        target  => '/var/lib/clamav',
        server  => $rsync_server,
        timeout => $rsync_timeout,
        delete  => true,
        require => Package[$package_name]
      }
    }
  }

  if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
    $_clamav_av_enable = $enable_clamav ? { true => 'on', default => 'off' }
    selboolean { 'antivirus_can_scan_system':
      persistent => true,
      value      => $_clamav_av_enable
    }
  }
}
