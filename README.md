#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Module Description](#module-description)
1. [Setup](#setup)
    * [Configure your Puppet Server](#configure-your-puppet-server)
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
Keep your private keys safe on the host they belong to and let your Puppet
Server sign the CSRs and distribute the certificates.

## Requirements

* Puppet 4.x with [Exported Resources](https://docs.puppet.com/puppet/latest/lang_exported.html) enabled
* [puppetlabs/concat](https://github.com/puppetlabs/puppetlabs-concat)
* [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
* [puppetlabs/vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo)
* [camptocamp/openssl](https://github.com/camptocamp/puppet-openssl)

Furthermore you're advised to use [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml)
to protect sensitive information (such as DNS API secrets).

## Module Description

This module creates private keys and CSRs, transfers the CSR to your Puppet
Server where it is signed using the popular and lightweight [Neilpang/acme.sh](https://github.com/Neilpang/acme.sh).

Signed certificates are shipped back to the appropriate host.

You just need to specify the required challenge configuration on your Puppet
Server. All DNS-01 hooks that are [supported by acme.sh](https://github.com/Neilpang/acme.sh/blob/master/dnsapi/README.md) will work immediately.

## Setup

### Configure your Puppet Server

The whole idea is centralized certificate management, thus you have to
add some configuration on your Puppet Server.

First configure the Let's Encrypt accounts that are available to issue
certificates:

~~~puppet
    Class { 'acme':
      accounts => ['certmaster@example.com', 'ssl@example.com']
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
        }
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

Note that the `hook` parameter must exactly match the name of the hook that is used by [Neilpang/acme.sh](https://github.com/Neilpang/acme.sh).
Some DNS hooks require special environment variables, simply add them to the
`env` parameter.

All CSRs are collected and signed on your Puppet Server, and the resulting
certificates and CA chain files are shipped back to your nodes.

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
and accounts that you've previously configured on your Puppet Server. Otherwise
the module will refuse to issue the certificate.

The private key and CSR will be generated on your node and the CSR is shipped
to your Puppet Server for signing.
The certificate is put on your node after some time.

Instead of specifying the domains as parameter to the `acme` class, it is
possible to call the `acme::certificate` define directly:

~~~puppet
    ::acme::certificate { 'test.example.com':
      use_profile    => 'route53_example',
      use_account    => 'ssl@example.com',
      letsencrypt_ca => 'staging',
    }
~~~

#### SAN certificates

Requesting SAN certificates is easy too. To do so pass a space seperated list
of domain names in the `certificates` hash.
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

Or use the define directly:

~~~puppet
    ::acme::certificate { 'test.example.com foo.example.com bar.example.com':
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
            dnssleep => 15,
          }
        }
      }
    }
~~~

#### Testing and Debugging

For testing purposes you should use the Let's Encrypt staging CA, otherwise
you'll hit rate limits pretty soon. It's possible to set the default CA on
your Puppet Server by using the `letsencrypt_ca` parameter:

~~~puppet
    class { 'acme' :
      letsencrypt_ca => 'staging'
    }
~~~

Or you can use this parameter directly when configuring certificates on your
Puppet nodes, as shown by the previous examples.

## Examples

### Apache
Using `acme` in combination with [puppetlabs-apache](https://github.com/puppetlabs/puppetlabs-apache):

~~~puppet
    # request a certificate from acme
    ::acme::certificate { $::fqdn:
      use_profile    => 'nsupdate_example',
      use_account    => 'certmaster@example.com',
      letsencrypt_ca => 'production',
      # restart apache when the certificate is signed (or renewed)
      notify         => Class['::apache::service'],
    }

    # get configuration from acme::params
    include ::acme::params
    $base_dir = $::acme::params::base_dir
    $crt_dir  = $::acme::params::crt_dir
    $key_dir  = $::acme::params::key_dir

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
      notify    => Class['::apache::service'],
    }
    file { "/etc/ssl/${::fqdn}.key":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0640',
      source    => $my_key,
      subscribe => Acme::Certificate[$::fqdn],
      notify    => Class['::apache::service'],
    }
    file { "/etc/ssl/${::fqdn}.ca":
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      source    => $my_chain,
      subscribe => Acme::Certificate[$::fqdn],
      notify    => Class['::apache::service'],
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

* `/etc/acme.sh/accounts`: (Puppet Server) Private keys and other files related to Let's Encrypt accounts
* `/etc/acme.sh/certs`: Certificates, CA chains and OCSP files
* `/etc/acme.sh/configs`: OpenSSL configuration and other files required for the CSR
* `/etc/acme.sh/csrs`: Certificate signing requests (CSR)
* `/etc/acme.sh/home`: (Puppet Server) Working directory for acme.sh
* `/etc/acme.sh/keys`: Private keys for each certificate
* `/etc/acme.sh/results`: (Puppet Server) Working directory, used to export certificates
* `/opt/acme.sh`: (Puppet Server) Local copy of acme.sh (GIT repository)
* `/var/log/acme.sh/acme.log`: (Puppet Server) acme.sh log file

### Classes and parameters

Classes:
* `acme`
* `acme::params`
* `acme::request::handler`

Defines:
* `acme::csr`
* `acme::deploy`
* `acme::deploy::crt`
* `acme::request`
* `acme::request::crt`

Parameters:
* `acme_git_url`: URL to the acme.sh GIT repository (feel free to use a local mirror)
* `acme_host`: Defaults to your Puppet Server; override for testing purposes
* `dh_param_size`: DH parameter size, defaults to 2048
* `letsencrypt_ca`: The Let's Encrypt CA that should be used, choose either `staging` or `production`
* `letsencrypt_proxy`: A proxy server that should be used when connecting to the Let's Encrypt CA
* `manage_packages`: Set to `false` to disable package management. Defaults to `true`

Facts:
* `acme_csrs`
* `acme_csr_*`
* `acme_crts`

## Limitations

### Requires multiple Puppet runs

It takes several puppet runs to issue a certificate. Two Puppet runs are
required to prepare the CSR on your Puppet node. Two more Puppet runs
on your Puppet Server are required to sign the certificate. Now it's ready to be
collected by your Puppet node.

The process is seamless for certificate renewals, but it takes a little time
to issue a new certificate.

### HTTP-01 challenge type untested

The HTTP-01 challenge type is supported, but it's untested with this module.
Some additional parameters may be missing. Feel free to report issues
or suggest enhancements.

### OS Compatibility

This module was tested on CentOS/RedHat and Ubuntu/Debian. Please open a new
issue if your operating system is not supported yet, and provide information
about problems or missing features.

## Development

Please use the GitHub issues functionality to report any bugs or requests for
new features. Feel free to fork and submit pull requests for potential
contributions.

## Fork

This module is a fork of the excellent [bzed/bzed-letsencrypt](https://github.com/bzed/bzed-letsencrypt/).
The fork was necessary in order to support acme.sh instead of dehydrated.

## License
Based on [bzed/bzed-letsencrypt](https://github.com/bzed/bzed-letsencrypt/), Copyright 2017 Bernd Zeimetz.

Let's Encrypt is a trademark of the Internet Security Research Group. All rights reserved.

See the `LICENSE` file for further information.
