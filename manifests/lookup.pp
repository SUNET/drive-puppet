#Class for SUNET-Drive-Lookup-Server
class sunetdrive::lookup (
  $bootstrap = undef,
  $location  = undef
) {

  $environment = sunetdrive::get_environment()


  # Firewall settings
  $nextcloud_ip = hiera_array("${location}_app", [])
  $tug_office = hiera_array('tug_office')

  $dbhost = 'proxysql_proxysql_1'
  $gss_jwt_key = safe_hiera('gss_jwt_key')
  $mysql_user_password = safe_hiera('mysql_user_password')
  $lookup_version = hiera("lookup_version_${environment}")

  #Create users
  user { 'www-data': ensure => present, system => true }

  file { '/opt/lookup/config.php':
    ensure  => present,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/lookup/config.php.erb'),
    mode    => '0644',
  }

  sunet::docker_compose { 'drive_lookup_docker_compose':
    content          => template('sunetdrive/lookup/docker-compose_lookup.yml.erb'),
    service_name     => 'lookup',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'Lookup server',
  }

  sunet::misc::ufw_allow { 'https':
    from => '0.0.0.0/0',
    port => 443,
  }
}
