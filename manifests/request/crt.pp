# Define: acme::request::crt
#
# Take certificates from facter and export a ressource
# with the certificate content.
#
define acme::request::crt(
  $domain = $name
) {
  require ::acme::params

  # acme.sh configuration
  $acme_dir = $::acme::params::acme_dir
  $crt_dir = $::acme::params::crt_dir
  $results_dir = $::acme::params::results_dir
  $ocsp_file = "${results_dir}/${domain}.ocsp"

  # Places where acme.sh stores the resulting certificate.
  $le_crt_file = "${acme_dir}/${domain}/${domain}.cer"
  $le_chain_file = "${acme_dir}/${domain}/ca.cer"
  $le_fullchain_file = "${acme_dir}/${domain}/fullchain.cer"

  # XXX: It seems that we cannot use the files from $acme_dir, because
  #      this does not work with file() for some reasons. It works with
  #      (all) files that are in the catalog, though.
  $result_crt_file = "${results_dir}/${domain}.pem"
  $result_chain_file = "${results_dir}/${domain}.ca"

  $crt = file($result_crt_file)
  notify { "cert for ${domain} from ${result_crt_file} contents: ${crt}": loglevel => debug }

  # special handling for ocsp stuff (binary data)
  $ocsp = base64('encode', file_or_empty_string($ocsp_file))

  $chain = file_or_empty_string($result_chain_file)
  notify { "chain for ${domain} from ${le_chain_file} contents: ${chain}": loglevel => debug }

  if ($crt =~ /BEGIN CERTIFICATE/) {
    @@acme::deploy::crt { $domain:
      crt_content       => $crt,
      crt_chain_content => $chain,
      ocsp_content      => $ocsp,
      tag               => $::fqdn,
    }
  }
}
