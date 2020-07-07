# @summary Setup acme.sh and all necessary directories and packages.
# @api private
class acme::setup::puppetmaster {
  File { $acme::acme_install_dir:
    ensure => directory,
    mode   => '0755',
  }

  File { $acme::csr_dir:
    ensure => directory,
    owner  => $acme::user,
    group  => $acme::group,
    mode   => '0755',
  }

  File { $acme::log_dir:
    ensure => directory,
    owner  => $acme::user,
    group  => $acme::group,
    mode   => '0755',
  }

  File { $acme::results_dir:
    ensure => directory,
    owner  => $acme::user,
    group  => $acme::group,
    mode   => '0755',
  }

  if ($acme::manage_packages) {
    if !defined(Package['git']) {
      ensure_packages('git')
    }
    $vcsrepo_require = [File[$acme::acme_install_dir],Package['git']]
  } else {
    $vcsrepo_require = File[$acme::acme_install_dir]
  }

  # Checkout aka "install" acme.sh.
  Vcsrepo { $acme::acme_install_dir:
    ensure   => latest,
    revision => $acme::acme_revision,
    provider => git,
    source   => $acme::acme_git_url,
    user     => root,
    force    => $acme::acme_git_force,
    require  => $vcsrepo_require,
  }
}
