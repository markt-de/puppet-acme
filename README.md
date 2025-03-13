# puppet-acme

[![Build Status](https://github.com/markt-de/puppet-acme/actions/workflows/ci.yaml/badge.svg)](https://github.com/markt-de/puppet-acme/actions/workflows/ci.yaml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/markt/acme.svg)](https://forge.puppetlabs.com/markt/acme)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/markt/acme.svg)](https://forge.puppetlabs.com/markt/acme)
[![License](https://img.shields.io/github/license/markt-de/puppet-acme.svg)](https://github.com/markt-de/puppet-acme/blob/master/LICENSE.txt)

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Workflow](#workflow)
1. [Setup](#setup)
    * [Configure your Puppet Server](#configure-your-puppet-server)
1. [Usage](#usage)
    * [Request a certificate](#request-a-certificate)
    * [Using other ACME CA's](#using-other-acme-cas)
    * [Wildcard certificates](#wildcard-certificates)
    * [SAN certificates](#san-certificates)
    * [Multiple certificates for one base domain](#multiple-certificates-for-one-base-domain)
    * [DNS alias mode](#dns-alias-mode)
    * [Custom CA](#custom-ca)
    * [Testing and debugging](#testing-and-debugging)
    * [Updating acme.sh](#updating-acmesh)
1. [Examples](#examples)
    * [Apache](#apache)
1. [Reference](#reference)
    * [Files and directories](#files-and-directories)
    * [Classes and parameters](#classes-and-parameters)
1. [Limitations](#limitations)
    * [Requires multiple Puppet runs](#requires-multiple-puppet-runs)
    * [HTTP-01 challenge type untested](#http-01-challenge-type-untested)
    * [Rebuilding nodes](#rebuilding-nodes)
    * [OS Compatibility](#os-compatibility)
1. [Development](#development)
1. [Fork](#fork)
1. [License](#license)

## Overview

Centralized SSL certificate management using Let's Encrypt™ or other ACME CA's.
Keep your private keys safe on the host they belong to and let your Puppet Server
sign the CSRs and distribute the certificates.

## Requirements

* Puppet with [Exported Resources](https://puppet.com/docs/puppet/latest/lang_exported.html) enabled (PuppetDB)
* A [compatible DNS provider](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) to validate your ACME certificates

Furthermore it is highly recommended to use [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml)
to protect sensitive information (such as DNS API secrets).

## Workflow

For every configured certificate, this module creates a private key and CSR, transfers the CSR to your Puppet Server
where it is signed using the popular and lightweight [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh).

Signed certificates are shipped back to the originating host. The private key is never exposed.

You just need to specify the required challenge configuration on your Puppet Server.
All DNS-01 hooks that are [supported by acme.sh](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/README.md) will work immediately.

## Setup

### Configure your Puppet Server

The whole idea is centralized certificate management, thus you have to
add some configuration on your Puppet Server.

First configure the ACME accounts that are available to issue certificates:

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
            'AWS_ACCESS_KEY_ID'     => 'foobar',
            'AWS_SECRET_ACCESS_KEY' => 'secret',
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

All CSRs are collected and signed on your Puppet Server via PuppetDB, and the resulting
certificates and CA chain files are shipped back to the originating host via PuppetDB.

## Usage

### Request a certificate
On the Puppet node where you need the certificate(s):

~~~puppet
    class { 'acme':
      certificates => {
        # issue a test certificate
        test.example.com => {
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'letsencrypt_test',
        }
        # a cert for the current FQDN is nice too
        ${facts['networking']['fqdn']} => {
          use_profile => 'nsupdate_example',
          use_account => 'certmaster@example.com',
          ca          => 'letsencrypt',
        },
      }
    }
~~~

*Note:* The `use_profile` and `use_account` parameters must match the profiles
and accounts that you've previously configured on your Puppet Server. Otherwise
the module will refuse to issue the certificate.

The private key and CSR will be generated on your node and the CSR is shipped
to your Puppet Server for signing. The certificate is put on your node as soon
as it was signed on your Puppet Server.

Instead of specifying the domains as parameter to the `acme` class, it is
also possible to use the `acme::certificate` defined type directly:

~~~puppet
    acme::certificate { 'test.example.com':
      use_profile => 'route53_example',
      use_account => 'ssl@example.com',
      ca          => 'letsencrypt_test',
    }
~~~

### Using other ACME CA's

This module uses the Let's Encrypt ACME CA by default. The default ACME CA can
be changed on the Puppet Server:

~~~puppet
    Class { 'acme':
      default_ca => 'zerossl',
      ca_whitelist => ['letsencrypt', 'letsencrypt_test', 'zerossl'],
      ...
    }
~~~

Note that other CA's must always be added to the `$ca_whitelist`, otherwise issueing
certificates will fail for this CA. By default only 'letsencrypt' and 'letsencrypt_test'
are whitelisted.

Besides that a different CA can also be specified for individual certificates:

~~~puppet
    class { 'acme':
      certificates => {
        test.example.com => {
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'zerossl',
        }
      }
    }
~~~

### Wildcard certificates

To request a wildcard certificate:

~~~puppet
    acme::certificate { '*.example.com':
      use_profile => 'route53_example',
      use_account => 'ssl@example.com',
      ca          => 'letsencrypt_test',
    }
~~~

Wildcard certificates may also use multiple domains names like `*.example.com example.com` (see below).

### SAN certificates

Requesting SAN certificates is easy too. To do so add a space separated list
of domain names to the `certificates` hash.
The first domain name in each list is used as the base domain for the request.
For example:

~~~puppet
    class { 'acme':
      certificates => {
        'test.example.com foo.example.com bar.example.com' => {
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'letsencrypt_test',
        }
    }
~~~

Or use the defined type directly:

~~~puppet
    acme::certificate { 'test.example.com foo.example.com bar.example.com':
      use_profile => 'route53_example',
      use_account => 'ssl@example.com',
      ca          => 'letsencrypt_test',
    }
~~~

In both examples "test.example.com" will be used as base domain for the CSR.

Alternatively, you can specify the domains explicitly:

~~~puppet
    class { 'acme':
      certificates => {
        'test.example.com' => {
          domain      => 'test.example.com foo.example.com bar.example.com',
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'letsencrypt_test',
        }
    }
~~~

or as a list of domains:

~~~puppet
    class { 'acme':
      certificates => {
        'test.example.com' => {
          domain      => ['test.example.com', 'foo.example.com', 'bar.example.com'],
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'letsencrypt_test',
        }
    }
~~~

It is recommended to use the first domain as name for the certificate resource,
to increase compatibility with the acme.sh script. However, it is not a strict
requirement, and is not possible when multiple certificates are required for the
same base name (see below).

### Multiple certificates for one base domain

Sometimes you need to issue multiple certificates for the same base domain.
This can happen either on a single node (for example one certificate with ocsp_must_staple flag
set, and one without it), or on multiple nodes (for example two failover nodes serving the same 
domain).

You can use the resource name to specify a unique identifier, and the `domain` parameter to
explicitly list the domain(s):

~~~puppet
    class { 'acme':
      certificates => {
        'mail.example.com (webserver)' => {
          domain      => 'mail.example.com',
          use_profile => 'route53_example',
          use_account => 'ssl@example.com',
          ca          => 'letsencrypt_test',
        },
        'mail.example.com (mailserver)' => {
          domain           => 'mail.example.com',
          use_profile      => 'route53_example',
          use_account      => 'ssl@example.com',
          ca               => 'letsencrypt_test',
          ocsp_must_staple => true,
        }
      }
   }
~~~

Please note that this functionality relies on an [undocumented feature of acme.sh](https://github.com/acmesh-official/acme.sh/pull/4384).

### DNS alias mode

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

### Custom CA

Any ACME CA may be used by specifying a name that does not conflict with the default CAs:

~~~puppet
    acme::certificate { 'test.example.com':
      use_profile => 'route53_example',
      use_account => 'ssl@example.com',
      ca          => 'private_ca123',
    }
~~~

Note that the CA URL must be configured and the CA name must be whitelisted on the Puppet Server:

~~~puppet
    Class { 'acme':
      default_ca   => 'letsencrypt',
      ca_config    => { private_ca123 => 'https://ca.example.com/acme/directory' },
      ca_whitelist => [ 'private_ca123', 'letsencrypt' ],
      ...
    }
~~~

### Testing and Debugging

For testing purposes you should use a test CA, such as `letsencrypt_test`. Otherwise
you will hit rate limits pretty soon. It is possible to set the default CA on
your Puppet Server by using the `default_ca` parameter:

~~~puppet
    class { 'acme' :
      default_ca => 'letsencrypt_test'
    }
~~~

Or you can use this parameter directly when configuring certificates on your
Puppet nodes, as shown in the previous examples.

Note that certificates generated by a test CA cannot be validated and as a result
will generate security warnings.

### Updating acme.sh

This module automatically updates acme.sh to the latest version, which may not
always be desirable. It is possible to change the `$acme_revision` parameter to
install a specific version of acme.sh:

~~~puppet
    class { 'acme' :
      acme_revision => '9293bcfb1cd5a56c6cede3f5f46af8529ee99624'
    }
~~~

The revision should be taken from the official acme.sh repository. In order to
revert to the latest version, the value should be set to 'master'.

## Examples

### Apache
Using `acme` in combination with [puppetlabs-apache](https://github.com/puppetlabs/puppetlabs-apache):

~~~puppet
    # request a certificate from acme
    acme::certificate { $facts['networking']['fqdn']:
      use_profile => 'nsupdate_example',
      use_account => 'certmaster@example.com',
      ca          => 'letsencrypt',
      # restart apache when the certificate is signed (or renewed)
      notify      => Class['apache::service'],
    }

    # get configuration from acme
    include acme
    $base_dir = $acme::base_dir
    $crt_dir  = $acme::crt_dir
    $key_dir  = $acme::key_dir

    # where acme stores our certificate and key files
    $my_key = "${key_dir}/${facts['networking']['fqdn']}/private.key"
    $my_cert = "${crt_dir}/${facts['networking']['fqdn']}/cert.pem"
    $my_chain = "${crt_dir}/${facts['networking']['fqdn']}/chain.pem"

    # configure apache
    include apache
    apache::vhost { $facts['networking']['fqdn']:
      port     => '443',
      docroot  => '/var/www/example',
      ssl      => true,
      ssl_cert => "/etc/ssl/${facts['networking']['fqdn']}.crt",
      ssl_ca   => "/etc/ssl/${facts['networking']['fqdn']}.ca",
      ssl_key  => "/etc/ssl/${facts['networking']['fqdn']fqdn}.key",
    }

    # copy certificate files
    file { "/etc/ssl/${facts['networking']['fqdn']}.crt":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      source    => $my_cert,
      subscribe => Acme::Certificate[$facts['networking']['fqdn']],
      notify    => Class['apache::service'],
    }
    file { "/etc/ssl/${facts['networking']['fqdn']}.key":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0640',
      source    => $my_key,
      subscribe => Acme::Certificate[$facts['networking']['fqdn']],
      notify    => Class['apache::service'],
    }
    file { "/etc/ssl/${facts['networking']['fqdn']}.ca":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      source    => $my_chain,
      subscribe => Acme::Certificate[$facts['networking']['fqdn']],
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

* `/etc/acme.sh/accounts`: (Puppet Server) Private keys and other files related to ACME accounts
* `/etc/acme.sh/certs`: Certificates, CA chains and OCSP files
* `/etc/acme.sh/configs`: OpenSSL configuration and other files required for the CSR
* `/etc/acme.sh/csrs`: Certificate signing requests (CSR)
* `/etc/acme.sh/home`: (Puppet Server) Working directory for acme.sh
* `/etc/acme.sh/keys`: Private keys for each certificate
* `/etc/acme.sh/results`: (Puppet Server) Working directory, used to export certificates
* `/opt/acme.sh`: (Puppet Server) Local copy of acme.sh (GIT repository)
* `/var/log/acme.sh/acme.log`: (Puppet Server) acme.sh log file

### Classes and parameters

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

### Requires multiple Puppet runs

It takes several puppet runs to issue a certificate. Two Puppet runs are
required to prepare the CSR on your Puppet node. Two more Puppet runs
on your Puppet Server are required to sign the certificate and send it to
PuppetDB. Now it's ready to be collected by your Puppet node.

The process is seamless for certificate renewals, but it takes a little time
to issue a new certificate.

### HTTP-01 challenge type untested

The HTTP-01 challenge type is theoretically supported, but it is untested with this module.
Some additional parameters may be missing. Feel free to report issues
or suggest enhancements.

### Rebuilding nodes

When rebuilding or reinstalling an existing node, the module will be unable to
create new or update existing certificates for this node. Instead a key mismatch
will occur, because an entirely new private key will be created on the node.

There is currently no way to fix this automatically [#6](https://github.com/markt-de/puppet-acme/issues/6).

The old files can be manually cleaned on the Puppet Server by running something
like this:

```
find /etc/acme.sh -name '*NODENAME*' -type f -delete
```

Besides that it may also be necessary to purge the old PuppetDB contents for this
node.

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
Copyright (C) 2017-2021 Frank Wall

Based on [bzed/bzed-letsencrypt](https://github.com/bzed/bzed-letsencrypt/), Copyright 2017 Bernd Zeimetz.

Let's Encrypt is a trademark of the Internet Security Research Group. All rights reserved.

See the `LICENSE` file for further information.
