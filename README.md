[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/clamav.svg)](https://forge.puppetlabs.com/simp/clamav)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/clamav.svg)](https://forge.puppetlabs.com/simp/clamav)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-clamav.svg)](https://travis-ci.org/simp/pupmod-simp-clamav)

## This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [This is a SIMP module](#this-is-a-simp-module)
* [Using clamav](#using-clamav)
  * [Enabling updates](#enabling-updates)
    * [freshclam](#freshclam)
    * [rsync](#rsync)
      * [Client side](#client-side)
      * [Server side](#server-side)
* [Limitations](#limitations)
* [Development](#development)
  * [Acceptance tests](#acceptance-tests)

<!-- vim-markdown-toc -->

## Description

This module provides an interface to the installation and management of ClamAV.

See [REFERENCE.md](./REFERENCE.md) for API documentation.

## This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html)

This module is optimally designed for use within a larger SIMP ecosystem, but
it can be used independently:

  * When included within the SIMP ecosystem, security compliance settings will
    be managed from the Puppet server.

  * If used independently, all SIMP-managed security subsystems are disabled by
    default and must be explicitly opted into by administrators.  Please review
    the `simp-simp_options` module for details.

The clamav module was removed from the  default class list in all simp scenarios
in SIMP 6.5.
Users of SIMP 6.5 or later must add clamav to the class list or include it via a manifest.

The catalyst `simp_options::clamav` has been deprecated. It will be removed
in future releases. It is still used as a wrapper for this module for
backwards compatibility.  You must therefore have `simp_options::clamav` undefined
or set to true for this module to do anything.

Setting the SIMP catalyst, `simp_options::clamav`, to false does not
uninstall ClamAV, it simply prevents this module from doing anything.
These catalysts are used by SIMP to allow users to override default
behavior of classes that are included by default. See the ``using clamav``
section below for how to remove clamav from the system.

## Using clamav

This module can be used to add or remove clamav from a system.

To manage ClamAV with this module:

```puppet
include clamav
```

By default this module will install ClamAV and set up a cron
to do a scan.
To remove ClamAV from the system set the following via Hiera:

```yaml
---
clamav::enable: false
```

### Enabling updates

Generally, your updates will be provided by an upstream package repository,
such as EPEL. However, there are two optional methods for enabling DAT file
updates.

#### freshclam

To enable the `freshclam` update system, set the following via Hiera:

```yaml
---
clamav::enable_freshclam: true
```

NOTE: No additional configuration of `freshclam` is currently supported. To
update the configuration file, you will need to create your own `File`
resource.

#### rsync

You may choose to enable `rsync` downloads of the DAT files from a SIMP `rsync`
server. The module defaults are already set to support this configuration.

##### Client side

Add the following to Hiera to enable `rsync` downloads:

```yaml
---
clamav::enable_data_rsync: true
```

##### Server side

To add DAT files to the server, you should place them in
`/var/simp/environments/<environment>/rsync/Global/clamav` and ensure that the
permissions are set to `409:409`.


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json)
for the most up-to-date list of supported operating systems, Puppet versions,
and module dependencies.


## Development

Please see the [SIMP Contribution Guidelines](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).


### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).
By default the tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.

Some environment variables may be useful:

```shell
BEAKER_debug=true
BEAKER_provision=no
BEAKER_destroy=no
BEAKER_use_fixtures_dir_for_modules=yes
```

* `BEAKER_debug`: show the commands being run on the STU and their output.
* `BEAKER_destroy=no`: prevent the machine destruction after the tests finish so you can inspect the state.
* `BEAKER_provision=no`: prevent the machine from being recreated. This can save a lot of time while you're writing the tests.
* `BEAKER_use_fixtures_dir_for_modules=yes`: cause all module dependencies to be loaded from the `spec/fixtures/modules` directory, based on the contents of `.fixtures.yml`.  The contents of this directory are usually populated by `bundle exec rake spec_prep`.  This can be used to run acceptance tests to run on isolated networks.
