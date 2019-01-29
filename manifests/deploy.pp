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

  Acme::Deploy::Crt <<| tag == $domain and tag == $acme_host |>>
}
