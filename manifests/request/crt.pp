# @summary Fetch the certificate from facter and export it via PuppetDB.
#
# @param domain
#   The certificate commonname / domainname.
#
# @api private
define acme::request::crt (
  String $domain = $name
) {
  # acme.sh configuration
  $acme_dir = $acme::acme_dir
  $crt_dir = $acme::crt_dir
  $results_dir = $acme::results_dir
  $ocsp_file = "${results_dir}/${domain}.ocsp"

  # Places where acme.sh stores the resulting certificate.
  $le_crt_file = "${acme_dir}/${domain}/${domain}.cer"
  $le_chain_file = "${acme_dir}/${domain}/ca.cer"
  $le_fullchain_file = "${acme_dir}/${domain}/fullchain.cer"

  # Avoid special characters (required for wildcard certs)
  $domain_rep = regsubst($domain, /[*.-]/, {'.' => '_', '-' => '_', '*' => $acme::wildcard_marker}, 'G')
  $domain_tag = regsubst($domain, /[*]/, $acme::wildcard_marker, 'G')

  $crt = pick_default($facts["acme_crt_${domain_rep}"], '')

  # special handling for ocsp stuff (binary data)
  $ocsp = base64('encode', file_or_empty_string($ocsp_file))

  $chain = pick_default($facts["acme_ca_${domain_rep}"], '')

  if ($crt =~ /BEGIN CERTIFICATE/) {
    @@acme::deploy::crt { $domain:
      crt_content       => "${crt}\n",
      crt_chain_content => $chain,
      ocsp_content      => $ocsp,
      # Use the certificate name to tag this resource. This ensures that
      # the certificate is only installed on the host where it is configured.
      tag               => "crt_${domain_tag}",
    }
  } else {
    notify { "got no cert from facter for domain ${domain} (may need another puppet run)": }
  }
}
