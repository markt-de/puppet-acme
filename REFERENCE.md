# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

#### Public Classes

* [`acme`](#acme): Install and configure acme.sh to manage SSL certificates

#### Private Classes

* `acme::request::handler`: Gather all data and use acme.sh to create accounts and sign certificates.
* `acme::setup::common`: Setup all necessary directories, users and groups.
* `acme::setup::puppetmaster`: Setup acme.sh and all necessary directories and packages.

### Defined types

#### Public Defined types

* [`acme::certificate`](#acme--certificate): Request a certificate.

#### Private Defined types

* `acme::csr`: Create a Certificate Signing Request (CSR) and send it to PuppetDB
* `acme::deploy`: Collects signed certificates for this host from PuppetDB.
* `acme::deploy::crt`: Install a signed certificate on the target host.
* `acme::request`: A request to sign a CSR or renew a certificate.
* `acme::request::crt`: Fetch the certificate from facter and export it via PuppetDB.
* `acme::request::ocsp`: Retrieve ocsp stapling information

### Functions

* [`file_or_empty_string`](#file_or_empty_string): Return the contents of a file.  Multiple files can be passed, and the first file that exists will be read in.

## Classes

### <a name="acme"></a>`acme`

Install and configure acme.sh to manage SSL certificates

#### Parameters

The following parameters are available in the `acme` class:

* [`accounts`](#-acme--accounts)
* [`acct_dir`](#-acme--acct_dir)
* [`acme_dir`](#-acme--acme_dir)
* [`acme_git_url`](#-acme--acme_git_url)
* [`acme_git_force`](#-acme--acme_git_force)
* [`acme_host`](#-acme--acme_host)
* [`acme_install_dir`](#-acme--acme_install_dir)
* [`acme_revision`](#-acme--acme_revision)
* [`acmecmd`](#-acme--acmecmd)
* [`acmelog`](#-acme--acmelog)
* [`base_dir`](#-acme--base_dir)
* [`ca_whitelist`](#-acme--ca_whitelist)
* [`certificates`](#-acme--certificates)
* [`cfg_dir`](#-acme--cfg_dir)
* [`crt_dir`](#-acme--crt_dir)
* [`csr_dir`](#-acme--csr_dir)
* [`date_expression`](#-acme--date_expression)
* [`default_account`](#-acme--default_account)
* [`default_ca`](#-acme--default_ca)
* [`default_profile`](#-acme--default_profile)
* [`dh_param_size`](#-acme--dh_param_size)
* [`dnssleep`](#-acme--dnssleep)
* [`exec_timeout`](#-acme--exec_timeout)
* [`group`](#-acme--group)
* [`key_dir`](#-acme--key_dir)
* [`log_dir`](#-acme--log_dir)
* [`manage_packages`](#-acme--manage_packages)
* [`ocsp_must_staple`](#-acme--ocsp_must_staple)
* [`ocsp_request`](#-acme--ocsp_request)
* [`path`](#-acme--path)
* [`posthook_cmd`](#-acme--posthook_cmd)
* [`profiles`](#-acme--profiles)
* [`proxy`](#-acme--proxy)
* [`renew_days`](#-acme--renew_days)
* [`results_dir`](#-acme--results_dir)
* [`shell`](#-acme--shell)
* [`stat_expression`](#-acme--stat_expression)
* [`user`](#-acme--user)

##### <a name="-acme--accounts"></a>`accounts`

Data type: `Array`

An array of e-mail addresses that acme.sh may use during the ACME
account registration. Should only be defined on $acme_host.

##### <a name="-acme--acct_dir"></a>`acct_dir`

Data type: `Stdlib::Absolutepath`

The directory for acme.sh accounts.

##### <a name="-acme--acme_dir"></a>`acme_dir`

Data type: `Stdlib::Absolutepath`

The working directory for acme.sh.

##### <a name="-acme--acme_git_url"></a>`acme_git_url`

Data type: `String`

URL to the acme.sh GIT repository. Defaults to the official GitHub project.
Feel free to use a local mirror or fork.

##### <a name="-acme--acme_git_force"></a>`acme_git_force`

Data type: `Boolean`

Force repository creation, destroying any files on the path in the process.
Useful when the repo URL has changed.

##### <a name="-acme--acme_host"></a>`acme_host`

Data type: `String`

The host you want to run acme.sh on.
For now it needs to be a puppetmaster, as it needs direct access
to the certificates using functions in Puppet.

##### <a name="-acme--acme_install_dir"></a>`acme_install_dir`

Data type: `Stdlib::Absolutepath`

The installation directory for acme.sh.

##### <a name="-acme--acme_revision"></a>`acme_revision`

Data type: `String`

The GIT revision of the acme.sh repository. Defaults to `master` which should
contain a stable version of acme.sh.

##### <a name="-acme--acmecmd"></a>`acmecmd`

Data type: `String`

The binary path to acme.sh.

##### <a name="-acme--acmelog"></a>`acmelog`

Data type: `Stdlib::Absolutepath`

The log file.

##### <a name="-acme--base_dir"></a>`base_dir`

Data type: `Stdlib::Absolutepath`

The configuration base directory for acme.sh.

##### <a name="-acme--ca_whitelist"></a>`ca_whitelist`

Data type: `Array`

Specifies the CAs that may be used on `$acme_host`. The module will register
any account specified in `$accounts` with all specified CAs. This ensure that
these accounts are ready for use.

##### <a name="-acme--certificates"></a>`certificates`

Data type: `Hash`

Array of full qualified domain names you want to request a certificate for.
For SAN certificates you need to pass space seperated strings,
for example ['foo.example.com fuzz.example.com', 'blub.example.com']

##### <a name="-acme--cfg_dir"></a>`cfg_dir`

Data type: `Stdlib::Absolutepath`

The directory for acme.sh configs.

##### <a name="-acme--crt_dir"></a>`crt_dir`

Data type: `Stdlib::Absolutepath`

The directory for acme.sh certificates.

##### <a name="-acme--csr_dir"></a>`csr_dir`

Data type: `Stdlib::Absolutepath`

The directory for acme.sh CSRs.

##### <a name="-acme--date_expression"></a>`date_expression`

Data type: `String`

The command used to calculate renewal dates for existing certificates.

##### <a name="-acme--default_account"></a>`default_account`

Data type: `Optional[String]`

The default account that should be used to new certificate requests.
The account must already be defined in `$accounts`.
May be overriden by specifying `$use_account` for the certificate.

Default value: `undef`

##### <a name="-acme--default_ca"></a>`default_ca`

Data type: `Enum['buypass', 'buypass_test', 'letsencrypt', 'letsencrypt_test', 'sslcom', 'zerossl']`

The default ACME CA that should be used to new certificate requests.
May be overriden by specifying `$ca` for the certificate.
Previous versions of acme.sh used to have Let's Encrypt as their default CA,
hence this is the default value for this Puppet module.

##### <a name="-acme--default_profile"></a>`default_profile`

Data type: `Optional[String]`

The default profile that should be used to new certificate requests.
The profile must already be defined in `$profile`.
May be overriden by specifying `$use_profile` for the certificate.

Default value: `undef`

##### <a name="-acme--dh_param_size"></a>`dh_param_size`

Data type: `Integer`

Specifies the DH parameter size, defaults to `2048`.

##### <a name="-acme--dnssleep"></a>`dnssleep`

Data type: `Integer`

The time in seconds acme.sh should wait for all DNS changes to take effect.
Settings this to `0` disables the sleep mechanism and lets acme.sh poll DNS
status automatically by using DNS over HTTPS.

##### <a name="-acme--exec_timeout"></a>`exec_timeout`

Data type: `Integer`

Specifies the time in seconds that any acme.sh operation can take before
it is aborted by Puppet. This should usually be set to a higher value
than `$dnssleep`.

##### <a name="-acme--group"></a>`group`

Data type: `String`

The group for acme.sh.

##### <a name="-acme--key_dir"></a>`key_dir`

Data type: `Stdlib::Absolutepath`

The directory for acme.sh keys.

##### <a name="-acme--log_dir"></a>`log_dir`

Data type: `Stdlib::Absolutepath`

The log directory for acme.sh.

##### <a name="-acme--manage_packages"></a>`manage_packages`

Data type: `Boolean`

Whether the module should install necessary packages, mainly git.
Set to `false` to disable package management.

##### <a name="-acme--ocsp_must_staple"></a>`ocsp_must_staple`

Data type: `Boolean`

Whether to request certificates with OCSP Must-Staple extension, defaults to `true`.

##### <a name="-acme--ocsp_request"></a>`ocsp_request`

Data type: `Stdlib::Absolutepath`

The script used by acme.sh to get OCSP data.

##### <a name="-acme--path"></a>`path`

Data type: `String`

The content of the PATH env variable when running Exec resources.

##### <a name="-acme--posthook_cmd"></a>`posthook_cmd`

Data type: `String`

Specifies a optional command to run after a certificate has been changed.

##### <a name="-acme--profiles"></a>`profiles`

Data type: `Optional[Hash]`

A hash of profiles that contain information how acme.sh should sign
certificates. A profile defines not only the challenge type, but also all
required parameters and credentials used by acme.sh to sign the certificate.
Should only be defined on $acme_host.

Default value: `undef`

##### <a name="-acme--proxy"></a>`proxy`

Data type: `Optional[String]`

Proxy server to use to connect to the ACME CA, for example `proxy.example.com:3128`

Default value: `undef`

##### <a name="-acme--renew_days"></a>`renew_days`

Data type: `Integer`

Specifies the interval at which certs should be renewed automatically. Defaults to `60`.

##### <a name="-acme--results_dir"></a>`results_dir`

Data type: `Stdlib::Absolutepath`

The output directory for acme.sh.

##### <a name="-acme--shell"></a>`shell`

Data type: `String`

The shell for the acme.sh user account.

##### <a name="-acme--stat_expression"></a>`stat_expression`

Data type: `String`

The command used to get the modification time of a file.

##### <a name="-acme--user"></a>`user`

Data type: `String`

The user for acme.sh.

## Defined types

### <a name="acme--certificate"></a>`acme::certificate`

Request a certificate.

#### Parameters

The following parameters are available in the `acme::certificate` defined type:

* [`acme_host`](#-acme--certificate--acme_host)
* [`ca`](#-acme--certificate--ca)
* [`dh_param_size`](#-acme--certificate--dh_param_size)
* [`domain`](#-acme--certificate--domain)
* [`ocsp_must_staple`](#-acme--certificate--ocsp_must_staple)
* [`posthook_cmd`](#-acme--certificate--posthook_cmd)
* [`renew_days`](#-acme--certificate--renew_days)
* [`use_account`](#-acme--certificate--use_account)
* [`use_profile`](#-acme--certificate--use_profile)

##### <a name="-acme--certificate--acme_host"></a>`acme_host`

Data type: `String`

The host you want to run acme.sh on. Usually your Puppet Server.
Defaults to `$acme::acme_host`.

Default value: `$acme::acme_host`

##### <a name="-acme--certificate--ca"></a>`ca`

Data type: `Optional[Enum['buypass', 'buypass_test', 'letsencrypt', 'letsencrypt_test', 'sslcom', 'zerossl']]`

The ACME CA that should be used. Used to overwrite the default
CA that is configured on `$acme_host`.

Default value: `$acme::default_ca`

##### <a name="-acme--certificate--dh_param_size"></a>`dh_param_size`

Data type: `Integer`

dh parameter size, defaults to $acme::dh_param_size

Default value: `$acme::dh_param_size`

##### <a name="-acme--certificate--domain"></a>`domain`

Data type: `Variant[String, Array[String], Undef]`

Full qualified domain names you want to request a certificate for.
For SAN certificates you need to pass space seperated strings,
for example 'foo.example.com fuzz.example.com', or an array of names.

If no domain is specified, the resource name will be parsed as a
list of domains, and the first domain will be used as certificate name.

Default value: `undef`

##### <a name="-acme--certificate--ocsp_must_staple"></a>`ocsp_must_staple`

Data type: `Boolean`

request certificate with OCSP Must-Staple exctension, defaults to $acme::ocsp_must_staple

Default value: `$acme::ocsp_must_staple`

##### <a name="-acme--certificate--posthook_cmd"></a>`posthook_cmd`

Data type: `String`

Specifies a optional command to run after a certificate has been changed.

Default value: `$acme::posthook_cmd`

##### <a name="-acme--certificate--renew_days"></a>`renew_days`

Data type: `Integer`

Specifies the interval at which certs should be renewed automatically. Defaults to `60`.

Default value: `$acme::renew_days`

##### <a name="-acme--certificate--use_account"></a>`use_account`

Data type: `String`

The ACME account that should be used (or registered).
This account must exist in `$accounts` on your `$acme_host`.

Default value: `$acme::default_account`

##### <a name="-acme--certificate--use_profile"></a>`use_profile`

Data type: `String`

Specify the profile that should be used to sign the certificate.
This profile must exist in `$profiles` on your `$acme_host`.

Default value: `$acme::default_profile`

## Functions

### <a name="file_or_empty_string"></a>`file_or_empty_string`

Type: Ruby 3.x API

Return the contents of a file.  Multiple files
can be passed, and the first file that exists will be read in.

#### `file_or_empty_string()`

Return the contents of a file.  Multiple files
can be passed, and the first file that exists will be read in.

Returns: `Any`

