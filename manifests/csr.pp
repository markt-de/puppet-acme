# = Define: acme::csr
#
# PRIVATE CLASS. Create a CSR and ask to sign it.
#
# == Parameters:
#
# [*acme_host*]
#   Host the certificates will be signed on
#
# [*use_account*]
#   The Let's Encrypt account that should be used (or registered).
#
# [*use_profile*]
#   The profile that should be used to sign the certificate.
#
# [*letsencrypt_ca*]
#   The Let's Encrypt CA you want to use. Used to overwrite the default Let's
#   Encrypt CA that is configured on $acme_host.
#
define acme::csr(
  $acme_host,
  $use_account,
  $use_profile,
  $renew_days       = $::acme::params::renew_days,
  $letsencrypt_ca   = undef,
  $domain_list      = $name,
  $country          = undef,
  $state            = undef,
  $locality         = undef,
  $organization     = undef,
  $unit             = undef,
  $email            = undef,
  $password         = undef,
  $ensure           = 'present',
  $force            = true,
  $dh_param_size    = 2048,
  $ocsp_must_staple = true,
) {
  require ::acme::params

  validate_string($acme_host)
  validate_string($use_account)
  validate_string($use_profile)
  validate_string($country)
  validate_string($organization)
  validate_string($domain_list)
  validate_string($ensure)
  validate_string($state)
  validate_string($locality)
  validate_string($unit)
  validate_string($email)
  validate_integer($dh_param_size)

  $user = $::acme::params::user
  $group = $::acme::params::group

  $base_dir = $::acme::params::base_dir
  $cfg_dir = $::acme::params::cfg_dir
  $key_dir = $::acme::params::key_dir
  $crt_dir = $::acme::params::crt_dir
  $path = $::acme::params::path
  $date_expression = $::acme::params::date_expression

  # Handle certificates with multiple domain names (SAN).
  $domains = split($domain_list, ' ')
  $domain = $domains[0]
  $has_san = size(domains) > 1
  if ($has_san) {
    $altnames = delete_at($domains, 0)
    $subject_alt_names = $domains
  } else {
    $altnames = []
    $subject_alt_names = []
  }

  file { "${cfg_dir}/${domain}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0750',
    require => Group[$group],
  }

  file { "${key_dir}/${domain}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0750',
    require => Group[$group],
  }

  ensure_resource('file', "${crt_dir}/${domain}", {
    ensure  => directory,
    mode    => '0755',
    owner   => $user,
    group   => $group,
    require => [
      User[$user],
      Group[$group]
    ],
  })

  $cnf_file = "${cfg_dir}/${domain}/ssl.cnf"
  $dh_file  = "${cfg_dir}/${domain}/params.dh"
  $key_file = "${key_dir}/${domain}/private.key"
  $csr_file = "${crt_dir}/${domain}/cert.csr"
  $crt_file = "${crt_dir}/${domain}/cert.pem"

  $create_dh_unless = join([
    'test',
    '-f',
    "'${dh_file}'",
    '&&',
    'test',
    '$(',
    "stat -c '%Y' ${dh_file}",
    ')',
    '-gt',
    '$(',
    $date_expression,
    ')',
  ], ' ')

  exec { "create-dh-${dh_file}" :
    require => [
      File[$crt_dir]
    ],
    user    => 'root',
    group   => $group,
    path    => $path,
    command => "openssl dhparam -check -out ${dh_file} ${dh_param_size}",
    unless  => $create_dh_unless,
    timeout => 30*60,
  }

  file { $dh_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => $group,
    mode    => '0644',
    require => Exec["create-dh-${dh_file}"],
  }

  file { $cnf_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => $group,
    mode    => '0644',
    content => template('acme/cert.cnf.erb'),
  }

  ssl_pkey { $key_file:
    ensure   => $ensure,
    password => $password,
    require  => File[$key_dir],
  }

  x509_request { $csr_file:
    ensure      => $ensure,
    template    => $cnf_file,
    private_key => $key_file,
    password    => $password,
    force       => $force,
    require     => File[$cnf_file],
  }

  exec { "refresh-csr-${csr_file}":
    path        => $path,
    command     => "rm -f ${csr_file}",
    refreshonly => true,
    user        => 'root',
    group       => $group,
    before      => X509_request[$csr_file],
    subscribe   => File[$cnf_file],
  }

  file { $key_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    require => Ssl_pkey[$key_file],
  }

  file { $csr_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => $group,
    mode    => '0644',
    require => X509_request[$csr_file],
  }

  $domain_rep = regsubst($domain, /[.-]/, '_', 'G')
  $csr_content = pick_default(getvar("::acme_csr_${domain_rep}"), '')
  if ($csr_content =~ /CERTIFICATE REQUEST/) {
    @@acme::request { $domain:
      csr              => $csr_content,
      tag              => $acme_host,
      altnames         => $altnames,
      use_account      => $use_account,
      use_profile      => $use_profile,
      renew_days       => $renew_days,
      letsencrypt_ca   => $letsencrypt_ca,
      ocsp_must_staple => $ocsp_must_staple,
    }
  } else {
    notify { "no CSR from facter for domain ${domain} (normal on first run)" : }
  }
}
