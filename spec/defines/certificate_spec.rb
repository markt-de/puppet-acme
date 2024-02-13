require 'spec_helper'

describe 'acme::certificate', type: :define do
  context 'on supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let(:pre_condition) { 'include acme' }

        test_cert = 'test.example.com'
        wildcard_cert = '*.example.com'
        altname_test1 = 'foo.example.com'
        altname_test2 = 'bar.example.com'

        context 'with example configuration' do
          let(:params) do
            {
              use_profile: 'route53_example',
              use_account: 'ssl@example.com',
              ca: 'letsencrypt_test',
            }
          end

          let(:title) { test_cert }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_acme__certificate(test_cert) }
          it { is_expected.to contain_exec("posthook_#{test_cert}") }
          it { is_expected.to contain_acme__deploy(test_cert) }

          it { is_expected.to contain_acme__csr(test_cert) }
          it { is_expected.to contain_acme__csr('test.example.com') }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}").with_ensure('directory') }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*commonName\s+= #{test_cert}.*}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").without_content(%r{subjectAltName}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").without_content(%r{alt_names}) }
          it { is_expected.to contain_exec("create-dh-/etc/acme.sh/configs/#{test_cert}/params.dh") }
          it { is_expected.to contain_file("/etc/acme.sh/keys/#{test_cert}").with_ensure('directory') }
          it { is_expected.to contain_ssl_pkey("/etc/acme.sh/keys/#{test_cert}/private.key") }
          it { is_expected.to contain_x509_request("/etc/acme.sh/certs/#{test_cert}/cert.csr") }

          # should only exist on $acme_host
          it { is_expected.not_to contain_file('/etc/acme.sh/csrs') }
        end

        context 'when creating a SAN certificate' do
          let(:params) do
            {
              use_profile: 'route53_example',
              use_account: 'ssl@example.com',
              ca: 'letsencrypt_test',
            }
          end

          let(:title) { "#{test_cert} #{altname_test1} #{altname_test2}" }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*commonName\s+= #{test_cert}.*}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{subjectAltName}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*\[ alt_names \].*}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*DNS.1 = #{test_cert}.*}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*DNS.2 = #{altname_test1}.*}) }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{test_cert}/ssl.cnf").with_content(%r{.*DNS.3 = #{altname_test2}.*}) }
        end

        context 'when creating a wildcard certificate' do
          let(:params) do
            {
              use_profile: 'route53_example',
              use_account: 'ssl@example.com',
              ca: 'letsencrypt_test',
            }
          end

          let(:title) { wildcard_cert }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{wildcard_cert}").with_ensure('directory') }
          it { is_expected.to contain_file("/etc/acme.sh/configs/#{wildcard_cert}/ssl.cnf").with_content(%r{.*commonName\s+= #{Regexp.escape(wildcard_cert)}.*}) }
        end
      end
    end
  end
end
