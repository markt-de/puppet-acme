require 'facter'

csr_domains = Dir['/etc/acme.sh/certs/*/cert.csr'].map { |a| File.basename(File.dirname(a)) }

Facter.add(:acme_csrs) do
  setcode do
    csr_domains.join(',') if csr_domains
  end
end

csr_domains.each do |csr_domain|
  Facter.add('acme_csr_' + csr_domain.gsub(/[.-]/, '_')) do
    setcode do
      csr = File.read("/etc/acme.sh/certs/#{csr_domain}/cert.csr")
      csr
    end
  end
end
