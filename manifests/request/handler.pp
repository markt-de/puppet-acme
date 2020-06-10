# @summary Gather all data and use acme.sh to create accounts and sign certificates.
#
# @api private
class acme::request::handler (
  Array $accounts = $acme::accounts,
  Hash $profiles = $acme::profiles,
  Enum['production','staging'] $letsencrypt_ca = $acme::letsencrypt_ca,
  # acme.sh
  String $user = $acme::user,
  String $group = $acme::group,
  String $acme_git_url = $acme::acme_git_url,
  String $acmecmd = $acme::acmecmd,
  String $acmelog = $acme::acmelog,
  String $acme_install_dir = $acme::acme_install_dir,
  String $base_dir = $acme::base_dir,
  String $acme_dir = $acme::acme_dir,
  String $acct_dir = $acme::acct_dir,
  String $cfg_dir = $acme::cfg_dir,
  String $path = $acme::path,
  String $ocsp_request = $acme::ocsp_request,
  Optional[String] $letsencrypt_proxy = $acme::letsencrypt_proxy,
) {
  File {
    owner => 'root',
    group => 0,
  }

  # Setup and register Let's Encrypt accounts.
  $accounts.each |$account_email| {
    $account_dir = "${acct_dir}/${account_email}"

    # Create a directory for each account.
    file { $account_dir:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }

    # Register accounts for both Let's Encrypt environments.
    # (Because we just don't know for which env it will be used later.)
    $le_envs = ['staging', 'production']
    $le_envs.each |$le_env| {

      # Handle switching CAs with different account keys.
      $account_key_file = "${account_dir}/private_${le_env}.key"
      $account_conf_file = "${account_dir}/account_${le_env}.conf"

      # Create account config file for acme.sh.
      file { $account_conf_file:
        owner   => $user,
        group   => $group,
        mode    => '0640',
        content => epp("${module_name}/account.conf.epp", {
          account_email    => $account_email,
          account_key_file => $account_key_file,
          acme_dir         => $acme_dir,
          acmelog          => $acmelog,
          }),
        require => File[$account_dir],
      }

      # Some status files so we avoid useless runs of acme.sh.
      $account_created_file = "${account_dir}/${le_env}.created"
      $account_registered_file = "${account_dir}/${le_env}.registered"

      # We need to tell acme.sh when to use LE staging servers.
      if ( $le_env == 'staging' ) {
        $staging_or_not = '--staging'
      } else {
        $staging_or_not = ''
      }

      $le_create_command = join([
        $acmecmd,
        $staging_or_not,
        '--create-account-key',
        '--accountkeylength 4096',
        '--log-level 2',
        "--log ${acmelog}",
        "--home ${$acme_dir}",
        "--accountconf ${account_conf_file}",
        '>/dev/null',
        '&&',
        "touch ${account_created_file}",
      ], ' ')

      # Run acme.sh to create the account key.
      exec { "create-account-${le_env}-${account_email}" :
        user    => $user,
        cwd     => $base_dir,
        group   => $group,
        path    => $path,
        command => $le_create_command,
        creates => $account_created_file,
        require => [
          User[$user],
          Group[$group],
          File[$account_conf_file],
        ],
      }

      $le_register_command = join([
        $acmecmd,
        $staging_or_not,
        '--registeraccount',
        '--log-level 2',
        "--log ${acmelog}",
        "--home ${$acme_dir}",
        "--accountconf ${account_conf_file}",
        '>/dev/null',
        '&&',
        "touch ${account_registered_file}",
      ], ' ')

      # Run acme.sh to register the account.
      exec { "register-account-${le_env}-${account_email}" :
        user    => $user,
        cwd     => $base_dir,
        group   => $group,
        path    => $path,
        command => $le_register_command,
        creates => $account_registered_file,
        require => [
          User[$user],
          Group[$group],
          File[$account_conf_file],
        ],
      }

    }

  }

  # Store config for profiles in filesystem, if we support them.
  # (Otherwise the user needs to manually create the required files.)
  $profiles.each |$profile_name, $profile_config| {
    # XXX: Test if $profile_config is not empty and of type Hash
    if ($profile_config != undef) and (type($profile_config) =~ Type[Hash]) {
      $challengetype = $profile_config['challengetype']
      $hook = $profile_config['hook']
    } else {
      fail("Module ${module_name}: profile \"${profile_name}\" config must be of type Hash")
    }

    # Basic validation for ALL profiles.
    if !$challengetype or !$hook {
      fail("Module ${module_name}: profile \"${profile_name}\" is incomplete,",
        "missing either \"challengetype\" or \"hook\"")
    }

    # DNS-01: nsupdate hook
    if ($challengetype == 'dns-01') and ($hook == 'nsupdate') {
      $nsupdate_id = $profile_config['options']['nsupdate_id']
      $nsupdate_key = $profile_config['options']['nsupdate_key']
      $nsupdate_type = $profile_config['options']['nsupdate_type']

      # Make sure all required values are available.
      if ($nsupdate_id and $nsupdate_key and $nsupdate_type) {
        # Create config file for hook script.
        $hook_dir = "${cfg_dir}/profile_${profile_name}"
        $hook_conf_file = "${hook_dir}/hook.cnf"

        file { $hook_dir:
          ensure => directory,
          owner  => $user,
          group  => $group,
          mode   => '0600',
        }

        file { $hook_conf_file:
          owner   => $user,
          group   => $group,
          mode    => '0600',
          content => epp("${module_name}/hooks/${hook}.epp", {
            nsupdate_id   => $nsupdate_id,
            nsupdate_key  => $nsupdate_key,
            nsupdate_type => $nsupdate_type,
            }),
          require => File[$hook_dir],
        }
      }
    }
  }

  # needed for the openssl ocsp -header flag
  $old_openssl = versioncmp($::openssl_version, '1.1.0') < 0

  file { $ocsp_request:
    ensure  => file,
    owner   => 'root',
    group   => $group,
    mode    => '0755',
    content => epp("${module_name}/get_certificate_ocsp.sh.epp", {
      old_openssl => $old_openssl,
      path        => $acme::path,
      proxy       => $letsencrypt_proxy,
      }),
  }

  # Get all certificate signing requests that were tagged to be processed on
  # this host. Usually you want them all to run on the Puppetserver.
  Acme::Request<<| tag == $::fqdn |>>
}
