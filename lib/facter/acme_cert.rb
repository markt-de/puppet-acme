require 'facter'

Facter.add(:acme_certs) do
  setcode do
    certs = {}

    Dir['/etc/acme.sh/results/*.pem']
      .map { |a| File.basename(a, '.pem') }
      .each do |cert_name|
      crt = File.read("/etc/acme.sh/results/#{cert_name}.pem")
      ca = File.read("/etc/acme.sh/results/#{cert_name}.ca")

      begin
        cert = OpenSSL::X509::Certificate.new(crt)
      rescue OpenSSL::X509::CertificateError => e
        raise Puppet::ParseError, "Not a valid x509 certificate: #{e}"
      end
      cn = cert.subject.to_a.find { |name, _, _| name == 'CN' }[1]

      certs[cert_name] = {
        crt: crt.strip,
        ca: ca.strip,
        cn: cn,
      }
    end

    certs
  end
end
