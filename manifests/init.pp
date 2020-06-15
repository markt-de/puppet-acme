# @summary Install and configure acme.sh to manage SSL certificates
#
# @param certificates
#   Array of full qualified domain names you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example ['foo.example.com fuzz.example.com', 'blub.example.com']
#
# @param profiles
#   A hash of profiles that contain information how acme.sh should sign
#   certificates. A profile defines not only the challenge type, but also all
#   required parameters and credentials used by acme.sh to sign the certificate.
#   Should only be defined on $acme_host.
#
# @param accounts
#   An array of e-mail addresses that acme.sh may use during the Let's Encrypt
#   account registration. Should only be defined on $acme_host.
#
# @param acme_host
#   The host you want to run acme.sh on.
#   For now it needs to be a puppetmaster, as it needs direct access
#   to the certificates using functions in Puppet.
#
# @param acme_git_url
#   URL to the acme.sh GIT repository. Defaults to the official GitHub project.
#   Feel free to use a local mirror or fork.
#
# @param acme_revision
#   The GIT revision of the acme.sh repository. Defaults to `master` which should
#   contain a stable version of acme.sh.
#
# @param letsencrypt_ca
#   The Let's Encrypt CA you want to use. For testing and debugging you may want
#   to set it to `staging`, otherwise `production` is used and the usual
#   rate limits apply.
#
# @param renew_days
#   Specifies the interval at which certs should be renewed automatically. Defaults to `60`.
#
# @param letsencrypt_proxy
#   Proxyserver to use to connect to the Let's Encrypt CA, for example `proxy.example.com:3128`
#
# @param posthook_cmd
#   Specified a optional command to run after a certificate has been changed.
#
# @param dh_param_size
#   Specifies the DH parameter size, defaults to `2048`.
#
# @param ocsp_must_staple
#   Whether to request certificates with OCSP Must-Staple extension, defaults to `true`.
#
# @param manage_packages
#   Whether the module should install necessary packages, mainly git.
#   Set to `false` to disable package management.
#
# @param wildcard_marker
#   A string that is used to replace `*` in wildcard certificates. This is required
#   because Puppet does not allow special chars in variable names.
#   DO NOT CHANGE THIS VALUE! It is hardcoded in all custom facts too.
#
class acme (
  Array $accounts,
  String $acme_git_url,
  String $acme_host,
  String $acme_revision,
  Stdlib::Compat::Absolute_path $acme_install_dir,
  String $acmecmd,
  Stdlib::Compat::Absolute_path $acmelog,
  Stdlib::Compat::Absolute_path $base_dir,
  Stdlib::Compat::Absolute_path $acme_dir,
  Stdlib::Compat::Absolute_path $acct_dir,
  Stdlib::Compat::Absolute_path $cfg_dir,
  Stdlib::Compat::Absolute_path $key_dir,
  Stdlib::Compat::Absolute_path $crt_dir,
  Stdlib::Compat::Absolute_path $csr_dir,
  Stdlib::Compat::Absolute_path $results_dir,
  Stdlib::Compat::Absolute_path $log_dir,
  Stdlib::Compat::Absolute_path $ocsp_request,
  Hash $certificates,
  String $date_expression,
  Integer $dh_param_size,
  Integer $dnssleep,
  String $group,
  Enum['production','staging'] $letsencrypt_ca,
  Boolean $manage_packages,
  Boolean $ocsp_must_staple,
  String $path,
  String $posthook_cmd,
  Integer $renew_days,
  String $shell,
  String $stat_expression,
  String $user,
  String $wildcard_marker,
  # optional parameters
  Optional[String] $letsencrypt_proxy = undef,
  Optional[Hash] $profiles = undef
) {
  require ::acme::setup::common

  # Is this the host to sign CSRs?
  if ($::fqdn == $acme_host) {
    class { '::acme::setup::puppetmaster' :
      acme_git_url    => $acme_git_url,
      acme_revision   => $acme_revision,
      manage_packages => $manage_packages,
    }

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
      class { '::acme::request::handler' :
        acme_git_url      => $acme_git_url,
        letsencrypt_ca    => $letsencrypt_ca,
        accounts          => $accounts,
        profiles          => $profiles,
        letsencrypt_proxy => $letsencrypt_proxy,
        require           => Class[::acme::setup::puppetmaster],
      }
    }
    # Collect certificates.
    if (defined('::acme_crts') and $::acme_crts and $::acme_crts != '') {
      $acme_crts_array = split($::acme_crts, ',')
      ::acme::request::crt { $acme_crts_array: }
    }
  }

  # Generate CSRs.
  $certificates.each |$domain, $config| {
    # Merge domain params with module params.
    $options = deep_merge({
      domain           => $domain,
      acme_host        => $acme_host,
      dh_param_size    => $dh_param_size,
      ocsp_must_staple => $ocsp_must_staple,
    },$config)
    # Create the certificate resource.
    ::acme::certificate { $domain: * => $options }
  }
}
