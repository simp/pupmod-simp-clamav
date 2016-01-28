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
# [*enable_schedule*]
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
  $enable_schedule = defined('$::enable_clamav') ? { true => $::enable_clamav, default => hiera('enable_clamav',true) },
  $minute = '32',
  $hour = '5',
  $monthday = '*',
  $month = '*',
  $weekday = '0',
  $nice_level = '19',
  $scan_targets = ['/tmp','/var/tmp','/dev/shm'],
  $official_db_only = true,
  $logfile = '/var/log/clamscan.log',
  $recursive = true,
  $cross_fs = true,
  $summary = false,
  $infected_only = true,
  $bytecode = true,
  $bytecode_unsigned = false,
  $bytecode_timeout = '60000',
  $detect_pua = false,
  $exclude_pua = [],
  $include_pua = [],
  $max_files = '10000',
  $max_filesize = '25',
  $max_scansize = '100',
  $max_recursion = '16',
  $max_dir_recursion = '15'
) {
  include 'logrotate'

  # Validation
  validate_bool($enable_schedule)
  validate_integer($minute)
  validate_integer($hour)
  validate_integer($weekday)
  validate_integer($nice_level)
  validate_array($scan_targets)
  validate_bool($official_db_only)
  validate_absolute_path($logfile)
  validate_bool($recursive)
  validate_bool($cross_fs)
  validate_bool($summary)
  validate_bool($infected_only)
  validate_bool($bytecode)
  validate_integer($bytecode_timeout)
  validate_bool($bytecode_unsigned)
  validate_bool($detect_pua)
  validate_array($exclude_pua)
  validate_array($include_pua)
  validate_integer($max_files)
  validate_integer($max_filesize)
  validate_integer($max_scansize)
  validate_integer($max_recursion)
  validate_integer($max_dir_recursion)

  # Disable clam scans if clamav is not enabled.
  $_clamscan_ensure = $enable_schedule ? { true => 'present', default => 'absent' }
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
