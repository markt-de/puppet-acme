require 'facter'
crt_domains = Dir['/etc/acme.sh/results/*.pem'].map { |a| a.gsub(%r{\.pem$}, '').gsub(%r{^.*/}, '') }

Facter.add(:acme_crts) do
  setcode do
    crt_domains.join(',') if crt_domains
  end
end
