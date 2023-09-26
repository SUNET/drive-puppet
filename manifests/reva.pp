#Class for SUNET-Drive-Lookup-Server
class sunetdrive::reva (
  String $domain = 'drive.test.sunet.se',
  String $customer = 'sunet',
  String $reva_domain  = "${customer}-reva.${domain}",
  String $reva_version = 'v1.26.0',
) {

  $environment = sunetdrive::get_environment()
  $shared_secret = safe_hiera('shared_secret')
  $iopsecret = safe_hiera('iopsecret')

  # Firewall settings
  #Create users
  user { 'www-data': ensure => present, system => true }

  file { '/opt/reva/revad.toml':
    ensure  => present,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/reva/revad.toml.erb'),
    mode    => '0644',
  }
  file { '/opt/reva/data':
    ensure => directory,
    owner  => 'www-data',
  }
  file { '/opt/reva/metrics.json':
    ensure  => present,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/reva/metrics.json.erb'),
    mode    => '0644',
  }

  sunet::docker_compose { 'drive_reva_docker_compose':
    content          => template('sunetdrive/reva/docker-compose.yml.erb'),
    service_name     => 'reva',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'Sciencemesh reva server',
  }
  $ports = [443,19000]
  $ports.each | $port|{
    sunet::misc::ufw_allow { "reva_${port}":
      from => '0.0.0.0/0',
      port => $port,
    }
  }

}
