# @summary Collects signed certificates for this host from PuppetDB.
#
# @param acme_host
#   Host the certificates were signed on
#
# @api private
define acme::deploy (
  String $acme_host,
) {
  $domains = split($name, ' ')
  $domain = $domains[0]

  # Avoid special characters (required for wildcard certs)
  $domain_tag = regsubst($domain, /[*]/, $acme::wildcard_marker, 'G')

  # Install the signed certificate on this host.
  # Using the certificate name as a tag ensures that only those certificates
  # are installed that are configured on this host.
  Acme::Deploy::Crt <<| tag == "crt_${domain_tag}" |>>
}
