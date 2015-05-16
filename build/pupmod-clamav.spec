Summary: ClamAV Puppet Module
Name: pupmod-clamav
Version: 4.1.0
Release: 5
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-rsync >= 4.1.0-1
Requires: simp-rsync >= 4.0.1-14
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-clamav-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to install the ClamAV command line
virus scanner on your systems.

Virus database updates are distributed via rsync.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/clamav

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/clamav
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/clamav

%files
%defattr(0640,root,puppet,0750)
%{prefix}/clamav

%post
#!/bin/sh

if [ -d %{prefix}/clamav/plugins ]; then
  /bin/mv %{prefix}/clamav/plugins %{prefix}/clamav/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Fri Feb 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-5
- Updated to use the new 'simp' environment.
- Changed calls directly to /etc/init.d/rsyslog to '/sbin/service rsyslog' so
  that both RHEL6 and RHEL7 are properly supported.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Changed puppet-server requirement to puppet

* Mon Jun 23 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Fixed SELinux check for when selinux_current_mode is not found.

* Mon May 05 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Removed management of /var/lib/clamav to avoid SELinux labeling fights with
  Rsync. This directory is managed by the RPM.
- Fixed a template bug in the directory specifications.
- Changed scan_directory to scan_targets in set_schedule
- Set up the schedule by default via a boolean in the clamav class
- Removed /home from the default scan list and added /dev/shm

* Wed Apr 16 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-2
- Added spec tests.
- Fixed incorrect validation in manifests.

* Fri Apr 04 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-2
- Selinux booleans now set if mode != disabled

* Thu Feb 13 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-1
- Converted all string booleans into native booleans.

* Mon Dec 10 2013 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-0
- Changed singleton clamav::set_schedule define to paramterized class
  and updated code documentation for compatibility with puppet 3 and hiera.

* Tue Dec 10 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-11
- Removed the 'clamav' user and group since they are no longer used by the
  default clamav packages.
- Updated the configuration to allow for the removal of the freshclam cron job
  by default. If enabled, freshclam will be used instead of rsync.

* Sat Dec 07 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-10
- Modified the selinux boolean from clamscan_can_scan_system to
  antivirus_can_scan_system which is present in the newest versions of ClamAV

* Thu Oct 03 2013 Kendall Moore <kmoore@keywcorp.com> - 4.0.0-9
- Updated all erb templates to properly scope variables.

* Mon Jun 10 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-8
- Added support for more clamscan options in the clamav::set_schedule define
  and reduced the default noise level in the output so that user's cron logs
  aren't spammed.

* Thu May 02 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-7
- Set the clamscan_can_scan_system boolean for ClamAV

* Mon Feb 25 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-6
- Added a call to $::rsync_timeout to the rsync call since it is now required.
- Created a Cucumber test to ensure the clamav module installs correctly.
- We may have *finally* gotten rsync and the clamav module in sync!
  - The clamav user/group is 410
  - The clam user/group is 409

* Fri Nov 16 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-5
- Changed the group of /var/lib/clamav to 'clam' and the mode to 664
  for freshclam support.

* Fri Sep 21 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-4
- Reversed the order of removal for clamav.i686 and clamav_lib.i686 since they
  did not match the proper depencency order in the RPMs.

* Wed Apr 11 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-3
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-2
- Improved test stubs.

* Mon Dec 26 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-1
- Updated the spec file to not require a separate file list.

* Mon Nov 07 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-0
- Fixed call to rsyslog restart for RHEL6.

* Thu Jan 27 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-1
- Updated to use rsync native type

* Tue Jan 11 2011 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 27 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0-2
- Added set_schedule define

* Tue Oct 26 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0-1
- Converting all spec files to check for directories prior to copy.

* Wed May 19 2010 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0-0
- Code and Doc refactor

* Fri Nov 06 2009 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.1-0
- Initial Release
