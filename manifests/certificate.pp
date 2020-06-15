# @summary Request a certificate.
#
# @param domain
#   Full qualified domain names you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example 'foo.example.com fuzz.example.com'
#
# @param use_account
#   The Let's Encrypt account that should be used (or registered).
#   This account must exist in `$accounts` on your `$acme_host`.
#
# @param use_profile
#   Specify the profile that should be used to sign the certificate.
#   This profile must exist in `$profiles` on your `$acme_host`.
#
# @param acme_host
#   The host you want to run acme.sh on. Usually your Puppetserver.
#   Defaults to `$acme::acme_host`.
#
# @param letsencrypt_ca
#   The Let's Encrypt CA you want to use. Used to overwrite the default Let's
#   Encrypt CA that is configured on `$acme_host`.
#
# @param dh_param_size
#   dh parameter size, defaults to $::acme::dh_param_size
#
# @param ocsp_must_staple
#   request certificate with OCSP Must-Staple exctension, defaults to $::acme::ocsp_must_staple
#
define acme::certificate (
  String $use_account,
  String $use_profile,
  String $domain = $name,
  String $acme_host = $acme::acme_host,
  Integer $dh_param_size = $acme::dh_param_size,
  Boolean $ocsp_must_staple = $acme::ocsp_must_staple,
  String $posthook_cmd = $acme::posthook_cmd,
  Integer $renew_days = $acme::renew_days,
  Optional[Enum['production','staging']] $letsencrypt_ca = undef,
) {
  require ::acme::setup::common

  $domain_dc = downcase($domain)
  $path = $acme::path

  # Post-Hook CMD
  exec { "posthook_${name}":
    command     => $posthook_cmd,
    path        => $path,
    refreshonly => true,
  }

  # Collect and install signed certificates.
  ::acme::deploy { $domain_dc:
    acme_host => $acme_host,
  } ~> Exec["posthook_${name}"]

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
