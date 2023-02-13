# This is NI for SUNET Drive
class sunetdrive::ni() {
  if $environment == 'prod' {
    $domain = 'ni.drive.sunet.se'
  }  else {
    $domain = 'ni.drive.test.sunet.se'
  }

  file { '/opt/sri/postgresql':
    ensure => directory,
  }
  -> file { '/opt/sri/postgresql/data':
    ensure => directory,
  }
  -> file { '/opt/sri/neo4j':
    ensure => directory,
  }
  -> file { '/opt/sri/neo4j/data':
    ensure => directory,
  }
  -> file { '/opt/sri/ni':
    ensure => directory,
  }
  -> file { '/opt/sri/ni/etc':
    ensure => directory,
  }
  -> file { '/opt/sri/ni/log':
    ensure => directory,
  }
  -> file { '/opt/sri/backup':
    ensure => directory,
  }
  -> file { '/opt/sri/backup/neo4j':
    ensure => directory,
  }
  -> file { '/opt/sri/staticfiles':
    ensure => directory,
  }
  -> file { '/opt/sri/srifrontfiles':
    ensure => directory,
  }
  -> file { '/opt/sri/nginx':
    ensure => directory,
  }
  -> file { '/opt/sri/nginx/etc':
    ensure => directory,
  }
  -> file { '/opt/sri/nginx/log':
    ensure => directory,
  }
  -> file { '/opt/sri/nginx/etc/ni.http':
    ensure  => present,
    content => '';
  }
  -> file { '/opt/sri/nginx/etc/dhparams.pem':
    ensure  => present,
    content => '';
  }
  -> file { '/opt/sri/ni/etc/dotenv':
    ensure  => present,
    content => '';
  }
  -> file { '/opt/sri/postgresql/init/init-noclook-db.sh':
    ensure  => present,
    content => '';
  }
  sunet::docker_compose { 'drive_ni_compose':
    content          => template('sunetdrive/ni/docker-compose.yml.erb'),
    service_name     => 'sri',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'NI',
  }
}
