# @summary Collects signed certificates and installs them.
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

  # Install the signed certificate on this host.
  # Using the certificate name as a tag ensures that only those certificates
  # are installed that are configured on this host.
  Acme::Deploy::Crt <<| tag == $domain |>>
}
