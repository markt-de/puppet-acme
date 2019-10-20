# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## UNRELEASED

### Fixed
* Make sure `$acme_git_url` is passed to `acme::setup::puppetmaster` (#18)

## 1.0.3

### Added
* Allow certificate renewal requests to defer without failing (#8)
* Adding possibility to provide challenge alias for signing certificates (#11)
* Add posthook command (#15)

### Changed
* Use only lowercase for domains (#14)

### Fixed
* Fixes for Puppet 5 (#12)

## 1.0.2

### Changed
* Support openssl >= 1.1.0 (#4)

### Fixed
* Allow to request certs without OCSP Must-Staple extension (#3)

## 1.0.1

### Fixed
* Style fixes and documentation improvements

## 1.0.0
Initial release (fork of bzed-letsencrypt).
