# @summary Fetch the certificate from facter and export it via PuppetDB.
#
# @param domain
#   The certificate commonname / domainname.
#
# @api private
define acme::request::crt (
  String $domain
) {
  # acme.sh configuration
  $acme_dir = $acme::acme_dir
  $crt_dir = $acme::crt_dir
  $results_dir = $acme::results_dir
  $ocsp_file = "${results_dir}/${name}.ocsp"

  if ($domain == $name) {
    $cert_home = $acme_dir
  } else {
    $cert_home = "${acme_dir}/${name}_"
  }

  # Places where acme.sh stores the resulting certificate.
  $le_crt_file = "${cert_home}/${domain}/${domain}.cer"
  $le_chain_file = "${cert_home}/${domain}/ca.cer"
  $le_fullchain_file = "${cert_home}/${domain}/fullchain.cer"

  $crt = pick_default($facts.dig('acme_certs', $name, 'crt'), '')

  # special handling for ocsp stuff (binary data)
  $ocsp = base64('encode', file_or_empty_string($ocsp_file))

  $chain = pick_default($facts.dig('acme_certs', $name, 'ca'), '')

  if ($crt =~ /BEGIN CERTIFICATE/) {
    @@acme::deploy::crt { $name:
      crt_content       => "${crt}\n",
      crt_chain_content => $chain,
      ocsp_content      => $ocsp,
    }
  } else {
    notify { "got no cert from facter for ${name} (may need another puppet run)": }
  }
}
