require 'facter'
crt_domains = Dir['/etc/acme.sh/results/*.pem'].map { |a| File.basename(a, '.pem') }

Facter.add(:acme_crts) do
  setcode do
    crt_domains.join(',') if crt_domains
  end
end
