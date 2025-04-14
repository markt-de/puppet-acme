# @summary Request a certificate.
#
# @param acme_host
#   The host you want to run acme.sh on. Usually your Puppet Server.
#   Defaults to `$acme::acme_host`.
#
# @param ca
#   The ACME CA that should be used. Used to overwrite the default
#   CA that is configured on `$acme_host`.
#
# @param challenge_alias
#   Specifies a optional challenge alias, which will be used for DNS alias mode.
#
# @param dh_param_size
#   Specifies the DH parameter size, defaults to $acme::dh_param_size.
#
# @param key_size
#   The key size for RSA keys, defaults to $acme::key_size.
#
# @param domain
#   Full qualified domain names you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example 'foo.example.com fuzz.example.com', or an array of names.
#
#   If no domain is specified, the resource name will be parsed as a
#   list of domains, and the first domain will be used as certificate name.
#
# @param domain_alias
#   Specifies a optional domain alias, which will be used for DNS alias mode.
#
# @param ocsp_must_staple
#   request certificate with OCSP Must-Staple exctension, defaults to $acme::ocsp_must_staple
#
# @param posthook_cmd
#   Specifies a optional command to run after a certificate has been changed.
#
# @param purge_key_on_mismatch
#   Whether or not the private key should be removed if a $key_size mismatch is detected.
#   Note that this will cause a cert/key mismatch for existing certificates, until a new certificate was issued using the new key.
#
# @param renew_days
#   Specifies the interval at which certs should be renewed automatically. Defaults to `60`.
#
# @param use_account
#   The ACME account that should be used (or registered).
#   This account must exist in `$accounts` on your `$acme_host`.
#
# @param use_profile
#   Specify the profile that should be used to sign the certificate.
#   This profile must exist in `$profiles` on your `$acme_host`.
#
define acme::certificate (
  String $use_account = $acme::default_account,
  String $use_profile = $acme::default_profile,
  Variant[String, Array[String], Undef] $domain = undef,
  String $acme_host = $acme::acme_host,
  Integer $dh_param_size = $acme::dh_param_size,
  Integer $key_size = $acme::key_size,
  Boolean $ocsp_must_staple = $acme::ocsp_must_staple,
  String $posthook_cmd = $acme::posthook_cmd,
  Boolean $purge_key_on_mismatch = $acme::purge_key_on_mismatch,
  Integer $renew_days = $acme::renew_days,
  Optional[Variant[
      Enum['buypass', 'buypass_test', 'letsencrypt', 'letsencrypt_test', 'sslcom', 'zerossl'],
      Pattern[/^[a-z0-9_-]+$/]
  ]] $ca = $acme::default_ca,
  Optional[String] $challenge_alias = undef,
  Optional[String] $domain_alias = undef,
) {
  require acme::setup::common

  $path = $acme::path

  if $domain =~ Undef {
    # compatibility mode, parse name as list of domains, and use first as certificate resource name
    $domains = split(downcase($name), ' ')
    $cert_name = $domains[0]
  } elsif $domain =~ String {
    $domains = split($domain, ' ')
    $cert_name = $name
  } else {
    $domains = $domain
    $cert_name = $name
  }

  # Post-Hook CMD
  exec { "posthook_${cert_name}":
    command     => $posthook_cmd,
    path        => $path,
    refreshonly => true,
  }

  # Collect and install signed certificates.
  acme::deploy { $cert_name:
    acme_host => $acme_host,
  } ~> Exec["posthook_${cert_name}"]

  # Generate CSRs.
  ::acme::csr { $cert_name:
    domains               => $domains,
    use_account           => $use_account,
    use_profile           => $use_profile,
    acme_host             => $acme_host,
    dh_param_size         => $dh_param_size,
    key_size              => $key_size,
    ocsp_must_staple      => $ocsp_must_staple,
    purge_key_on_mismatch => $purge_key_on_mismatch,
    renew_days            => $renew_days,
    ca                    => $ca,
    challenge_alias       => $challenge_alias,
    domain_alias          => $domain_alias,
  }
}
