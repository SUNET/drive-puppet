#Resource type for SUNET-Drive-Application
define sunetdrive::app_type (
  $bootstrap = undef,
  $location  = undef,
  $override_config = undef,
  $override_compose = undef
) {
  # Config from group.yaml and customer specific conf
  $environment = sunetdrive::get_environment()
  $customer = sunetdrive::get_customer()
  $nodenumber = sunetdrive::get_node_number()

  # Common settings for multinode and full nodes
  $nextcloud_ip = $config['app']
  $s3_bucket = $config['s3_bucket']
  $s3_host = $config['s3_host']
  $site_name = $config['site_name']
  $trusted_domains = $config['trusted_domains']
  $trusted_proxies = $config['trusted_proxies']

  # These are encrypted values from local.eyaml
  $gss_jwt_key = safe_hiera('gss_jwt_key')
  $smtppassword = safe_hiera('smtp_password')

  $is_multinode = (($override_config != undef) and ($override_compose != undef))
  if $is_multinode {
    # The config used
    $config = $override_config
    # Other settings
    $redis_host = $config['redis_host']
    $admin_password = $config[ 'admin_password' ]
    $dbhost = $config[ 'dbhost' ]
    $dbname = $config[ 'dbname' ]
    $dbuser = $config[ 'dbuser' ]
    $instanceid = $config[ 'instanceid' ]
    $mysql_user_password = $config[ 'mysql_user_password' ]
    $passwordsalt = $config[ 'passwordsalt' ]
    $redis_host_password = $config[ 'redis_host_password' ]
    $s3_key = $config[ 's3_key' ]
    $s3_secret = $config[ 's3_secret' ]
    $secret = $config[ 'secret' ]
    $session_save_handler = 'redis'
    $session_save_path = "tcp://${redis_host}:6379?auth=${redis_host_password}"
  } else {
    # The config used
    $config = hiera_hash($environment)
    $skeletondirectory = $config['skeletondirectory']
    # Other settings
    $redis_seeds = [
        {'host' => "redis1.${site_name}", 'port' => 6379},
        {'host' => "redis2.${site_name}", 'port' => 6379},
        {'host' => "redis3.${site_name}", 'port' => 6379},
        {'host' => "redis1.${site_name}", 'port' => 6380},
        {'host' => "redis2.${site_name}", 'port' => 6380},
        {'host' => "redis3.${site_name}", 'port' => 6380},
        {'host' => "redis1.${site_name}", 'port' => 6381},
        {'host' => "redis2.${site_name}", 'port' => 6381},
        {'host' => "redis3.${site_name}", 'port' => 6381},
      ]
    $admin_password = safe_hiera('admin_password')
    $dbhost = 'proxysql_proxysql_1'
    $dbname = 'nextcloud'
    $dbuser = 'nextcloud'
    $instanceid = safe_hiera('instanceid')
    $mysql_user_password = safe_hiera('mysql_user_password')
    $passwordsalt = safe_hiera('passwordsalt')
    $redis_host_password = safe_hiera('redis_host_password')
    $redis_cluster_password = safe_hiera('redis_cluster_password')
    $s3_key = safe_hiera('s3_key')
    $s3_secret = safe_hiera('s3_secret')
    $secret = safe_hiera('secret')
    $session_save_handler = 'rediscluster'
    $session_save_path = "seed[]=${redis_seeds[0]['host']}:${redis_seeds[0]['port']}&seed[]=${redis_seeds[1]['host']}:${redis_seeds[1]['port']}&seed[]=${redis_seeds[2]['host']}:${redis_seeds[2]['port']}&seed[]=${redis_seeds[3]['host']}:${redis_seeds[3]['port']}&seed[]=${redis_seeds[4]['host']}:${redis_seeds[4]['port']}&seed[]=${redis_seeds[5]['host']}:${redis_seeds[6]['port']}&seed[]=${redis_seeds[7]['host']}:${redis_seeds[7]['port']}&seed[]=${redis_seeds[8]['host']}:${redis_seeds[8]['port']}&timeout=2&read_timeout=2&failover=error&persistent=1&auth=${redis_cluster_password}&stream[verify_peer]=0"
  }
  $twofactor_enforced_groups = hiera_array('twofactor_enforced_groups')
  $twofactor_enforced_excluded_groups = hiera_array('twofactor_enforced_excluded_groups')
  $nextcloud_version = hiera("nextcloud_version_${environment}")
  $nextcloud_version_string = split($nextcloud_version, '[-]')[0]
  #These are global values from common.yaml
  $gs_enabled = hiera('gs_enabled')
  $gs_federation = hiera('gs_federation')
  $gss_master_admin = hiera_array('gss_master_admin')
  $gss_master_url = hiera("gss_master_url_${environment}")
  $lookup_server = hiera("lookup_server_${environment}")
  $mail_domain = hiera("mail_domain_${environment}")
  $mail_smtphost = hiera("mail_smtphost_${environment}")
  $mail_from_address = hiera("mail_from_address_${environment}")
  $s3_usepath = hiera('s3_usepath')
  $smtpuser = hiera("smtp_user_${environment}")
  $tug_office = hiera_array('tug_office')

  # This is a global value from common.yaml but overridden in the gss-servers local.yaml
  $gss_mode = hiera('gss_mode')

  # These are global values from common.yaml but can be overridden in group.yaml
  $drive_email_template_text_left = $config['drive_email_template_text_left']
  $drive_email_template_plain_text_left = $config['drive_email_template_plain_text_left']
  $drive_email_template_url_left = $config['drive_email_template_url_left']
  $lb_servers = hiera_hash($environment)['lb_servers']
  $document_servers = hiera_hash($environment)['document_servers']

  file { '/opt/nextcloud/nce.ini':
    ensure  => file,
    force   => true,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/application/nce.ini.erb'),
    mode    => '0644',
  }
  unless $is_multinode{
    user { 'www-data': ensure => present, system => true }

    file { '/opt/nextcloud/cron.sh':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('sunetdrive/application/cron.erb.sh'),
    }
    cron { 'cron.sh':
      command => '/opt/nextcloud/cron.sh',
      user    => 'root',
      minute  => '*/5',
    }
    file { '/opt/nextcloud/user-sync.sh':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('sunetdrive/application/user-sync.erb.sh'),
    }
    -> cron { 'gss_user_sync':
      command => '/opt/nextcloud/user-sync.sh',
      user    => 'root',
      minute  => '*/5',
    }
    file { '/usr/local/bin/occ':
      ensure  => present,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/application/occ.erb'),
      mode    => '0740',
    }
    file { '/etc/sudoers.d/99-occ':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /usr/local/bin/occ\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    file { '/usr/local/bin/upgrade23-25.sh':
      ensure  => absent,
    }
    file { '/opt/rotate/conf.d/nextcloud.conf':
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => "#This file is managed by puppet\n#filename:retention days:maxsize mb\n/opt/nextcloud/nextcloud.log:180:256\n",
      mode    => '0644',
    }
    file { '/opt/rotate/conf.d/redis.conf':
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => "#This file is managed by puppet
#filename:retention days:maxsize mb\n/opt/redis/server/server.log:180:256\n/opt/redis/sentinel/sentinel.log:180:256\n",
      mode    => '0644',
    }
    file { '/opt/nextcloud/000-default.conf':
      ensure  => file,
      force   => true,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/000-default.conf.erb'),
      mode    => '0644',
    }
    file { '/opt/nextcloud/mpm_prefork.conf':
      ensure  => file,
      force   => true,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/mpm_prefork.conf.erb'),
      mode    => '0644',
    }
    file { '/opt/nextcloud/404.html':
      ensure  => file,
      force   => true,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/404.html.erb'),
      mode    => '0644',
    }
    file { '/opt/nextcloud/config.php':
      ensure  => file,
      force   => true,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/config.php.erb'),
      mode    => '0644',
    }
    file { '/opt/nextcloud/nextcloud.log':
      ensure => file,
      force  => true,
      owner  => 'www-data',
      group  => 'root',
      mode   => '0644',
    }
    file { '/opt/nextcloud/rclone.conf':
      ensure  => file,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/rclone.conf.erb'),
      mode    => '0644',
    }
    file { '/usr/local/bin/migrate_external_mounts':
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/application/migrate_external_mounts.erb'),
      mode    => '0744',
    }
    file { '/opt/nextcloud/complete_reinstall.sh':
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/application/complete_reinstall.erb.sh'),
      mode    => '0744',
    }
    file { '/etc/sudoers.d/99-run-cosmos':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /usr/local/bin/run-cosmos\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    file { '/usr/local/bin/redis-cli':
      ensure  => present,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/application/redis-cli.erb'),
      mode    => '0740',
    }
    file { '/etc/sudoers.d/99-redis-cli':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /usr/local/bin/redis-cli\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    file { '/usr/local/bin/add_admin_user':
      ensure  => present,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/application/add_admin_user.erb'),
      mode    => '0744',
    }
    file { '/etc/sudoers.d/99-no_mysql_servers':
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /home/script/bin/get_no_mysql_servers.sh\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
    file { '/home/script/bin/get_no_mysql_servers.sh':
      ensure  => present,
      force   => true,
      owner   => 'script',
      group   => 'script',
      content => template('sunetdrive/application/get_no_mysql_servers.erb.sh'),
      mode    => '0744',
    }
  }
  if $location =~ /^gss-test/ {
    file { '/opt/nextcloud/mappingfile.json':
      ensure  => present,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/mappingfile-test.json.erb'),
      mode    => '0644',
    }
  } elsif $location =~ /^gss/ {
    file { '/opt/nextcloud/mappingfile.json':
      ensure  => present,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/mappingfile-prod.json.erb'),
      mode    => '0644',
    }
  } elsif $location =~ /^kau/ {
    file { '/mnt':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755',
    }

  }
  if $skeletondirectory {
    file { '/opt/nextcloud/skeleton':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755',
    }
  }
  if $customer == 'mdu' {
    file { '/opt/nextcloud/skeleton/README.md':
      ensure  => present,
      require => File['/opt/nextcloud/skeleton'],
      owner   => 'www-data',
      group   => 'www-data',
      content => template('sunetdrive/application/MDU-README.md.erb'),
      mode    => '0644',
    }
  }
  if $is_multinode {
    $compose = $override_compose
  } else {
    $compose = sunet::docker_compose { 'drive_application_docker_compose':
      content          => template('sunetdrive/application/docker-compose_nextcloud.yml.erb'),
      service_name     => 'nextcloud',
      compose_dir      => '/opt/',
      compose_filename => 'docker-compose.yml',
      description      => 'Nextcloud application',
    }
    if $::facts['sunet_nftables_enabled'] == 'yes' {
      sunet::nftables::docker_expose { 'https':
        allow_clients => ['any'],
        port          => 443,
        iif           => 'ens3',
      }
    } else {
      sunet::misc::ufw_allow { 'https':
        from => '0.0.0.0/0',
        port => 443,
      }
    }
  }

}
