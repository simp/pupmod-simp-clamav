# == Class: clamav::set_schedule
#
# This class allows you to set a schedule for ClamAV to run a check
# on your system via cron.
#
# See clamscan(1) for any undefined variables.
# All 'yes/no' variables have been translated to 'true/false' for consistency.
#
# Defaults to weekly.
#
# == Parameters
#
# [*enable*]
#   Enables/Disables the clamscan cronjob.  Defaults to true.
#
# [*minute*]
# [*hour*]
# [*monthday*]
# [*month*]
# [*weekday*]
#
# [*nice_level*]
#   The system 'nice' level at which to run the virus scan.
#
# [*scan_directory*]
#   An array of directories upon which to perform this scan.
#
# [*official_db_only*]
# [*logfile*]
# [*recursive*]
# [*cross_fs*]
# [*summary*]
# [*infected_only*]
# [*bytecode*]
# [*bytecode_unsigned*]
# [*bytecode_timeout*]
# [*detect_pua*]
# [*include_pua*]
# [*max_files*]
#
# [*max_filesize*]
#   The maximum archive size to scan, in megabytes.
#
# [*max_scansize*]
#   The maximum scanned file size to scan, in megabytes.
#
# [*max_recursion*]
# [*max_dir_recursion*]
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class clamav::set_schedule (
  Boolean                                      $enable            = true,
  Stdlib::Compat::Integer                      $minute            = '32',
  Stdlib::Compat::Integer                      $hour              = '5',
  Variant[Stdlib::Compat::Integer, Enum['*']]  $monthday          = '*',
  Variant[Stdlib::Compat::Integer, Enum['*']]  $month             = '*',
  Stdlib::Compat::Integer                      $weekday           = '0',
  Stdlib::Compat::Integer                      $nice_level        = '19',
  Array[String]                                $scan_targets      = ['/tmp','/var/tmp','/dev/shm'],
  Boolean                                      $official_db_only  = true,
  Stdlib::Absolutepath                         $logfile           = '/var/log/clamscan.log',
  Boolean                                      $recursive         = true,
  Boolean                                      $cross_fs          = true,
  Boolean                                      $summary           = false,
  Boolean                                      $infected_only     = true,
  Boolean                                      $bytecode          = true,
  Boolean                                      $bytecode_unsigned = false,
  Stdlib::Compat::Integer                      $bytecode_timeout  = '60000',
  Boolean                                      $detect_pua        = false,
  Array[String]                                $exclude_pua       = [],
  Array[String]                                $include_pua       = [],
  Stdlib::Compat::Integer                      $max_files         = '10000',
  Stdlib::Compat::Integer                      $max_filesize      = '25',
  Stdlib::Compat::Integer                      $max_scansize      = '100',
  Stdlib::Compat::Integer                      $max_recursion     = '16',
  Stdlib::Compat::Integer                      $max_dir_recursion = '15'
) {
  include 'logrotate'

  $_clamscan_ensure = $enable ? { true => 'present', default => 'absent' }
  cron { 'clamscan':
    ensure   => $_clamscan_ensure,
    command  => template('clamav/clamscan_cmd.erb'),
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday
  }

  # add the logrotate file
  logrotate::add { 'clamscan':
    log_files  => [ $logfile ],
    missingok  => true,
    lastaction => '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
  }
}
