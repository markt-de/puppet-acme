require 'facter'

crt_domains = Dir['/etc/acme.sh/results/*.pem'].map { |a| a.gsub(%r{\.pem$}, '').gsub(%r{^.*/}, '') }

crt_domains.each do |crt_domain|
  Facter.add('acme_crt_' + crt_domain.gsub('.', '_').gsub('-', '_')) do
    setcode do
      crt = File.read("/etc/acme.sh/results/#{crt_domain}.pem")
      crt.strip
    end
  end
end

crt_domains.each do |crt_domain|
  Facter.add('acme_ca_' + crt_domain.gsub('.', '_').gsub('-', '_')) do
    setcode do
      ca = File.read("/etc/acme.sh/results/#{crt_domain}.ca")
      ca.strip
    end
  end
end

