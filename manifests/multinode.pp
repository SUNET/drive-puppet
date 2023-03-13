# This class uses all the other classes to create a multinode server
class sunetdrive::multinode (
  $bootstrap = undef,
  $location  = undef
)
{
  $myname =  $facts['hostname']
  $is_multinode = true;
  $environment = sunetdrive::get_environment()
  $lb_servers = hiera_hash($environment)['lb_servers']
  $document_servers = hiera_hash($environment)['document_servers']
  $nextcloud_ip = hiera_hash($environment)['app']
  $db_ip = hiera_hash($environment)['db']
  $admin_password = hiera('admin_password')
  $cluster_admin_password = hiera('cluster_admin_password')

  $twofactor_enforced_groups = []
  $twofactor_enforced_excluded_groups = []
  $allcustomers = hiera_hash('multinode_mapping')
  $allnames = $allcustomers.keys
  $tempcustomers = $allnames.map | $index, $potential | {
    if $myname =~ $allcustomers[$potential]['server'] {
      $potential
    }
    else {
      nil
    }
  }
  $php_memory_limit_mb = 512
  $nodenumber = $::fqdn[9,1]
  $customers = $tempcustomers - nil
  $passwords = $customers.map | $index, $customer | {
    hiera("${customer}_mysql_user_password")
  }
  $transaction_persistent = 1
  $monitor_password = hiera('proxysql_password')
  user { 'www-data': ensure => present, system => true }
  sunet::system_user {'mysql': username => 'mysql', group => 'mysql' }
  ensure_resource('file', '/opt/nextcloud' , { ensure => directory, recurse => true } )
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
    ensure  => present,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/multinode/upgrade23-25.erb.sh'),
    mode    => '0744',
  }
  file { '/usr/local/bin/get_containers':
    ensure  => present,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/multinode/get_containers'),
    mode    => '0744',
  }
  file { '/usr/local/bin/add_admin_user':
    ensure  => present,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/application/add_admin_user.erb'),
    mode    => '0744',
  }
  file { '/opt/nextcloud/prune.sh':
    ensure  => file,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/multinode/prune.erb.sh'),
    mode    => '0744',
  }
  if $environment == 'test' {
    cron { 'multinode_prune':
      command => '/opt/nextcloud/prune.sh',
      require => File['/opt/nextcloud/prune.sh'],
      user    => 'root',
      minute  =>  '25',
      hour    =>  '4',
    }
    file { '/opt/proxysql/proxysql.cnf':
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/multinode/proxysql.cnf.erb'),
      mode    => '0644',
    }
  }
  file { '/opt/nextcloud/apache.php.ini':
    ensure  => file,
    force   => true,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/application/apache.php.ini.erb'),
    mode    => '0644',
  }

  file { '/opt/nextcloud/apcu.ini':
    ensure  => file,
    force   => true,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/application/apcu.ini.erb'),
    mode    => '0644',
  }

  file { '/opt/nextcloud/cli.php.ini':
    ensure  => file,
    force   => true,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/application/cli.php.ini.erb'),
    mode    => '0644',
  }

  file { '/opt/nextcloud/cron.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('sunetdrive/application/cron.erb.sh'),
  }

  file { '/opt/nextcloud/000-default.conf':
    ensure  => file,
    force   => true,
    owner   => 'www-data',
    group   => 'root',
    content => template('sunetdrive/application/000-default.conf.erb'),
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
  $link_content = '[Match]
Driver=bridge veth

[Link]
MACAddressPolicy=none'
  file { '/etc/systemd/network/98-default.link':
    ensure  => file,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => $link_content,
    mode    => '0744',
  }
  file { '/opt/nextcloud/compress-logs.sh':
    ensure  => file,
    force   => true,
    owner   => 'root',
    group   => 'root',
    content => template('sunetdrive/multinode/compress-logs.erb.sh'),
    mode    => '0744',
  }
  cron { 'multinode_compress_logs':
    command => '/opt/nextcloud/compress-logs.sh',
    require => File['/opt/nextcloud/compress-logs.sh'],
    user    => 'root',
    minute  => '10',
    hour    => '0',
    weekday => '0',
  }
  if $nodenumber == '2' {
    cron { 'add_back_bucket_for_karin_nordgren':
      command => '(/usr/local/bin/occ nextcloud-kmh_app_1 files_external:list karin_nordgren@kmh.se  &&  /home/script/bin/create_bucket.sh nextcloud-kmh_app_1 karin_nordgren@kmh.se karin-nordgren-drive-sunet-se) || /bin/true',
      user    => 'root',
      minute  =>  '*/10',
    }
  }
  $customers.each | $index, $customer | {
    cron { "multinode_cron_${customer}":
      command => "/opt/nextcloud/cron.sh nextcloud-${customer}_app_1",
      require => File['/opt/nextcloud/cron.sh'],
      user    => 'root',
      minute  =>  '*/10',
    }
    if $environment == 'prod' {
      $s3_bucket = "primary-${customer}-drive.sunet.se"
      $site_name = "${customer}.drive.sunet.se"
      $trusted_proxies = ['lb1.drive.sunet.se','lb2.drive.sunet.se', 'lb3.drive.sunet.se', 'lb4.drive.sunet.se']
    } else {
      $s3_bucket = "primary-${customer}-${environment}.sunet.se"
      $site_name = "${customer}.drive.${environment}.sunet.se"
      $trusted_proxies = ["lb1.drive.${environment}.sunet.se","lb2.drive.${environment}.sunet.se",
      "lb3.drive.${environment}.sunet.se","lb4.drive.${environment}.sunet.se"]
    }
    $apache_default_path = "/opt/multinode/${customer}/000-default.conf"
    $apache_error_path = "/opt/multinode/${customer}/404.html"
    $config_php_path = "/opt/multinode/${customer}/config.php"
    $cron_log_path ="/opt/multinode/${customer}/cron.log"
    $customer_config_full = hiera_hash($customer)
    $customer_config = $customer_config_full[$environment]

    if  $environment == 'prod' {
      $dbhost = "mariadb-${customer}_db_1"
      $dbname = 'nextcloud'
      $dbuser = 'nextcloud'
    } else {
      $dbhost = 'proxysql_proxysql_1'
      $dbname = "nextcloud_${customer}"
      $dbuser = "nextcloud_${customer}"
    }

    $gs_enabled = hiera('gs_enabled')
    $gs_federation = hiera('gs_federation')
    $gss_master_admin = hiera_array('gss_master_admin')
    $gss_master_url = hiera("gss_master_url_${environment}")
    $https_port = hiera_hash('multinode_mapping')[$customer]['port']
    $lookup_server = hiera("lookup_server_${environment}")
    $mail_domain = hiera("mail_domain_${environment}")
    $mail_from_address = hiera("mail_from_address_${environment}")
    $mail_smtphost = hiera("mail_smtphost_${environment}")
    $nextcloud_log_path ="/opt/multinode/${customer}/nextcloud.log"
    $nextcloud_version = hiera("nextcloud_version_${environment}")
    $nextcloud_version_string =  split($nextcloud_version, '[-]')[0]
    $rclone_conf_path = "/opt/multinode/${customer}/rclone.conf"
    $redis_conf_dir = "/opt/multinode/${customer}/server"
    $redis_conf_path = "${redis_conf_dir}/redis.conf"
    $redis_host= "redis-${customer}_redis-server_1"
    $s3_host = $customer_config['s3_host']
    $s3_usepath = hiera('s3_usepath')
    $smtpuser = hiera("smtp_user_${environment}")
    $trusted_domains = [$site_name, $facts['fqdn'], 'localhost']
    $tug_office = hiera_array('tug_office')

    # Secrets from local.eyaml
    $admin_password = safe_hiera("${customer}_admin_password")
    $instanceid = safe_hiera("${customer}_instanceid")
    $mysql_root_password = safe_hiera("${customer}_mysql_root_password")
    $backup_password = safe_hiera("${customer}_backup_password")
    $mysql_user_password = safe_hiera("${customer}_mysql_user_password")
    $s3_key = safe_hiera("${customer}_s3_key")
    $s3_secret = safe_hiera("${customer}_s3_secret")
    $secret = safe_hiera("${customer}_secret")
    $passwordsalt= safe_hiera("${customer}_passwordsalt")
    $redis_host_password = safe_hiera("${customer}_redis_host_password")
    $gss_jwt_key = safe_hiera('gss_jwt_key')
    $smtppassword = safe_hiera('smtp_password')

    $extra_config = {
      admin_password                       => $admin_password,
      backup_password                      => $backup_password,
      dbhost                               => $dbhost,
      dbname                               => $dbname,
      dbuser                               => $dbuser,
      drive_email_template_plain_text_left => hiera($environment)['drive_email_template_plain_text_left'],
      drive_email_template_text_left       => hiera($environment)['drive_email_template_text_left'],
      drive_email_template_url_left        => hiera($environment)['drive_email_template_url_left'],
      mariadb_dir                          => "/opt/multinode/${customer}/mariadb-${customer}",
      mycnf_path                           => 'sunetdrive/multinode/my.cnf.erb',
      mysql_root_password                  => $mysql_root_password,
      mysql_user_password                  => $mysql_user_password,
      trusted_domains                      => $trusted_domains,
      trusted_proxies                      => $trusted_proxies,
    }
    $config = deep_merge($customer_config, $extra_config)
    ensure_resource('file', "/opt/multinode/${customer}" , { ensure => directory, recurse => true } )
    # Use the other sunetdrive classes with overridden config
    $db_ip = ['127.0.0.1']
    $app_compose = sunet::docker_compose { "drive_${customer}_app_docker_compose":
      content          => template('sunetdrive/multinode/docker-compose_nextcloud.yml.erb'),
      service_name     => "nextcloud-${customer}",
      compose_dir      => "/opt/multinode/${customer}",
      compose_filename => 'docker-compose.yml',
      description      => "Nextcloud application for ${customer}",
      require          => File[$config_php_path,
        '/opt/nextcloud/apache.php.ini',
        '/opt/nextcloud/cli.php.ini',
        "/opt/multinode/${customer}/complete_reinstall.sh",
      ],
    }
    $cache_compose = sunet::docker_compose { "drive_${customer}_redis_docker_compose":
      content          => template('sunetdrive/multinode/docker-compose_cache.yml.erb'),
      service_name     => "redis-${customer}",
      compose_dir      => "/opt/multinode/${customer}",
      compose_filename => 'docker-compose.yml',
      description      => "Redis cache server for ${customer}",
      require          => File[$redis_conf_path],
    }
    # Only add db related to prod
    if $environment == 'prod' {
      $dirs = ['datadir', 'init', 'conf', 'scripts' ]
      $dirs.each |$dir| {
        ensure_resource('file',"${config['mariadb_dir']}/${dir}", { ensure => directory, recurse => true } )
      }

      ensure_resource('file',"${config['mariadb_dir']}/backups", {
        ensure => directory,
        owner => 'root',
        group => 'script',
        mode => '0750',
        recurse => true
        } )
      $mariadb_compose   = sunet::docker_compose { "drive_mariadb_${customer}_compose":
        content          => template('sunetdrive/multinode/docker-compose_mariadb.yml.erb'),
        service_name     => "mariadb-${customer}",
        compose_dir      => "/opt/multinode/${customer}",
        compose_filename => 'docker-compose.yml',
        description      => "Mariadb server for ${customer}",
        owner            => 'root',
        group            => 'script',
        mode             => '0750',
      }

      file { "/opt/multinode/${customer}/mariadb-${customer}/do_backup.sh":
        ensure  => present,
        content => template('sunetdrive/mariadb_backup/do_backup.erb.sh'),
        mode    => '0744',
      }
      sunetdrive::db_type { "db_${customer}":
        location         => $location,
        override_config  => $config,
        override_compose => $mariadb_compose,
      }
    }
    # END DB related
    sunetdrive::app_type { "app_${customer}":
      location         => $location,
      override_config  => $config,
      override_compose => $app_compose,
    }

    file { $redis_conf_dir:
      ensure  => directory,
      recurse => true,
    }
    $redis_config = file { $redis_conf_path:
      ensure  => present,
      content => template('sunetdrive/multinode/redis.conf.erb'),
      mode    => '0666',
      require => [ File[$redis_conf_dir]]
    }
    sunetdrive::cache_type { "cache_${customer}":
      location            => $location,
      override_config     => $config,
      override_compose    => $cache_compose,
      override_redis_conf => $redis_config,
      require             => File[$redis_conf_path],
    }
    file { $config_php_path:
      ensure  => present,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/application/config.php.erb'),
      mode    => '0644',
    }
    file { $cron_log_path:
      ensure => file,
      force  => true,
      owner  => 'www-data',
      group  => 'root',
      mode   => '0644',
    }
    file { $nextcloud_log_path:
      ensure => file,
      force  => true,
      owner  => 'www-data',
      group  => 'root',
      mode   => '0644',
    }
    file { $rclone_conf_path:
      ensure  => present,
      owner   => 'www-data',
      group   => 'root',
      content => template('sunetdrive/multinode/rclone.conf.erb'),
      mode    => '0644',
    }
    file { "/opt/multinode/${customer}/complete_reinstall.sh":
      ensure  => file,
      force   => true,
      owner   => 'root',
      group   => 'root',
      content => template('sunetdrive/multinode/complete_reinstall.erb.sh'),
      mode    => '0744',
    }
    # Open ports
    sunet::misc::ufw_allow { "https_port_${customer}":
      from => '0.0.0.0',
      port => $https_port,
    }
  }
}
