# IDP proxy used in SUNET Drive
class sunetdrive::satosa($dehydrated_name=undef,$image='docker.sunet.se/satosa',$tag=undef) {

  $proxy_conf = hiera('satosa_proxy_conf')
  $default_conf = {
    'STATE_ENCRYPTION_KEY'       => hiera('satosa_state_encryption_key'),
    'USER_ID_HASH_SALT'          => hiera('satosa_user_id_hash_salt'),
    'CUSTOM_PLUGIN_MODULE_PATHS' => ['plugins'],
    'COOKIE_STATE_NAME'          => 'SATOSA_STATE'
  }
  $merged_conf = merge($proxy_conf,$default_conf)

  ensure_resource('file','/etc', { ensure => directory } )
  ensure_resource('file','/etc/satosa', { ensure => directory } )
  ensure_resource('file','/etc/satosa/', { ensure => directory } )
  ensure_resource('file','/etc/satosa/run', { ensure => directory } )
  ensure_resource('file','/etc/satosa/plugins', { ensure => directory } )
  ensure_resource('file','/etc/satosa/metadata', { ensure => directory } )

  ['backend','frontend','metadata'].each |$id| {
    if hiera("satosa_${id}_key",undef) != undef {
        sunet::snippets::secret_file { "/etc/satosa/${id}.key": hiera_key => "satosa_${id}_key" }
        # assume cert is in cosmos repo
    } else {
        # make key pair
        sunet::snippets::keygen {"satosa_${id}":
          key_file  => "/etc/satosa/${id}.key",
          cert_file => "/etc/satosa/${id}.crt"
        }
    }
  }
  sunet::docker_run {'satosa':
    image    => $image,
    imagetag => $tag,
    dns      => ['89.32.32.32'],
    volumes  => ['/etc/satosa:/etc/satosa','/etc/dehydrated:/etc/dehydrated'],
    ports    => ['443:8000'],
    env      => ['METADATA_DIR=/etc/satosa/metadata', 'WORKER_TIMEOUT=120']
  }
  file {'/etc/satosa/proxy_conf.yaml':
    content => inline_template("<%= @merged_conf.to_yaml %>\n"),
    notify  => Sunet::Docker_run['satosa']
  }
  $plugins = hiera('satosa_config')
  sort(keys($plugins)).each |$n| {
    $conf = hiera($n)
    $fn = $plugins[$n]
    file { $fn:
      content => inline_template("<%= @conf.to_yaml %>\n"),
      notify  => Sunet::Docker_run['satosa']
    }
  }
  sunet::misc::ufw_allow { 'satosa-allow-https':
    from => 'any',
    port => '443'
  }
  $dehydrated_status = $dehydrated_name ? {
    undef   => 'absent',
    default => 'present'
  }
  sunet::docker_run {'alwayshttps':
    ensure => $dehydrated_status,
    image  => 'docker.sunet.se/always-https',
    ports  => ['80:80'],
    env    => ['ACME_URL=http://acme-c.sunet.se']
  }
  sunet::misc::ufw_allow { 'satosa-allow-http':
    ensure => $dehydrated_status,
    from   => 'any',
    port   => '80'
  }
  if ($dehydrated_name) {
    file { '/etc/satosa/https.key': ensure => link, target => "/etc/dehydrated/certs/${dehydrated_name}.key" }
    file { '/etc/satosa/https.crt': ensure => link, target => "/etc/dehydrated/certs/${dehydrated_name}/fullchain.pem" }
  } else {
    sunet::snippets::keygen {'satosa_https':
      key_file  => '/etc/satosa/https.key',
      cert_file => '/etc/satosa/https.crt'
    }
  }
  file { '/opt/satosa':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  -> file { '/opt/satosa/restart.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('sunetdrive/satosa/restart.erb.sh'),
  }
  -> cron { 'restart_satosa':
    command => '/opt/satosa/restart.sh',
    user    => 'root',
    minute  => '15',
    hour    => '*/8',
  }
}
