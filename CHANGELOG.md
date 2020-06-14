# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
* Add support for FreeBSD ([#25], this time for real)
* Add unit tests
* Add parameter `$acme_revision` to checkout a different version of acme.sh

### Changed
* Migrate default values from `params.pp` to module data
* Convert templates to EPP
* Use Posix Shell instead of Bash
* Update list of supported operating systems
* Require Puppet 6
* Convert documentation to Puppet Strings

### Fixed
* Add missing default value for `acme::dnssleep`
* Fix cert deployment when the OCSP Must-Staple extension was disabled

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

[Unreleased]: https://github.com/fraenki/puppet-acme/compare/1.0.5...HEAD
[1.0.5]: https://github.com/fraenki/puppet-acme/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/fraenki/puppet-acme/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/fraenki/puppet-acme/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/fraenki/puppet-acme/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/fraenki/puppet-acme/compare/1.0.0...1.0.1
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
