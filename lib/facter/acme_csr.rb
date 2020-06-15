require 'facter'

csr_domains = Dir['/etc/acme.sh/certs/*/cert.csr'].map { |a| File.basename(File.dirname(a)) }

Facter.add(:acme_csrs) do
  setcode do
    csr_domains.join(',') if csr_domains
  end
end

csr_domains.each do |csr_domain|
  sanitized_name = csr_domain.gsub(%r{[*.-]}, { '.' => '_', '-' => '_', '*' => '___acme___' }) # rubocop:disable Style/BracesAroundHashParameters
  Facter.add('acme_csr_' + sanitized_name) do
    setcode do
      csr = File.read("/etc/acme.sh/certs/#{csr_domain}/cert.csr")
      csr
    end
  end
end
