# This class allows you to set a schedule for ClamAV to run a check
# on your system via cron.
#
# @see clamscan(1) for any undefined variables.
# All 'yes/no' variables have been translated to 'true/false' for consistency.
#
# Defaults to weekly.
#
# @param enable
#   Enables/Disables the clamscan cronjob.  Defaults to true.
# @param minute
# @param hour
# @param monthday
# @param month
# @param weekday
# @param nice_level
#   The system 'nice' level at which to run the virus scan.
# @param scan_directory
#   An array of directories upon which to perform this scan.
# @param official_db_only
# @param logfile
# @param recursive
# @param cross_fs
# @param summary
# @param infected_only
# @param bytecode
# @param bytecode_unsigned
# @param bytecode_timeout
# @param detect_pua
# @param include_pua
# @param max_files
# @param max_filesize
#   The maximum archive size to scan, in megabytes.
# @param max_scansize
#   The maximum scanned file size to scan, in megabytes.
# @param max_recursion
# @param max_dir_recursion
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class clamav::set_schedule (
  Boolean                       $enable            = true,
  Variant[String,Array[String]] $minute            = '32',
  Variant[String,Array[String]] $hour              = '5',
  Variant[String,Array[String]] $monthday          = '*',
  Variant[String,Array[String]] $month             = '*',
  Variant[String,Array[String]] $weekday           = '0',
  Integer                       $nice_level        = 19,
  Array[Stdlib::Absolutepath]   $scan_targets      = ['/tmp','/var/tmp','/dev/shm'],
  Boolean                       $official_db_only  = true,
  Stdlib::Absolutepath          $logfile           = '/var/log/clamscan.log',
  Boolean                       $recursive         = true,
  Boolean                       $cross_fs          = true,
  Boolean                       $summary           = false,
  Boolean                       $infected_only     = true,
  Boolean                       $bytecode          = true,
  Boolean                       $bytecode_unsigned = false,
  Integer                       $bytecode_timeout  = 60000,
  Boolean                       $detect_pua        = false,
  Array[String]                 $exclude_pua       = [],
  Array[String]                 $include_pua       = [],
  Integer                       $max_files         = 10000,
  Integer                       $max_filesize      = 25,
  Integer                       $max_scansize      = 100,
  Integer                       $max_recursion     = 16,
  Integer                       $max_dir_recursion = 15,
  Boolean                       $logrotate         = simplib::lookup('simp_options::logrotate', { 'default_value' => false })
) {

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
  if $logrotate {
    include '::logrotate'

    logrotate::rule { 'clamscan':
      log_files                 => [ $logfile ],
      missingok                 => true,
      lastaction_restart_logger => true
    }
  }
}
