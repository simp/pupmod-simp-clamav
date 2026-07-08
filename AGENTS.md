# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`pupmod-simp-clamav` is a SIMP Puppet module that installs and manages the
**ClamAV command-line anti-virus scanner** on Enterprise Linux systems. It is
scanner-focused, not daemon-focused: it installs the `clamav` package, optionally
manages the `clam` service account, schedules on-demand scans via cron, keeps the
virus definitions up to date (via `freshclam` *or* the SIMP rsync subsystem), and
sets the SELinux boolean that lets the scanner read the whole filesystem. It does
**not** manage the `clamd`/`clamav-milter` resident daemon.

### Business logic

**`clamav` (`manifests/init.pp`)** — the main class.

- **Master kill-switch:** the whole class body is wrapped in
  `if simplib::lookup('simp_options::clamav', {'default_value' => true})`. Setting
  `simp_options::clamav: false` makes the module a **no-op** — importantly, it does
  *not* remove ClamAV from a system, it just stops managing it.
- **`$enable`** (default `true`) is the second, finer toggle: it flips package
  install vs. `absent`, the freshclam cron file, the rsync pull, and the
  SELinux boolean. (The **clamscan** cron is *not* flipped directly by this
  parameter — it is toggled by `clamav::set_schedule::enable`, which merely
  *defaults* from the `clamav::enable` Hiera key; see `set_schedule` below.)
  Note the two-level semantics: `simp_options::clamav => false`
  = "don't touch anything"; `enable => false` = "actively remove/disable".
- Calls `simplib::assert_metadata($module_name)`.
- If `$schedule_scan` (default `true`), includes `clamav::set_schedule`.
- If `$manage_group_and_user` (default `true`), manages the `clam` group and user
  (**fixed uid/gid `409`**, home `/var/lib/clamav`, `/sbin/nologin`). The `clamav`
  package `require`s them when managed.
- Installs `package { $package_name }` (default `clamav`) — `ensure` is
  `$package_ensure` when enabled, else `absent`.
- **Legacy cleanup:** on `x86_64`, force-removes the old `clamav.i386` and
  `clamav-lib.i386` packages (a fix for a past multilib update issue).
- **Definition updates — two mutually exclusive mechanisms, `freshclam` wins:**
  - If `$enable_freshclam`: installs `/etc/cron.daily/freshclam` from the static
    `files/freshclam.cron` (runs `freshclam` to pull definitions over the internet).
  - Else: ensures that cron file `absent`, and — if `$enable && $enable_data_rsync`
    and `$rsync_source` is non-empty — pulls DAT files from the SIMP rsync server
    into `/var/lib/clamav` (`rsync { 'clamav': delete => true }`). This is the
    air-gapped/SIMP-managed path. `rsync_server`/`rsync_timeout` default from
    `simp_options::rsync::*`.
- **SELinux:** when SELinux is enabled, sets the `antivirus_can_scan_system`
  boolean `on`/`off` (persistent) to match `$enable`.

**`clamav::set_schedule` (`manifests/set_schedule.pp`)** — builds the scheduled
scan.

- Creates `cron { 'clamscan' }` (as `root`) whose command is rendered by
  `templates/clamscan_cmd.erb`. Schedule defaults to **weekly** (Sunday 05:32,
  `nice -n 19`). Its own `clamav::set_schedule::enable` parameter — which
  defaults from `simplib::lookup('clamav::enable', ...)` — toggles the cron
  entry `present`/`absent`.
- The many parameters map to `clamscan(1)` flags: `$scan_targets` (default
  `['/tmp','/var/tmp','/dev/shm']` — deliberately **very conservative**, expect to
  widen it), size/recursion caps (`max_files`, `max_filesize`, `max_scansize`,
  `max_recursion`, `max_dir_recursion`), PUA detection, bytecode options, etc.
- If `$logrotate` (default from `simp_options::logrotate`), includes `logrotate`
  and adds a `logrotate::rule` for the scan `$logfile` (`/var/log/clamscan.log`).

**`templates/clamscan_cmd.erb`** assembles the `clamscan` command string from the
`set_schedule` parameters. **`files/freshclam.cron`** is the static daily
definition-update script.

## Dependencies

- `puppetlabs/stdlib` (`>= 8.0.0 < 10.0.0`).
- `simp/simplib` (`>= 4.9.0 < 5.0.0`) — `simplib::lookup`, `simplib::assert_metadata`,
  and `Simplib::*` types (`Simplib::Host`, `Simplib::Cron::*`).
- `simp/rsync` (`>= 6.1.1 < 7.0.0`) — the `rsync` resource used for the DAT-file pull.
- `simp/logrotate` (`>= 6.5.0 < 7.0.0`) — used only when `logrotate` is enabled.
- Runtime: `openvox >= 8.0.0 < 9.0.0` (see `metadata.json` `requirements`).
- Supported OS: EL7/8/9 across RedHat/CentOS/OracleLinux and EL8/9 for
  Rocky/AlmaLinux (see `metadata.json`).

## Repository layout

- `manifests/init.pp` — the `clamav` class (package, user/group, updates, SELinux).
- `manifests/set_schedule.pp` — the `clamav::set_schedule` class (clamscan cron + logrotate).
- `templates/clamscan_cmd.erb` — builds the `clamscan` command line.
- `files/freshclam.cron` — static `/etc/cron.daily/freshclam` definition updater.
- `spec/classes/` — rspec-puppet unit tests; `spec/fixtures/hieradata/` holds test data.
- `spec/acceptance/suites/default/` — beaker acceptance suite; `nodesets/` holds
  the per-OS node definitions.
- `REFERENCE.md` — generated Puppet Strings reference (do not hand-edit; regenerate).
- `metadata.json` — module metadata, dependencies, and supported OS matrix.

## Common commands

This module uses `puppetlabs_spec_helper` + `simp-rake-helpers` +
`simp-beaker-helpers`; tasks come from `Simp::Rake::Pupmod::Helpers` (see `Rakefile`).

```sh
bundle install

# Unit tests (rspec-puppet)
bundle exec rake spec

# A single spec file
bundle exec rspec spec/classes/init_spec.rb

# Lint / style
bundle exec rake lint
bundle exec rake rubocop

# Regenerate REFERENCE.md after changing manifest docstrings
bundle exec puppet strings generate --format markdown --out REFERENCE.md

# Acceptance tests (beaker; needs a hypervisor — CI uses vagrant_libvirt)
bundle exec rake beaker:suites[default]
```

Note `.rspec` sets `--fail-fast`, so `rake spec` stops at the first failure.

## Conventions

- This is a component of the SIMP ecosystem. Follow SIMP module conventions:
  parameters that reflect site-wide policy are resolved through `simp_options::*`
  hiera keys via `simplib::lookup`, defaulting to safe values so the module works
  standalone.
- Preserve the two-level disable semantics: `simp_options::clamav` = manage-or-not
  (never removes), `$enable` = install/remove-and-toggle. Don't conflate them.
- Preserve the freshclam-over-rsync precedence in `init.pp` when editing the
  definition-update logic — they are mutually exclusive by design.
- The default `scan_targets` are intentionally minimal; don't broaden them as a
  "fix" without cause — widening scan scope is a site policy decision.
- Keep manifest parameter `@param` docstrings current — `REFERENCE.md` is
  generated from them.
