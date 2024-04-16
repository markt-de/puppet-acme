# @summary Install and configure acme.sh to manage SSL certificates
#
# @param accounts
#   An array of e-mail addresses that acme.sh may use during the ACME
#   account registration. Should only be defined on $acme_host.
#
# @param acct_dir
#   The directory for acme.sh accounts.
#
# @param acme_dir
#   The working directory for acme.sh.
#
# @param acme_git_url
#   URL to the acme.sh GIT repository. Defaults to the official GitHub project.
#   Feel free to use a local mirror or fork.
#
# @param acme_git_force
#   Force repository creation, destroying any files on the path in the process.
#   Useful when the repo URL has changed.
#
# @param acme_host
#   The host you want to run acme.sh on.
#   For now it needs to be a puppetmaster, as it needs direct access
#   to the certificates using functions in Puppet.
#
# @param acme_install_dir
#   The installation directory for acme.sh.
#
# @param acme_revision
#   The GIT revision of the acme.sh repository. Defaults to `master` which should
#   contain a stable version of acme.sh.
#
# @param acmecmd
#   The binary path to acme.sh.
#
# @param acmelog
#   The log file.
#
# @param base_dir
#   The configuration base directory for acme.sh.
#
# @param ca_whitelist
#   Specifies the CAs that may be used on `$acme_host`. The module will register
#   any account specified in `$accounts` with all specified CAs. This ensure that
#   these accounts are ready for use.
#
# @param certificates
#   Array of full qualified domain names you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example ['foo.example.com fuzz.example.com', 'blub.example.com']
#
# @param cfg_dir
#   The directory for acme.sh configs.
#
# @param crt_dir
#   The directory for acme.sh certificates.
#
# @param csr_dir
#   The directory for acme.sh CSRs.
#
# @param date_expression
#   The command used to calculate renewal dates for existing certificates.
#
# @param default_account
#   The default account that should be used to new certificate requests.
#   The account must already be defined in `$accounts`.
#   May be overriden by specifying `$use_account` for the certificate.
#
# @param default_ca
#   The default ACME CA that should be used to new certificate requests.
#   May be overriden by specifying `$ca` for the certificate.
#   Previous versions of acme.sh used to have Let's Encrypt as their default CA,
#   hence this is the default value for this Puppet module.
#
# @param default_profile
#   The default profile that should be used to new certificate requests.
#   The profile must already be defined in `$profile`.
#   May be overriden by specifying `$use_profile` for the certificate.
#
# @param dh_param_size
#   Specifies the DH parameter size, defaults to `2048`.
#
# @param dnssleep
#   The time in seconds acme.sh should wait for all DNS changes to take effect.
#   Settings this to `0` disables the sleep mechanism and lets acme.sh poll DNS
#   status automatically by using DNS over HTTPS.
#
# @param exec_timeout
#   Specifies the time in seconds that any acme.sh operation can take before
#   it is aborted by Puppet. This should usually be set to a higher value
#   than `$dnssleep`.
#
# @param group
#   The group for acme.sh.
#
# @param key_dir
#   The directory for acme.sh keys.
#
# @param log_dir
#   The log directory for acme.sh.
#
# @param manage_packages
#   Whether the module should install necessary packages, mainly git.
#   Set to `false` to disable package management.
#
# @param ocsp_must_staple
#   Whether to request certificates with OCSP Must-Staple extension, defaults to `true`.
#
# @param ocsp_request
#   The script used by acme.sh to get OCSP data.
#
# @param path
#   The content of the PATH env variable when running Exec resources.
#
# @param posthook_cmd
#   Specifies a optional command to run after a certificate has been changed.
#
# @param profiles
#   A hash of profiles that contain information how acme.sh should sign
#   certificates. A profile defines not only the challenge type, but also all
#   required parameters and credentials used by acme.sh to sign the certificate.
#   Should only be defined on $acme_host.
#
# @param proxy
#   Proxy server to use to connect to the ACME CA, for example `proxy.example.com:3128`
#
# @param renew_days
#   Specifies the interval at which certs should be renewed automatically. Defaults to `60`.
#
# @param results_dir
#   The output directory for acme.sh.
#
# @param shell
#   The shell for the acme.sh user account.
#
# @param stat_expression
#   The command used to get the modification time of a file.
#
# @param user
#   The user for acme.sh.
#
class acme (
  Array $accounts,
  String $acme_git_url,
  Boolean $acme_git_force,
  String $acme_host,
  String $acme_revision,
  Stdlib::Absolutepath $acme_install_dir,
  String $acmecmd,
  Stdlib::Absolutepath $acmelog,
  Stdlib::Absolutepath $base_dir,
  Stdlib::Absolutepath $acme_dir,
  Stdlib::Absolutepath $acct_dir,
  Stdlib::Absolutepath $cfg_dir,
  Stdlib::Absolutepath $key_dir,
  Stdlib::Absolutepath $crt_dir,
  Stdlib::Absolutepath $csr_dir,
  Stdlib::Absolutepath $results_dir,
  Stdlib::Absolutepath $log_dir,
  Stdlib::Absolutepath $ocsp_request,
  Array $ca_whitelist,
  Hash $certificates,
  String $date_expression,
  Enum['buypass', 'buypass_test', 'letsencrypt', 'letsencrypt_test', 'sslcom', 'zerossl'] $default_ca,
  Integer $dh_param_size,
  Integer $dnssleep,
  Integer $exec_timeout,
  String $group,
  Boolean $manage_packages,
  Boolean $ocsp_must_staple,
  String $path,
  String $posthook_cmd,
  Integer $renew_days,
  String $shell,
  String $stat_expression,
  String $user,
  # optional parameters
  Optional[String] $default_account = undef,
  Optional[String] $default_profile = undef,
  Optional[String] $proxy = undef,
  Optional[Hash] $profiles = undef
) {
  require acme::setup::common

  # Is this the host to sign CSRs?
  if ($facts['networking']['fqdn'] == $acme_host) {
    class { 'acme::setup::puppetmaster': }

    # Validate configuration of $acme_host.
    if !($profiles) {
      # Cannot continue if no profile has been defined.
      notify { "Module ${module_name}: \$profiles must be defined on \"${acme_host}\"!":
        loglevel => err,
      }
    } elsif !($accounts) {
      # Cannot continue if no account has been defined.
      notify { "Module ${module_name}: \$accounts must be defined on \"${acme_host}\"!":
        loglevel => err,
      }
    } else {
      class { 'acme::request::handler' :
        require => Class[acme::setup::puppetmaster],
      }
    }
    # Collect certificates.
    if ($facts['acme_certs'] and $facts['acme_certs'].length > 0) {
      $facts['acme_certs'].each |$cert, $props| {
        acme::request::crt { $cert:
          domain => $props['cn'],
        }
      }
    } else {
      notify { 'got no acme_certs from facter (may need another puppet run)': }
    }
  }

  # Generate CSRs.
  $certificates.each |$name, $config| {
    # Merge domain params with module params.
    $options = deep_merge({
        acme_host        => $acme_host,
        dh_param_size    => $dh_param_size,
        ocsp_must_staple => $ocsp_must_staple,
    },$config)
    # Create the certificate resource.
    acme::certificate { $name: * => $options }
  }
}
