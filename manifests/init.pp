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
# [*enable_freshclam*]
# Type: Boolean
# Default: false
#   If true, will enable the freshclam cron job, otherwise rsync will be used.
#
# [*schedule_scan*]
# Type: Boolean
# Default: true
#   If true, will enable the scheduled system scan.
#   The default targets are *extremely* conservative so you'll probably want to
#   adjust this.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class clamav (
  $enable_freshclam = false,
  $schedule_scan = true,
  $rsync_server = hiera('rsync::server'),
  $rsync_timeout = hiera('rsync::timeout', '2')
) {

  if $schedule_scan { include clamav::set_schedule }

  group { 'clam':
    ensure    => 'present',
    allowdupe => false,
    gid       => '409'
  }

  package { 'clamav':
    ensure  => 'latest',
    require => [
      User['clam'],
      Group['clam']
    ]
  }

  # This is hackery to fix an update issue from the past.
  if $::hardwaremodel == 'x86_64' {
    package { 'clamav.i386':
      ensure => 'absent',
      notify => Package['clamav-lib.i386']
    }
    package { 'clamav-lib.i386':
      ensure => 'absent',
      notify => Package['clamav']
    }
  }

  if $enable_freshclam {
    file { '/etc/cron.daily/freshclam':
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/clamav/freshclam.cron'
    }
  }
  else {
    file { '/etc/cron.daily/freshclam': ensure => 'absent' }

    rsync { 'clamav':
      source  => 'clamav/',
      target  => '/var/lib/clamav',
      server  => $rsync_server,
      timeout => $rsync_timeout,
      delete  => true,
      require => [
        Package['clamav'],
        User['clam']
      ]

    }
  }

  if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
    selboolean { 'antivirus_can_scan_system':
      persistent => true,
      value      => 'on'
    }
  }

  user { 'clam':
    ensure     => 'present',
    allowdupe  => false,
    comment    => 'Clam Anti Virus Checker',
    uid        => '409',
    shell      => '/sbin/nologin',
    gid        => 'clam',
    home       => '/var/lib/clamav',
    membership => 'inclusive',
    require    => Group['clam']
  }
}
