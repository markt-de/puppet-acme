# == Define: acme::certificate
#
# Request a certificate for a single domain or a SAN certificate.
#
# === Parameters
#
# [*domain*]
#   Full qualified domain names (== commonname)
#   you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example 'foo.example.com fuzz.example.com'
#
# [*use_account*]
#   The Let's Encrypt account that should be used (or registered).
#
# [*use_profile*]
#   Specify the profile that should be used to sign the certificate.
#   A profile defines not only the challenge type, but also all required
#   parameters and credentials to sign the certificate.
#
# [*acme_host*]
#   The host you want to run acme.sh on.
#   Defaults to $::acme::acme_host
#
# [*letsencrypt_ca*]
#   The Let's Encrypt CA you want to use. Used to overwrite the default Let's
#   Encrypt CA that is configured on $acme_host.
#
# [*dh_param_size*]
#   dh parameter size, defaults to $::acme::dh_param_size
#
# [*ocsp_must_staple*]
#   request certificate with OCSP Must-Staple exctension, defaults to $::acme::ocsp_must_staple
#
# === Examples
#   ::acme::certificate( 'foo.example.com' :
#   }
#
define acme::certificate (
  $use_account,
  $use_profile,
  $domain           = $name,
  $renew_days       = $::acme::params::renew_days,
  $letsencrypt_ca   = undef,
  $acme_host        = $::acme::acme_host,
  $dh_param_size    = $::acme::dh_param_size,
  $ocsp_must_staple = $::acme::ocsp_must_staple
){
  validate_string($domain)
  $domain_dc = downcase($domain)
  validate_integer($dh_param_size)
  validate_string($acme_host)
  validate_string($domain_dc)
  validate_string($use_account)
  validate_string($use_profile)

  require ::acme::params
  require ::acme::setup::common

  # Collect and install signed certificates.
  ::acme::deploy { $domain_dc:
    acme_host => $acme_host,
  }

  # Generate CSRs.
  ::acme::csr { $domain_dc:
    use_account      => $use_account,
    use_profile      => $use_profile,
    acme_host        => $acme_host,
    dh_param_size    => $dh_param_size,
    ocsp_must_staple => $ocsp_must_staple,
    renew_days       => $renew_days,
    letsencrypt_ca   => $letsencrypt_ca,
  }

}
