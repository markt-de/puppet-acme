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

  $domain_rep = regsubst(regsubst($domain, '\.', '_', 'G'),'-', '_', 'G')

  $crt = pick_default($facts.get("acme_crt_${domain_rep}"), '')
  notify { "cert for ${domain} from ${result_crt_file} contents: ${crt}": loglevel => debug }

  # special handling for ocsp stuff (binary data)
  $ocsp = base64('encode', file_or_empty_string($ocsp_file))

  $chain = pick_default($facts.get("acme_ca_${domain_rep}"), '')
  notify { "chain for ${domain} from ${le_chain_file} contents: ${chain}": loglevel => debug }

  if ($crt =~ /BEGIN CERTIFICATE/) {
    @@acme::deploy::crt { $domain:
      crt_content       => "$crt\n",
      crt_chain_content => $chain,
      ocsp_content      => $ocsp,
      tag               => $::fqdn,
    }
  }
}
