# = Define: acme::request
#
# Request to sign a CSR.
#
# == Parameters:
#
# [*csr*]
#   The full csr as string.
#
# [*domain*]
#   Certificate commonname / domainname.
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
define acme::request (
  $csr,
  $use_account,
  $use_profile,
  $renew_days       = $::acme::params::renew_days,
  $letsencrypt_ca   = undef,
  $domain           = $name,
  $altnames         = undef,
  $ocsp_must_staple = true,
) {
  require ::acme::params

  $user = $::acme::params::user
  $group = $::acme::params::group
  $base_dir = $::acme::params::base_dir
  $acme_dir = $::acme::params::acme_dir
  $cfg_dir = $::acme::params::cfg_dir
  $crt_dir = $::acme::params::crt_dir
  $csr_dir = $::acme::params::csr_dir
  $acct_dir = $::acme::params::acct_dir
  $log_dir = $::acme::params::log_dir
  $results_dir = $::acme::params::results_dir
  $acme_install_dir = $::acme::params::acme_install_dir
  $path = $::acme::params::path

  # acme.sh configuration
  $acmecmd = $::acme::params::acmecmd
  $acmelog = $::acme::params::acmelog
  $csr_file = "${csr_dir}/${domain}/cert.csr"
  $crt_file = "${crt_dir}/${domain}/cert.pem"
  $chain_file = "${crt_dir}/${domain}/chain.pem"
  $fullchain_file = "${crt_dir}/${domain}/fullchain.pem"

  # Check if the account is actually defined.
  $accounts = $::acme::accounts
  if ! ($use_account in $accounts) {
    fail("Module ${module_name}: account \"${use_account}\" for cert ${domain}",
      "is not defined on \$acme_host")
  }
  $account_email = $use_account

  # Check if the profile is actually defined.
  $profiles = $::acme::profiles
  #if ($profiles == Hash) and $profiles[$use_profile] {
  if $profiles[$use_profile] {
    $profile = $profiles[$use_profile]
  } else {
    fail("Module ${module_name}: unable to find profile \"${use_profile}\" for",
      "cert ${domain}")
  }
  $challengetype = $profile['challengetype']
  $hook = $profile['hook']

  # Validate Let's Encrypt CA.
  if ( $letsencrypt_ca ) {
    validate_re($letsencrypt_ca, '^(staging|production)$')
    $_letsencrypt_ca = $letsencrypt_ca
  } else {
    # Fallback to default CA.
    $_letsencrypt_ca = $::acme::letsencrypt_ca
  }
  notify { "using CA \"${_letsencrypt_ca}\" for domain ${domain}": loglevel => debug }

  # We need to tell acme.sh when to use LE staging servers.
  if ( $_letsencrypt_ca == 'staging' ) {
    $staging_or_not = '--staging'
  } else {
    $staging_or_not = ''
  }

  $account_conf_file = "${acct_dir}/${account_email}/account_${_letsencrypt_ca}.conf"

  # Add ocsp if must-staple is requested
  if ($ocsp_must_staple) {
    $_ocsp = '--ocsp'
  } else {
    $_ocsp = ''
  }

  # Collect options for "supported" hooks.
  if ($challengetype == 'dns-01') {
    # DNS-01 / nsupdate hook
    if ($hook == 'nsupdate') {
      $nsupdate_id = $profile['options']['nsupdate_id']
      $nsupdate_key = $profile['options']['nsupdate_key']
      $nsupdate_type = $profile['options']['nsupdate_type']
      if ($nsupdate_id and $nsupdate_key and $nsupdate_type) {
        $hook_dir = "${cfg_dir}/profile_${use_profile}"
        $hook_conf_file = "${hook_dir}/hook.cnf"
        $_hook_params_pre = { 'NSUPDATE_KEY' => $hook_conf_file }
      }
    }
  }
  # Merge those pre-defined hook options with user-defined hook options.
  # NOTE: We intentionally use Hashes so that *values* can be overriden.
  $_hook_params = deep_merge($_hook_params_pre, $profile['env'])
  # Convert the Hash to an Array, required for Exec's "environment" attribute.
  $hook_params = $_hook_params.map |$key,$value| { "${key}=${value}" }
  notify { "hook params for domain ${domain}: ${hook_params}": loglevel => debug }

  # Collect additional options for acme.sh.
  if ($profile['options']['dnssleep']) {
    $_dnssleep = "--dnssleep  ${profile['options']['dnssleep']}"
  } else {
    $_dnssleep = "--dnssleep ${::acme::params::dnssleep}"
  }

  if ($profile['options']['challenge_alias']) {
    $_challenge_alias = "--challenge-alias ${profile['options']['challenge_alias']}"
    $acme_options = join([$_dnssleep, $_challenge_alias], ' ')
  } else {
    $acme_options = $_dnssleep
  }

  File {
    owner   => $user,
    group   => $group,
    require => [
      User[$user],
      Group[$group]
    ],
  }

  # NOTE: We need to use a different directory on $acme_host to avoid
  #       duplicate declaration errors (in cases where the CSR was also
  #       generated on $acme_host).
  file { "${csr_dir}/${domain}":
    ensure => directory,
    mode   => '0755',
  }

  file { $csr_file :
    ensure  => file,
    content => $csr,
    mode    => '0640',
  }

  # Create directory to place the crt_file for each domain
  $crt_dir_domain = "${crt_dir}/${domain}"
  file { $crt_dir_domain :
    ensure => directory,
    mode   => '0755',
  }

  # Places where acme.sh stores the resulting certificate.
  $le_crt_file = "${acme_dir}/${domain}/${domain}.cer"
  $le_chain_file = "${acme_dir}/${domain}/ca.cer"
  $le_fullchain_file = "${acme_dir}/${domain}/fullchain.cer"

  # We create a copy of the resulting certificates in a separate folder
  # to make it easier to collect them with facter.
  # XXX: Also required by acme::request::crt.
  $result_crt_file = "${results_dir}/${domain}.pem"
  $result_chain_file = "${results_dir}/${domain}.ca"

  # Convert altNames to be compatible with acme.sh.
  $_altnames = $altnames.map |$item| { "--domain ${item}" }

  # Convert days to seconds for openssl...
  $renew_seconds = $renew_days*86400
  notify { "acme renew set to ${renew_days} days (or ${renew_seconds} seconds) for domain ${domain}": loglevel => debug }

  $le_check_command = join([
    "/usr/bin/test -f ${le_crt_file}",
    '&&',
    "/usr/bin/openssl x509 -checkend ${renew_seconds} -noout -in ${le_crt_file}",
    '&&',
    '/usr/bin/test',
    '$(',
    "/usr/bin/stat -c '%Y' ${le_crt_file}",
    ')',
    '-gt',
    '$(',
    "/usr/bin/stat -c '%Y' ${csr_file}",
    ')',
  ], ' ')

  # Check if challenge type is supported.
  if $challengetype == 'http-01' {
    # XXX add support for other http-01 hooks
    $acme_challenge = '--webroot /etc/acme.sh/challenges'
  } elsif $challengetype == 'dns-01' {
    # Hook is passed unchecked to acme.sh to automatically support new hooks
    # when they are added to acme.sh.
    $acme_validation = "--dns dns_${hook}"
  } else {
    fail("${::hostname}: Module ${module_name}: unsupported challenge",
      "type \"${challengetype}\"")
  }

  # acme.sh command to sign a new csr.
  $le_command_signcsr = join([
    $acmecmd,
    $staging_or_not,
    '--signcsr',
    "--domain ${domain}",
    $_altnames,
    $acme_validation,
    "--log ${acmelog}",
    '--log-level 2',
    "--home ${$acme_dir}",
    '--keylength 4096',
    "--accountconf ${account_conf_file}",
    $_ocsp,
    "--csr ${csr_file}",
    "--certpath ${crt_file}",
    "--capath ${chain_file}",
    "--fullchainpath ${fullchain_file}",
    $acme_options,
    '>/dev/null',
  ], ' ')

  # acme.sh command to renew an existing certificate.
  $le_command_renew = join([
    $acmecmd,
    $staging_or_not,
    '--issue',
    "--domain ${domain}",
    $_altnames,
    $acme_validation,
    "--days ${renew_days}",
    "--log ${acmelog}",
    '--log-level 2',
    "--home ${$acme_dir}",
    '--keylength 4096',
    "--accountconf ${account_conf_file}",
    $_ocsp,
    "--csr ${csr_file}",
    "--certpath ${crt_file}",
    "--capath ${chain_file}",
    "--fullchainpath ${fullchain_file}",
    $acme_options,
    '>/dev/null',
  ], ' ')

  # Run acme.sh to issue the certificate
  exec { "issue-certificate-${domain}" :
    user        => $user,
    cwd         => $base_dir,
    group       => $group,
    unless      => $le_check_command,
    path        => $path,
    environment => $hook_params,
    command     => $le_command_signcsr,
    # Run this exec only if no old cert can be found.
    onlyif      => "/usr/bin/test ! -f ${le_crt_file}",
    require     => [
      User[$user],
      Group[$group],
      File[$csr_file],
      File[$crt_dir_domain],
      File[$account_conf_file],
      Vcsrepo[$acme_install_dir],
    ],
    notify      => [
      File[$le_crt_file],
      File[$result_crt_file],
      File[$result_chain_file],
    ],
  }

  # Run acme.sh to issue/renew the certificate
  exec { "renew-certificate-${domain}" :
    user        => $user,
    cwd         => $base_dir,
    group       => $group,
    unless      => $le_check_command,
    path        => $path,
    environment => $hook_params,
    command     => $le_command_renew,
    returns     => [ 0, 2, ],
    # Run this exec only if an old cert can be found.
    onlyif      => "/usr/bin/test -f ${le_crt_file}",
    require     => [
      User[$user],
      Group[$group],
      File[$csr_file],
      File[$crt_dir_domain],
      File[$account_conf_file],
      Vcsrepo[$acme_install_dir],
    ],
    notify      => [
      File[$le_crt_file],
      File[$result_crt_file],
      File[$result_chain_file],
    ],
  }

  file { $le_crt_file:
    mode    => '0644',
    replace => false,
  }

  file { $result_crt_file:
    source => $le_crt_file,
    mode   => '0644',
  }

  file { $result_chain_file:
    source => $le_chain_file,
    mode   => '0644',
  }

  ::acme::request::ocsp { $domain:
    require => File[$result_crt_file],
  }

}
