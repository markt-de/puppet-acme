# == Class: acme::setup::puppetmaster
#
# setup all necessary directories and groups
#
class acme::setup::puppetmaster (
  $acme_git_url,
  $manage_packages  = $::acme::manage_packages,
  $acme_install_dir = $::acme::acme_install_dir,
  $csr_dir          = $::acme::csr_dir,
  $log_dir          = $::acme::log_dir,
  $results_dir      = $::acme::results_dir,
  $user             = $::acme::user,
  $group            = $::acme::group,
) {
  File { $acme_install_dir:
    ensure => directory,
    mode   => '0755',
  }

  File { $csr_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  File { $log_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  File { $results_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  if ($manage_packages) {
    ensure_packages('git')
    $vcsrepo_require = [File[$acme_install_dir],Package['git']]
  } else {
    $vcsrepo_require = File[$acme_install_dir]
  }

  # Checkout aka "install" acme.sh.
  Vcsrepo { $acme_install_dir:
    ensure   => latest,
    revision => master,
    provider => git,
    source   => $acme_git_url,
    user     => root,
    require  => $vcsrepo_require,
  }

}
