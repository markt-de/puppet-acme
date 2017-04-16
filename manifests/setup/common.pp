# == Class: acme::setup::common
#
# setup all necessary directories and groups
#
class acme::setup::common (
  $base_dir = $::acme::params::base_dir,
  $acme_dir = $::acme::params::acme_dir,
  $crt_dir  = $::acme::params::crt_dir,
  $cfg_dir  = $::acme::params::cfg_dir,
  $key_dir  = $::acme::params::key_dir,
  $acct_dir = $::acme::params::acct_dir,
  $user     = $::acme::params::user,
  $group    = $::acme::params::group,
  $shell    = $::acme::params::shell,
) inherits ::acme::params {

  User { $user:
    gid        => $group,
    home       => $base_dir,
    shell      => $shell,
    managehome => false,
    password   => '!!',
  }

  group { $group:
    ensure => present,
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
