require 'facter'

Facter.add(:acme_csrs) do
  setcode do
    csrs = {}

    Dir['/etc/acme.sh/certs/*/cert.csr']
      .map { |a| File.basename(File.dirname(a)) }
      .each do |csr_name|
      csrs[csr_name] = File.read("/etc/acme.sh/certs/#{csr_name}/cert.csr")
    end

    csrs
  end
end
