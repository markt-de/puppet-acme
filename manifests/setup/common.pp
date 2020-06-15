# @summary Setup all necessary directories, users and groups.
# @api private
class acme::setup::common {
  User { $acme::user:
    gid        => $acme::group,
    home       => $acme::base_dir,
    shell      => $acme::shell,
    managehome => false,
    password   => '!!',
    system     => true,
  }

  group { $acme::group:
    ensure => present,
    system => true,
  }

  File {
    ensure  => directory,
    owner   => $acme::user,
    group   => $acme::group,
    mode    => '0755',
    require => Group[$acme::group],
  }

  File { $acme::base_dir :
    ensure => directory,
    mode   => '0755',
    owner  => $acme::user,
    group  => $acme::group,
  }

  File { $acme::key_dir :
    ensure => directory,
    mode   => '0750',
    owner  => $acme::user,
    group  => $acme::group,
  }

  File { $acme::crt_dir :
    ensure => directory,
    mode   => '0755',
    owner  => $acme::user,
    group  => $acme::group,
  }

  File { $acme::acme_dir :
    ensure => directory,
    mode   => '0750',
    owner  => $acme::user,
    group  => $acme::group,
  }

  File { $acme::acct_dir :
    ensure => directory,
    mode   => '0700',
    owner  => $acme::user,
    group  => $acme::group,
  }

  File { $acme::cfg_dir :
    ensure => directory,
    mode   => '0700',
    owner  => $acme::user,
    group  => $acme::group,
  }
}
