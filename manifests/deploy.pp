# @summary Collects signed certificates for this host from PuppetDB.
#
# @param acme_host
#   Host the certificates were signed on
#
# @api private
define acme::deploy (
  String $acme_host,
) {
  # Install the signed certificate on this host.
  Acme::Deploy::Crt <<| title == $name |>>
}
