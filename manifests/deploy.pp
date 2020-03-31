# = Define: acme::deploy
#
# Collects signed certificates and installs them.
#
# == Parameters:
#
# [*acme_host*]
#   Host the certificates were signed on
#
define acme::deploy(
    $acme_host,
) {
  $domains = split($name, ' ')
  $domain = $domains[0]

  # Install the signed certificate on this host.
  # Using the certificate name as a tag ensures that only those certificates
  # are installed that are configured on this host.
  Acme::Deploy::Crt <<| tag == $domain |>>
}
