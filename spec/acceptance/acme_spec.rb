require 'spec_helper_acceptance'

describe 'acme' do
  context 'with default parameters' do
    let(:pp) do
      %(class { 'acme':
        accounts => ['certmaster@example.com', 'ssl@example.com'],
        profiles => {
          nsupdate_example => {
            challengetype => 'dns-01',
            hook          => 'nsupdate',
            env           => {
              'NSUPDATE_SERVER' => 'bind.example.com'
            },
            options       => {
              dnssleep      => 15,
              nsupdate_id   => 'example-key',
              nsupdate_type => 'hmac-md5',
              nsupdate_key  => 'abcdefg1234567890',
            }
          },
          route53_example  => {
            challengetype => 'dns-01',
            hook          => 'aws',
            env           => {
              'AWS_ACCESS_KEY_ID'     => 'foobar',
              'AWS_SECRET_ACCESS_KEY' => 'secret',
            },
            options       => {
              dnssleep => 15,
            }
          }
        }
      })
    end

    it { apply_manifest(pp, catch_failures: true) }
  end
end
