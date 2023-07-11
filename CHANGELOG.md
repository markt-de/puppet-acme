# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [4.0.1] - 2023-07-11

### Changed
* Use modern facts in documentation ([#44])

## [4.0.0] - 2022-12-16
This major release aims to be compatible with all existing
configurations. However, a lot was changed unter the hood so
be careful when deploying this release.

### Added
* Allow the same certificate on multiple nodes ([#40])

### Changed
* Change names and output format of several custom facts ([#40])
* Replace dependency camptocamp/openssl with voxpupuli/openssl
* Update OS support and module dependencies
* Replace legacy facts with modern facts
* Migrate unit tests to GitHub Actions
* Update to PDK 2.5.0

### Fixed
* Fix unknown variable '_hook_params_pre'

## [3.0.0] - 2021-07-08
This new major release is a response to the most recent changes in acme.sh,
namely the switch from Let's Encrypt to ZeroSSL as default ACME CA. This module
will keep Let's Encrypt as the default CA, but adds support for all CA's that are
currently supported by acme.sh.

Existing users need to update acme.sh to a recent version (using the `$acme_revision`
parameter) and adopt the parameter changes, especially replacing the old parameter
`$letsencrypt_ca` with `$ca` (or `$default_ca` respectively).

### Added
* Add support for new ACME CA's: buypass, buypass_test, sslcom, zerossl
* Add parameters `$ca` and `$default_ca`
* Add parameter `$ca_whitelist` to specify which CA's will be used on `$acme_host`

### Changed
* Set default CA to Let's Encrypt
* New parameter `$ca` must be used to use Let's Encrypt "staging" environment (set it to `letsencrypt_test`)
* New parameter `$ca` must be used to use Let's Encrypt "production" environment (set it to `letsencrypt`)
* Rename parameter `$letsencrypt_proxy` to `$proxy`
* Adjust wording: replace "Let's Encrypt" with "ACME" wherever applicable

### Fixed
* Fix accidential switch from Let's Encrypt to ZeroSSL with recent version of acme.sh ([#33])

### Removed
* Remove parameter `$letsencrypt_ca`, new parameter `$ca` must be used instead

## [2.3.0] - 2020-08-17
NOTE: When upgrading from version 1.x to 2.x temporarely set `$acme_git_force` to `true`.

### Changed
* Replace deprecated acme.sh parameters ([#32])

## [2.2.0] - 2020-07-24

### Changed
* Change default value of `$acme_git_force` to `false`

### Fixed
* Fix an issue where certificates would incorrectly be deployed on Puppet Server ([#31])

## [2.1.0] - 2020-07-08
This is a maintenance release. It fixes an issue with deployment of signed certificates.

### Changed
* Small improvements to code readability and documentation
* Use `$facts` hash instead of top-scope variables
* Add messages for two common issues that could occur on first run

### Fixed
* Prevent duplicate declaration error if package git is already defined ([#30])
* Prevent cert files from being overwritten when using OCSP and wildcard certs

## [2.0.0] - 2020-06-16
This new major release is an effort to modernize the module. It fixes some long-standing bugs that have been uncovered by new unit tests. Please note that these bugfixes most likely trigger a re-issue of ALL certificates.

### Added
* Add support for FreeBSD ([#25], this time for real)
* Add unit tests
* Add parameter `$acme_revision` to checkout a different version of acme.sh
* Add parameter `$acme_git_force` to force acme.sh repository checkout
* Add parameter `$exec_timeout` to control how long acme.sh is allowed to run ([#28])
* Make `$dnssleep` optional, setting it to `0` lets acme.sh poll for DNS changes (DoH)

### Changed
* Migrate default values from `params.pp` to module data
* Convert templates to EPP
* Use Posix Shell instead of Bash
* Update list of supported operating systems
* Require Puppet 6
* Convert documentation to Puppet Strings
* Increase default timeout for acme.sh related `Exec` resources to 3600 seconds

### Fixed
* Only add subjectAltName for SAN certificates
* Add missing default value for `acme::dnssleep`
* Fix cert deployment when the OCSP Must-Staple extension is disabled
* Fix support for wildcard certificates (caused a server error)
* No longer overwrite acme.sh's changes in account config files

## [1.0.5] - 2020-06-03

### Added
* Add support for domain alias when using DNS alias mode
* Add support for FreeBSD

### Changed
* Update PDK to 1.18.0

### Fixed
* Fix possible conflicts in cert deployment on `$acme_host` ([#24]) 
* Correct syntax errors in the usage example ([#24])

## [1.0.4] - 2019-11-30

### Fixed
* Make sure `$acme_git_url` is passed to `acme::setup::puppetmaster` ([#18])
* Fix create dhparam command ([#19])
* Fix facts lookup on Puppet 5 ([#22])
* Fix duplicate resource error ([#20])

## [1.0.3] - 2019-09-18

### Added
* Allow certificate renewal requests to defer without failing ([#8])
* Adding possibility to provide challenge alias for signing certificates ([#11])
* Add posthook command ([#15])

### Changed
* Use only lowercase for domains ([#14])

### Fixed
* Fixes for Puppet 5 ([#12])

## [1.0.2] - 2017-11-13

### Changed
* Support openssl >= 1.1.0 ([#4])

### Fixed
* Allow to request certs without OCSP Must-Staple extension ([#3])

## [1.0.1] - 2017-04-16

### Fixed
* Style fixes and documentation improvements

## [1.0.0] - 2917-04-16
Initial release (fork of bzed-letsencrypt).

[Unreleased]: https://github.com/fraenki/puppet-acme/compare/4.0.1...HEAD
[4.0.1]: https://github.com/fraenki/puppet-acme/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/fraenki/puppet-acme/compare/3.0.0...4.0.0
[3.0.0]: https://github.com/fraenki/puppet-acme/compare/2.3.0...3.0.0
[2.3.0]: https://github.com/fraenki/puppet-acme/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/fraenki/puppet-acme/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/fraenki/puppet-acme/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/fraenki/puppet-acme/compare/1.0.5...2.0.0
[1.0.5]: https://github.com/fraenki/puppet-acme/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/fraenki/puppet-acme/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/fraenki/puppet-acme/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/fraenki/puppet-acme/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/fraenki/puppet-acme/compare/1.0.0...1.0.1
[#44]: https://github.com/fraenki/puppet-acme/pull/44
[#40]: https://github.com/fraenki/puppet-acme/pull/40
[#33]: https://github.com/fraenki/puppet-acme/pull/33
[#32]: https://github.com/fraenki/puppet-acme/pull/32
[#31]: https://github.com/fraenki/puppet-acme/pull/31
[#30]: https://github.com/fraenki/puppet-acme/pull/30
[#28]: https://github.com/fraenki/puppet-acme/pull/28
[#25]: https://github.com/fraenki/puppet-acme/pull/25
[#24]: https://github.com/fraenki/puppet-acme/pull/24
[#22]: https://github.com/fraenki/puppet-acme/pull/22
[#20]: https://github.com/fraenki/puppet-acme/pull/20
[#19]: https://github.com/fraenki/puppet-acme/pull/19
[#18]: https://github.com/fraenki/puppet-acme/pull/18
[#15]: https://github.com/fraenki/puppet-acme/pull/15
[#14]: https://github.com/fraenki/puppet-acme/pull/14
[#12]: https://github.com/fraenki/puppet-acme/pull/12
[#11]: https://github.com/fraenki/puppet-acme/pull/11
[#8]: https://github.com/fraenki/puppet-acme/pull/8
[#4]: https://github.com/fraenki/puppet-acme/pull/4
[#3]: https://github.com/fraenki/puppet-acme/pull/3
