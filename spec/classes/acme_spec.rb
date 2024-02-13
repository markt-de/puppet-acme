require 'spec_helper'

describe 'acme' do
  context 'on supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with example configuration' do
          let(:facts) do
            super().merge(
              openssl_version: '1.0.2k-fips',
            )
          end
          let(:params) do
            {
              accounts: ['certmaster@example.com', 'ssl@example.com'],
              profiles: {
                nsupdate_example: {
                  challengetype: 'dns-01',
                  hook: 'nsupdate',
                  env: {
                    NSUPDATE_SERVER: 'bind.example.com',
                  },
                  options: {
                    dnssleep: 15,
                    nsupdate_id: 'example-key',
                    nsupdate_type: 'hmac-md5',
                    nsupdate_key: 'abcdefg1234567890',
                  },
                },
                route53_example: {
                  challengetype: 'dns-01',
                  hook: 'aws',
                  env: {
                    AWS_ACCESS_KEY_ID: 'foobar',
                    AWS_SECRET_ACCESS_KEY: 'secret',
                  },
                  options: {
                    dnssleep: 15,
                  },
                },
              },
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('acme') }

          it { is_expected.not_to contain_class('acme::setup::puppetmaster') }
          it { is_expected.not_to contain_class('acme::request::handler') }
          it { is_expected.not_to contain_class('acme::request::crt') }

          it { is_expected.to contain_file('/etc/acme.sh').with_ensure('directory') }
          it { is_expected.to contain_file('/etc/acme.sh/certs').with_ensure('directory') }
          it { is_expected.to contain_file('/etc/acme.sh/configs').with_ensure('directory') }
          it { is_expected.to contain_file('/etc/acme.sh/keys').with_ensure('directory') }

          # should only exist on $acme_host
          it { is_expected.not_to contain_file('/etc/acme.sh/csrs').with_ensure('directory') }
          it { is_expected.not_to contain_file('/etc/acme.sh/results').with_ensure('directory') }
          it { is_expected.not_to contain_vcsrepo('/opt/acme.sh').with_revision('master') }
          it { is_expected.not_to contain_package('git').with_ensure('installed') }
        end

        context 'on Puppet Server' do
          test_host = 'puppetserver.example.com'
          le_account = 'certmaster@example.com'
          le_profile = 'nsupdate_example'

          let(:facts) do
            super().merge(
              networking: {
                fqdn: test_host,
              },
              servername: test_host,
              openssl_version: '1.0.2k-fips',
            )
          end
          let(:server_facts) do
            super().merge(
              servername: test_host,
            )
          end
          let(:params) do
            {
              accounts: [le_account],
              profiles: {
                nsupdate_example: {
                  challengetype: 'dns-01',
                  hook: 'nsupdate',
                  env: {
                    NSUPDATE_SERVER: 'bind.example.com',
                  },
                  options: {
                    dnssleep: 15,
                    nsupdate_id: 'example-key',
                    nsupdate_type: 'hmac-md5',
                    nsupdate_key: 'abcdefg1234567890',
                  },
                },
              },
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('acme') }

          it { is_expected.to contain_class('acme::setup::puppetmaster') }
          it { is_expected.to contain_class('acme::request::handler') }

          it { is_expected.to contain_file('/etc/acme.sh/accounts').with_ensure('directory') }
          it { is_expected.to contain_file("/etc/acme.sh/accounts/#{le_account}").with_ensure('directory') }
          it { is_expected.to contain_file("/etc/acme.sh/accounts/#{le_account}/account_staging.conf") }
          it { is_expected.to contain_file("/etc/acme.sh/accounts/#{le_account}/account_production.conf") }
          it { is_expected.to contain_augeas("update account conf: /etc/acme.sh/accounts/#{le_account}/account_staging.conf") }
          it { is_expected.to contain_augeas("update account conf: /etc/acme.sh/accounts/#{le_account}/account_production.conf") }
          it { is_expected.to contain_exec("create-account-letsencrypt_test-#{le_account}") }
          it { is_expected.to contain_exec("create-account-letsencrypt-#{le_account}") }
          it { is_expected.to contain_exec("register-account-letsencrypt_test-#{le_account}") }
          it { is_expected.to contain_exec("register-account-letsencrypt-#{le_account}") }

          it { is_expected.to contain_file("/etc/acme.sh/configs/profile_#{le_profile}").with_ensure('directory') }
          it { is_expected.to contain_file("/etc/acme.sh/configs/profile_#{le_profile}/hook.cnf").with_content(%r{.*secret.*abcdefg1234567890.*}) }

          it { is_expected.to contain_file('/etc/acme.sh/csrs').with_ensure('directory') }
          it { is_expected.to contain_file('/etc/acme.sh/results').with_ensure('directory') }
          it { is_expected.to contain_file('/opt/acme.sh').with_ensure('directory') }
          it { is_expected.to contain_vcsrepo('/opt/acme.sh').with_revision('master') }
          it { is_expected.to contain_package('git').with_ensure('installed') }
        end

        context 'on Puppet Server with custom ca_whitelist' do
          test_host = 'puppetserver.example.com'
          le_account = 'certmaster@example.com'
          le_ca = 'zerossl'

          let(:facts) do
            super().merge(
              networking: {
                fqdn: test_host,
              },
              servername: test_host,
              openssl_version: '1.0.2k-fips',
            )
          end
          let(:server_facts) do
            super().merge(
              servername: test_host,
            )
          end
          let(:params) do
            {
              accounts: [le_account],
              profiles: {
                nsupdate_example: {
                  challengetype: 'dns-01',
                  hook: 'nsupdate',
                  env: {
                    NSUPDATE_SERVER: 'bind.example.com',
                  },
                  options: {
                    dnssleep: 15,
                    nsupdate_id: 'example-key',
                    nsupdate_type: 'hmac-md5',
                    nsupdate_key: 'abcdefg1234567890',
                  },
                },
              },
              ca_whitelist: [le_ca],
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('acme') }

          it { is_expected.to contain_file("/etc/acme.sh/accounts/#{le_account}/account_#{le_ca}.conf") }
          it { is_expected.not_to contain_file("/etc/acme.sh/accounts/#{le_account}/account_staging.conf") }
          it { is_expected.not_to contain_file("/etc/acme.sh/accounts/#{le_account}/account_production.conf") }

          it { is_expected.to contain_augeas("update account conf: /etc/acme.sh/accounts/#{le_account}/account_#{le_ca}.conf") }
          it { is_expected.not_to contain_augeas("update account conf: /etc/acme.sh/accounts/#{le_account}/account_staging.conf") }
          it { is_expected.not_to contain_augeas("update account conf: /etc/acme.sh/accounts/#{le_account}/account_production.conf") }

          it { is_expected.to contain_exec("create-account-#{le_ca}-#{le_account}") }
          it { is_expected.not_to contain_exec("create-account-letsencrypt-#{le_account}") }

          it { is_expected.to contain_exec("register-account-#{le_ca}-#{le_account}") }
          it { is_expected.not_to contain_exec("register-account-letsencrypt-#{le_account}") }
        end
      end
    end
  end
end
