# @summary Setup acme.sh and all necessary directories and packages.
# @api private
class acme::setup::puppetmaster (
  String $acme_git_url,
  String $acme_revision,
  Boolean $manage_packages = $acme::manage_packages,
  String $acme_install_dir = $acme::acme_install_dir,
  String $csr_dir = $acme::csr_dir,
  String $log_dir = $acme::log_dir,
  String $results_dir = $acme::results_dir,
  String $user = $acme::user,
  String $group = $acme::group,
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
    revision => $acme_revision,
    provider => git,
    source   => $acme_git_url,
    user     => root,
    require  => $vcsrepo_require,
  }
}
