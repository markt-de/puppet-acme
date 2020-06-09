# == Class: acme::setup::common
#
# setup all necessary directories and groups
#
class acme::setup::common (
  String $base_dir = $acme::base_dir,
  String $acme_dir = $acme::acme_dir,
  String $crt_dir = $acme::crt_dir,
  String $cfg_dir = $acme::cfg_dir,
  String $key_dir = $acme::key_dir,
  String $acct_dir = $acme::acct_dir,
  String $user = $acme::user,
  String $group = $acme::group,
  String $shell = $acme::shell,
) {
  User { $user:
    gid        => $group,
    home       => $base_dir,
    shell      => $shell,
    managehome => false,
    password   => '!!',
    system     => true,
  }

  group { $group:
    ensure => present,
    system => true,
  }

  File {
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => Group[$group],
  }

  File { $base_dir :
    ensure => directory,
    mode   => '0755',
    owner  => $user,
    group  => $group,
  }

  File { $key_dir :
    ensure => directory,
    mode   => '0750',
    owner  => $user,
    group  => $group,
  }

  File { $crt_dir :
    ensure => directory,
    mode   => '0755',
    owner  => $user,
    group  => $group,
  }

  File { $acme_dir :
    ensure => directory,
    mode   => '0750',
    owner  => $user,
    group  => $group,
  }

  File { $acct_dir :
    ensure => directory,
    mode   => '0700',
    owner  => $user,
    group  => $group,
  }

  File { $cfg_dir :
    ensure => directory,
    mode   => '0700',
    owner  => $user,
    group  => $group,
  }
}
