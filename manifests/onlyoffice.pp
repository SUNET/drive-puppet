#Class for SUNET-Drive-OnlyOffice
class sunetdrive::onlyoffice () {
  $environment = sunetdrive::get_environment()
  $extra_hosts = hiera_hash($environment)['extra_hosts']
  $docker_tag  = hiera_hash($environment)['collabora_tag']
  $customers = hiera('fullnodes')
  $multinode_customers = keys(hiera_hash('multinode_mapping'))
  if $environment == 'prod' {
    $domain = 'drive.sunet.se'
  }  else {
    $domain = 'drive.test.sunet.se'
  }
  sunet::collabora::docs { 'sunet-onlyoffice':
    dns         => [ '89.32.32.32' ],
    extra_hosts => $extra_hosts,
    extra_volumes => ['/opt/collabora/coolwsd.xml:/etc/coolwsd/coolwsd.xml'],
    docker_tag  => $docker_tag,
  }
  file {'/opt/collabora/coolwsd.xml':
    ensure => present,
    content => template('sunetdrive/document/coolwsd.xml.erb'),
  }
}
