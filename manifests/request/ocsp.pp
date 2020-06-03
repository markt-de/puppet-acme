# Define: acme::request::ocsp
#
# Retrieve ocsp stapling information
#
define acme::request::ocsp(
  $domain = $name
) {
  require ::acme::params

  $user = $::acme::params::user
  $group = $::acme::params::group
  $base_dir = $::acme::params::base_dir
  $acme_dir = $::acme::params::acme_dir
  $acct_dir = $::acme::params::acct_dir
  $log_dir = $::acme::params::log_dir
  $results_dir = $::acme::params::results_dir
  $path = $::acme::params::path
  $date_expression = $::acme::params::date_expression

  # acme.sh configuration
  $acmecmd = $::acme::params::acmecmd
  $acmelog = $::acme::params::acmelog
  $crt_file = "${results_dir}/${domain}.pem"
  $chain_file = "${results_dir}/${domain}.ca"
  $ocsp_file = "${results_dir}/${domain}.ocsp"

  $ocsp_request = $::acme::params::ocsp_request

  $ocsp_command = join([
    $ocsp_request,
    $crt_file,
    $chain_file,
    $ocsp_file,
  ], ' ')

  $ocsp_onlyif = join([
    'test',
    '-f',
    "'${crt_file}'",
  ], ' ')

  $ocsp_unless = join([
    'test',
    '-f',
    "'${ocsp_file}'",
    '&&',
    'test',
    '$(',
    "stat -c '%Y' ${ocsp_file}",
    ')',
    '-gt',
    '$(',
    $date_expression,
    ')',
  ], ' ')

  exec { "update_ocsp_file_for_${domain}":
    path    => $path,
    command => $ocsp_command,
    unless  => $ocsp_unless,
    onlyif  => $ocsp_onlyif,
    user    => $user,
    group   => $group,
    require => File[$ocsp_request],
  }

  file { $ocsp_file:
    mode    => '0644',
    replace => false,
    require => Exec["update_ocsp_file_for_${domain}"],
  }
}
