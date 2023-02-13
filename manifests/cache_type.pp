#Resourcetype for SUNET-Drive-Cache
define sunetdrive::cache_type (
  $bootstrap = undef,
  $location  = undef,
  $override_config = undef,
  $override_compose = undef,
  $override_redis_conf = undef
) {
  $environment = sunetdrive::get_environment()
  $is_multinode = (($override_config != undef) and ($override_compose != undef) and ($override_redis_conf != undef))
  # Now we get the corresponding config from group.yaml
  if $is_multinode {
    $config = $override_config
  } else {
    $config = hiera_hash($environment)
    $nextcloud_ip = $config['app']

    # Pick out the first host to be redis leader
    $leader_address = $nextcloud_ip[0]

  }
  #Static variable defined here
  $leader_name = 'cache1'

  if $is_multinode {
    $redis_config = $override_redis_conf
  } else {
    $redis_host_password = safe_hiera('redis_host_password')
    $replica_of = hiera('replica_of')
    $announce_address = hiera('announce_address')

    file { '/opt/redis/server':
      ensure  => directory,
      recurse => true,
    }
    $redis_config = file { '/opt/redis/server/server.conf':
      ensure  => present,
      content => template('sunetdrive/cache/server.conf.erb'),
      mode    => '0666',
      require => File['/opt/redis/server'],
    }
    file { '/opt/redis/sentinel':
      ensure  => directory,
      recurse => true,
    }
    file { '/opt/redis/sentinel/sentinel.conf':
      ensure  => present,
      content => template('sunetdrive/cache/sentinel.conf.erb'),
      mode    => '0666',
      require => File['/opt/redis/sentinel'],
    }
    sunet::misc::ufw_allow { 'redis_server_port':
      from => '0.0.0.0/0',
      port => 6379,
    }
    sunet::misc::ufw_allow { 'redis_sentinel_port':
      from => '0.0.0.0/0',
      port => 26379,
    }
  }
  if $is_multinode {
    $compose = $override_compose
  } else {
    $compose = sunet::docker_compose { 'drive_redis_docker_compose':
      content          => template('sunetdrive/cache/docker-compose_cache.yml.erb'),
      service_name     => 'redis',
      compose_dir      => '/opt/',
      compose_filename => 'docker-compose.yml',
      description      => 'Redis cache cluster',
    }
  }

}

