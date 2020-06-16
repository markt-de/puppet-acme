# puppet-acme

[![Build Status](https://travis-ci.org/fraenki/puppet-acme.png?branch=master)](https://travis-ci.org/fraenki/puppet-acme)
[![Puppet Forge](https://img.shields.io/puppetforge/v/fraenki/acme.svg)](https://forge.puppetlabs.com/fraenki/acme)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/fraenki/acme.svg)](https://forge.puppetlabs.com/fraenki/acme)
[![License](https://img.shields.io/github/license/fraenki/puppet-acme.svg)](https://github.com/fraenki/puppet-acme/blob/master/LICENSE.txt)

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Workflow](#workflow)
1. [Setup](#setup)
    * [Configure your Puppetserver](#configure-your-puppet-server)
1. [Usage](#usage)
    * [Request a certificate](#request-a-certificate)
    * [SAN certificates](#san-certificates)
    * [DNS alias mode](#dns-alias-mode)
    * [Testing and debugging](#testing-and-debugging)
1. [Examples](#examples)
    * [Apache](#apache)
1. [Reference](#reference)
    * [Files and directories](#files-and-directories)
    * [Classes and parameters](#classes-and-parameters)
1. [Limitations](#limitations)
    * [Requires multiple Puppet runs](#requires-multiple-puppet-runs)
    * [HTTP-01 challenge type untested](#http-01-challenge-type-untested)
    * [OS Compatibility](#os-compatibility)
1. [Development](#development)
1. [Fork](#fork)
1. [License](#license)

## Overview

Centralized SSL certificate management using Let's Encrypt™.
Keep your private keys safe on the host they belong to and let your Puppetserver
sign the CSRs and distribute the certificates.

## Requirements

* Puppet 6 with [Exported Resources](https://puppet.com/docs/puppet/latest/lang_exported.html) enabled
* A [compatible DNS provider](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) to validate your Let's Encrypt certificates

Furthermore it is highly recommended to use [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml)
to protect sensitive information (such as DNS API secrets).

## Workflow

This module creates private keys and CSRs, transfers the CSR to your Puppetserver
where it is signed using the popular and lightweight [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh).

Signed certificates are shipped back to the originating host.

You just need to specify the required challenge configuration on your Puppetserver.
All DNS-01 hooks that are [supported by acme.sh](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/README.md) will work immediately.

## Setup

### Configure your Puppetserver

The whole idea is centralized certificate management, thus you have to
add some configuration on your Puppetserver.

First configure the Let's Encrypt accounts that are available to issue
certificates:

~~~puppet
    Class { 'acme':
      accounts => ['certmaster@example.com', 'ssl@example.com']
      ...
    }
~~~

Next add configuration for the challenge types you want to use, we call
each configuration a "profile":

~~~puppet
    Class { 'acme':
      accounts => ['certmaster@example.com', 'ssl@example.com'],
      profiles => {
        nsupdate_example => {
          challengetype => 'dns-01',
          hook          => 'nsupdate',
          env           => {
            'NSUPDATE_SERVER' => 'bind.example.com'
          },
          options       => {
            dnssleep      => 15,
            nsupdate_id   => 'example-key',
            nsupdate_type => 'hmac-md5',
            nsupdate_key  => 'abcdefg1234567890',
          }
        },
        route53_example  => {
          challengetype => 'dns-01',
          hook          => 'aws',
          env           => {
            AWS_ACCESS_KEY_ID     => 'foobar',
            AWS_SECRET_ACCESS_KEY => 'secret',
          },
          options       => {
            dnssleep => 15,
          }
        }
      }
    }
~~~

In this example we create two "profiles": One is utilizing the "nsupdate" hook
to communicate with a BIND DNS server and the other one uses the "aws" hook to
communicate with Amazon Route53.

Note that the `hook` parameter must exactly match the name of the hook that is used by [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh).
Some DNS hooks require environment variables that contain usernames or API tokens,
simply add them to the `env` parameter.

All CSRs are collected and signed on your Puppetserver via PuppetDB, and the resulting
certificates and CA chain files are shipped back to the originating host via PuppetDB.

## Usage

### Request a certificate
On the Puppet node where you need the certificate(s):

~~~puppet
    class { 'acme':
      certificates => {
        # issue a test certificate
        test.example.com => {
          use_profile    => 'route53_example',
          use_account    => 'ssl@example.com',
          letsencrypt_ca => 'staging',
        }
        # a cert for the current FQDN is nice too
        ${::fqdn} => {
          use_profile    => 'nsupdate_example',
          use_account    => 'certmaster@example.com',
          letsencrypt_ca => 'production',
        },
      }
    }
~~~

*Note:* The `use_profile` and `use_account` parameters must match the profiles
and accounts that you've previously configured on your Puppetserver. Otherwise
the module will refuse to issue the certificate.

The private key and CSR will be generated on your node and the CSR is shipped
to your Puppetserver for signing. The certificate is put on your node as soon
as it was signed on your Puppetserver.

Instead of specifying the domains as parameter to the `acme` class, it is
also possible to use the `acme::certificate` defined type directly:

~~~puppet
    acme::certificate { 'test.example.com':
      use_profile    => 'route53_example',
      use_account    => 'ssl@example.com',
      letsencrypt_ca => 'staging',
    }
~~~

#### SAN certificates

Requesting SAN certificates is easy too. To do so add a space separated list
of domain names to the `certificates` hash.
The first domain name in each list is used as the base domain for the request.
For example:

~~~puppet
    class { 'acme':
      certificates => {
        'test.example.com foo.example.com bar.example.com' => {
          use_profile    => 'route53_example',
          use_account    => 'ssl@example.com',
          letsencrypt_ca => 'staging',
        }
    }
~~~

Or use the defined type directly:

~~~puppet
    acme::certificate { 'test.example.com foo.example.com bar.example.com':
      use_profile    => 'route53_example',
      use_account    => 'ssl@example.com',
      letsencrypt_ca => 'staging',
    }
~~~

In both examples "test.example.com" will be used as base domain for the CSR.

#### DNS alias mode

In order to use DNS alias mode, specify the domain name either in the `challenge_alias` or `domain_alias` parameter of your profile:

~~~puppet
    Class { 'acme':
      accounts => ['certmaster@example.com', 'ssl@example.com'],
      profiles => {
        route53_example  => {
          challengetype   => 'dns-01',
          challenge_alias => 'alias-example.com',
          hook            => 'aws',
          env             => {
            AWS_ACCESS_KEY_ID     => 'foobar',
            AWS_SECRET_ACCESS_KEY => 'secret',
          },
          options         => {
            challenge_alias => 'alias-example.com',
            dnssleep        => 15,
          }
        }
      }
    }
~~~

#### Testing and Debugging

For testing purposes you should use the Let's Encrypt staging CA, otherwise
you will hit rate limits pretty soon. It is possible to set the default CA on
your Puppetserver by using the `letsencrypt_ca` parameter:

~~~puppet
    class { 'acme' :
      letsencrypt_ca => 'staging'
    }
~~~

Or you can use this parameter directly when configuring certificates on your
Puppet nodes, as shown in the previous examples.

## Examples

### Apache
Using `acme` in combination with [puppetlabs-apache](https://github.com/puppetlabs/puppetlabs-apache):

~~~puppet
    # request a certificate from acme
    acme::certificate { $::fqdn:
      use_profile    => 'nsupdate_example',
      use_account    => 'certmaster@example.com',
      letsencrypt_ca => 'production',
      # restart apache when the certificate is signed (or renewed)
      notify         => Class['apache::service'],
    }

    # get configuration from acme
    include acme
    $base_dir = $acme::base_dir
    $crt_dir  = $acme::crt_dir
    $key_dir  = $acme::key_dir

    # where acme stores our certificate and key files
    $my_key = "${key_dir}/${::fqdn}/private.key"
    $my_cert = "${crt_dir}/${::fqdn}/cert.pem"
    $my_chain = "${crt_dir}/${::fqdn}/chain.pem"

    # configure apache
    include apache
    apache::vhost { $::fqdn:
      port     => '443',
      docroot  => '/var/www/example',
      ssl      => true,
      ssl_cert => "/etc/ssl/${::fqdn}.crt",
      ssl_ca   => "/etc/ssl/${::fqdn}.ca",
      ssl_key  => "/etc/ssl/${::fqdn}.key",
    }

    # copy certificate files
    file { "/etc/ssl/${::fqdn}.crt":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      source    => $my_cert,
      subscribe => Acme::Certificate[$::fqdn],
      notify    => Class['apache::service'],
    }
    file { "/etc/ssl/${::fqdn}.key":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0640',
      source    => $my_key,
      subscribe => Acme::Certificate[$::fqdn],
      notify    => Class['apache::service'],
    }
    file { "/etc/ssl/${::fqdn}.ca":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      source    => $my_chain,
      subscribe => Acme::Certificate[$::fqdn],
      notify    => Class['apache::service'],
    }
~~~

## Reference

### Files and directories

Locations of the important certificate files (i.e. "cert.example.com"):

* `/etc/acme.sh/certs/cert.example.com/cert.pem`: the certificate
* `/etc/acme.sh/certs/cert.example.com/chain.pem`: the CA chain
* `/etc/acme.sh/certs/cert.example.com/fullchain.pem`: Certificate and CA chain in one file
* `/etc/acme.sh/certs/cert.example.com/cert.ocsp`: OCSP Must-Staple extension data
* `/etc/acme.sh/keys/cert.example.com/private.key`: Private key
* `/etc/acme.sh/keys/cert.example.com/fullchain_with_key.pem`: All-in-one: certificate, CA chain, private key

Basic directory layout:

* `/etc/acme.sh/accounts`: (Puppetserver) Private keys and other files related to Let's Encrypt accounts
* `/etc/acme.sh/certs`: Certificates, CA chains and OCSP files
* `/etc/acme.sh/configs`: OpenSSL configuration and other files required for the CSR
* `/etc/acme.sh/csrs`: Certificate signing requests (CSR)
* `/etc/acme.sh/home`: (Puppetserver) Working directory for acme.sh
* `/etc/acme.sh/keys`: Private keys for each certificate
* `/etc/acme.sh/results`: (Puppetserver) Working directory, used to export certificates
* `/opt/acme.sh`: (Puppetserver) Local copy of acme.sh (GIT repository)
* `/var/log/acme.sh/acme.log`: (Puppetserver) acme.sh log file

### Classes and parameters

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

### Requires multiple Puppet runs

It takes several puppet runs to issue a certificate. Two Puppet runs are
required to prepare the CSR on your Puppet node. Two more Puppet runs
on your Puppetserver are required to sign the certificate and send it to
PuppetDB. Now it's ready to be collected by your Puppet node.

The process is seamless for certificate renewals, but it takes a little time
to issue a new certificate.

### HTTP-01 challenge type untested

The HTTP-01 challenge type is theoretically supported, but it is untested with this module.
Some additional parameters may be missing. Feel free to report issues
or suggest enhancements.

### OS Compatibility

This module was tested on CentOS/RedHat, Ubuntu/Debian and FreeBSD. Please open a new
issue if your operating system is not supported yet, and provide information
about problems or missing features.

## Development

Please use the GitHub issues functionality to report any bugs or requests for
new features. Feel free to fork and submit pull requests for potential
contributions.

## Fork

This module is a fork of the excellent [bzed/bzed-letsencrypt](https://github.com/bzed/bzed-letsencrypt/).
The fork was necessary in order to use acme.sh instead of dehydrated.

## License
Copyright (C) 2017-2020 Frank Wall
Based on [bzed/bzed-letsencrypt](https://github.com/bzed/bzed-letsencrypt/), Copyright 2017 Bernd Zeimetz.

Let's Encrypt is a trademark of the Internet Security Research Group. All rights reserved.

See the `LICENSE` file for further information.
