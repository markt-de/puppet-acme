# @summary Retrieve ocsp stapling information
#
# @param domain
#   The certificate commonname / domainname.
#
# @api private
define acme::request::ocsp (
  String $domain = $name
) {
  $user = $acme::user
  $group = $acme::group
  $base_dir = $acme::base_dir
  $acme_dir = $acme::acme_dir
  $acct_dir = $acme::acct_dir
  $log_dir = $acme::log_dir
  $results_dir = $acme::results_dir
  $path = $acme::path
  $date_expression = $acme::date_expression
  $stat_expression = $acme::stat_expression

  # acme.sh configuration
  $acmecmd = $acme::acmecmd
  $acmelog = $acme::acmelog
  $crt_file = "${results_dir}/${domain}.pem"
  $chain_file = "${results_dir}/${domain}.ca"
  $ocsp_file = "${results_dir}/${domain}.ocsp"

  $ocsp_request = $acme::ocsp_request

  $ocsp_command = join([
    $ocsp_request,
    "\'${crt_file}\'",
    "\'${chain_file}\'",
    "\'${ocsp_file}\'",
  ], ' ')

  $ocsp_onlyif = "test -f \'${crt_file}\'"

  $ocsp_unless = join([
    "test -f \'${ocsp_file}\'",
    '&&',
    'test',
    "\$( ${stat_expression} \'${ocsp_file}\' )",
    '-gt',
    "\$( ${date_expression} )",
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
