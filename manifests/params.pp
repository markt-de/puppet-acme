# == Class: acme::params
#
# Some basic variables we want to use.
#
class acme::params {
  # acme.sh
  $acme_git_url = 'https://github.com/Neilpang/acme.sh.git'
  $acme_install_dir = '/opt/acme.sh'
  $acmecmd = "${acme_install_dir}/acme.sh"
  # NOTE: $base_dir should NOT be changed, it's required by our custom fact.
  $base_dir = '/etc/acme.sh'
  $acme_dir = "${base_dir}/home" # working directory for acme.sh
  $acct_dir = "${base_dir}/accounts"
  $cfg_dir = "${base_dir}/configs"
  $key_dir = "${base_dir}/keys"
  $crt_dir = "${base_dir}/certs"
  $csr_dir = "${base_dir}/csrs" # only used on $acme_host
  $results_dir = "${base_dir}/results" # only used on $acme_host
  $log_dir = '/var/log/acme.sh'
  $acmelog = "${log_dir}/acme.log"

  # Let's Encrypt defaults
  $letsencrypt_ca = 'production'
  $renew_days = 30
  $ocsp_request = "${base_dir}/get_certificate_ocsp.sh"

  # Cert defaults
  $dh_param_size = 2048
  $ocsp_must_staple = true

  # Module defaults
  $manage_packages = true
  $user = 'acme'
  $group = 'acme'
  $root_group = 'root'
  $shell = '/bin/bash'
  $path = '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin'
  $posthook_cmd = '/bin/true'

  if defined('$puppetmaster') {
    $acme_host = $::puppetmaster
  } elsif defined('$servername') {
    $acme_host = $::servername
  }
}
