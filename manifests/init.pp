# == Class: acme
#
# Include this class if you would like to create certificates or on your
# puppetmaster to have your CSRs signed.
#
# === Parameters
#
# [*certificates*]
#   Array of full qualified domain names (== commonname)
#   you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example ['foo.example.com fuzz.example.com', 'blub.example.com']
#
# [*acme_git_url*]
#   URL used to checkout the dehydrated using git.
#   Defaults to the upstream github url.
#
# [*profiles*]
#   A hash of profiles that contain information how acme.sh should sign
#   certificates. Should only be defined on $acme_host.
#
# [*accounts*]
#   An array of e-mail addresses that acme.sh may use during the Let's Encrypt
#   account registration.
#
# [*acme_host*]
#   The host you want to run acme.sh on.
#   For now it needs to be a puppetmaster, as it needs direct access
#   to the certificates using functions in puppet.
#
# [*posthook_cmd*]
#   command to run after a certificate has been changed
#
# [*letsencrypt_ca*]
#   The letsencrypt CA you want to use. For testing and debugging you may want
#   to set it to 'staging', otherwise 'production' is used and the usual
#   rate limits apply.
#
# [*letsencrypt_proxy*]
#   Proxyserver to use to connect to the letsencrypt CA
#   for example '127.0.0.1:3128'
#
# [*dh_param_size*]
#   dh parameter size, defaults to 2048
#
# [*ocsp_must_staple*]
#   Request certificats with OCSP Must-Staple extension, defaults to true
#
# [*manage_packages*]
#   install necessary packages, mainly git
#
# === Examples
#
#   class { 'acme' :
#     domains       => [ 'foo.example.com', 'fuzz.example.com' ],
#     challengetype => 'dns-01',
#     hook          => 'nsupdate'
#   }
#
class acme (
  $accounts          = [],
  $certificates      = {},
  $acme_git_url      = $::acme::params::acme_git_url,
  $profiles          = undef,
  $acme_host         = $::acme::params::acme_host,
  $posthook_cmd      = $::acme::params::posthook_cmd,
  $letsencrypt_ca    = $::acme::params::letsencrypt_ca,
  $letsencrypt_proxy = undef,
  $dh_param_size     = $::acme::params::dh_param_size,
  $ocsp_must_staple  = $::acme::params::ocsp_must_staple,
  $manage_packages   = $::acme::params::manage_packages,
) inherits ::acme::params {

  require ::acme::setup::common

  # Is this the host to sign CSRs?
  if ($::fqdn == $acme_host) {
    class { '::acme::setup::puppetmaster' :
      acme_git_url    => $acme_git_url,
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
    if ($::acme_crts and $::acme_crts != '') {
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
