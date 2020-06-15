require 'facter'

crt_domains = Dir['/etc/acme.sh/results/*.pem'].map { |a| File.basename(a, '.pem') }

crt_domains.each do |crt_domain|
  sanitized_name = crt_domain.gsub(%r{[*.-]}, { '.' => '_', '-' => '_', '*' => '___acme___' }) # rubocop:disable Style/BracesAroundHashParameters
  Facter.add('acme_crt_' + sanitized_name) do
    setcode do
      crt = File.read("/etc/acme.sh/results/#{crt_domain}.pem")
      crt.strip
    end
  end
end

crt_domains.each do |crt_domain|
  sanitized_name = crt_domain.gsub(%r{[*.-]}, { '.' => '_', '-' => '_', '*' => '___acme___' }) # rubocop:disable Style/BracesAroundHashParameters
  Facter.add('acme_ca_' + sanitized_name) do
    setcode do
      ca = File.read("/etc/acme.sh/results/#{crt_domain}.ca")
      ca.strip
    end
  end
end
