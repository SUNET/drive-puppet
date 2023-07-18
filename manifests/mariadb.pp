# A Class using the db resurce
class sunetdrive::mariadb (
  $bootstrap = undef,
  $location  = undef,
  $tag_mariadb = undef,
  $override_config = undef,
  $override_compose = undef,
) {

  $quorum_id = $facts['networking']['fqdn']
  $quorum_password = safe_hiera('quorum_password')
  $db = sunetdrive::db_type { 'base_db':
    bootstrap            => $bootstrap,
    tag_mariadb          => $tag_mariadb,
    location             => $location,
  }
  file { '/etc/quorum.conf':
    ensure  => file,
    mode    => '0644',
    content => template('sunetdrive/mariadb/quorum.conf.erb'),
  }
  file { '/usr/local/bin/quorum':
    ensure  => file,
    mode    => '0700',
    content => template('sunetdrive/mariadb/quorum.erb.sh'),
  }
}
