#Class for SUNET-Drive-Script
class sunetdrive::script (
  $bootstrap = undef,
  $location  = undef
) {
  $environment = sunetdrive::get_environment()
  $customer = sunetdrive::get_customer()
  $apikey_test = safe_hiera('monitor_apikey_test')
  $apikey_prod = safe_hiera('monitor_apikey_prod')
  $full_project_mapping = hiera_hash('project_mapping')
  $project_mapping = $full_project_mapping[$customer][$environment]
  $primary_project = $project_mapping['primary_project']
  $mirror_project = $project_mapping['mirror_project']
  $assigned_projects = $project_mapping['assigned']
  $full_backup_retention = hiera('full_backup_retention')
  $config = hiera_hash($environment)
  $backup_server = $config['backup_server']
  $rclone_url = 'https://downloads.rclone.org/rclone-current-linux-amd64.deb'
  $local_path = '/tmp/rclone-current-linux-amd64.deb'
  $singlenodes = hiera('singlenodes')

  if $customer == 'mdu' {
    $eppn_suffix = 'mdh.se'
    $include_userbuckets = 'true'
  } elsif $customer == 'uu' {
    $eppn_suffix = 'users.uu.se'
    $include_userbuckets = 'false'
  }
  else {
    $eppn_suffix = "${customer}.se"
    $include_userbuckets = 'false'
  }

  $ssh_config = "Host *.sunet.se
  User script
  IdentityFile /root/.ssh/id_script"

  $s3_key = safe_hiera('s3_key')
  $s3_secret = safe_hiera('s3_secret')
  $statistics_secret = safe_hiera('statistics_secret')
  $s3_key_pilot = hiera('s3_key_pilot', false)
  $s3_secret_pilot = hiera('s3_secret_pilot', false)
  # FIXME: This will not work if we start to mess around with the location of multinode customer data
  $s3_host = $config['s3_host']
  if $s3_host == 's3.sto4.safedc.net' {
    $s3_host_mirror = 's3.sto3.safedc.net'
    $s3_key_mirror = safe_hiera('s3_key_sto3')
    $s3_secret_mirror = safe_hiera('s3_secret_sto3')
  } else {
    $s3_host_mirror = 's3.sto4.safedc.net'
    $s3_key_mirror = safe_hiera('s3_key_sto4')
    $s3_secret_mirror = safe_hiera('s3_secret_sto4')
  }
  $site_name  = $config['site_name']
  $user_bucket_name  = $config['user_bucket_name']

  # It is a start that will get us user buckets and primary buckets
  $backup_projects = $location
  exec { 'rclone_deb':
    command => "/usr/bin/wget -q ${rclone_url} -O ${local_path}",
    creates => $local_path,
  }
  package { 'rclone':
    ensure   => installed,
    provider => dpkg,
    source   => $local_path,
    require  => Exec['rclone_deb'],
  }
  package { 'python3.9':
    ensure   => installed,
    provider => apt,
  }
  -> package { 'python3-pip':
    ensure   => installed,
    provider => apt,
  }
  package { 'duplicity':
    ensure   => installed,
    provider => apt,
  }
  $drive_version = '0.3.1'
  exec { 'drive-utils':
    command => "python3.9 -m pip install https://pypi.sunet.se/packages/drive-utils-${drive_version}.tar.gz",
    unless  => "python3.9 -m pip list | grep drive-utils | grep ${drive_version}",
    require => Package['python3.9'],
  }
  file { '/root/.ssh/':
    ensure => directory,
    mode   => '0700',
  }
  file { '/root/tasks/':
    ensure => directory,
    mode   => '0700',
  }
  file { '/root/scripts/':
    ensure => directory,
    mode   => '0700',
  }
  file { '/root/.ssh/id_script':
    ensure  => file,
    content => safe_hiera('ssh_priv_key'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/root/.ssh/config':
    ensure  => file,
    content => $ssh_config,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/root/.rclone.conf':
    ensure  => file,
    content => template('sunetdrive/script/rclone.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  if $s3_key_pilot and $s3_secret_pilot {
    file { '/root/scripts/migratebuckets.sh':
      ensure  => file,
      content => template('sunetdrive/script/migratebuckets.erb.sh'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
    }
  }

  file { '/root/tasks/backupsingleproject.sh':
    ensure  => file,
    content => template('sunetdrive/script/backupsingleproject.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/backupbuckets.sh':
    ensure  => file,
    content => template('sunetdrive/script/backup-all-buckets.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/backup-projectbuckets.sh':
    ensure  => absent,
  }
  file { '/root/tasks/backupdb.sh':
    ensure  => file,
    content => template('sunetdrive/script/backupdb.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/restart-nextcloud-farm':
    ensure  => file,
    content => template('sunetdrive/script/restart-nextcloud-farm.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/restart-db-cluster':
    ensure  => file,
    content => template('sunetdrive/script/restart-db-cluster.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/restart-proxysql.sh':
    ensure  => file,
    content => template('sunetdrive/script/restart-proxysql.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/usage.sh':
    ensure  => file,
    content => template('sunetdrive/script/usage.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/maintenance.sh':
    ensure  => file,
    content => template('sunetdrive/script/maintenance.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/reboot-customer.sh':
    ensure  => file,
    content => template('sunetdrive/script/reboot-customer.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/usr/local/bin/check_backups':
    ensure  => file,
    content => template('sunetdrive/script/check_backup.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/collect_backup_data.sh':
    ensure  => file,
    content => template('sunetdrive/script/collect_backup_data.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/makebuckets.sh':
    ensure  => file,
    content => template('sunetdrive/script/makebuckets.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  file { '/root/tasks/makemanualuserbucket.sh':
    ensure  => file,
    content => template('sunetdrive/script/makemanualuserbucket.erb.sh'),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }
  if $environment == 'test' {
    sunet::scriptherder::cronjob { 'reboot-customer':
      cmd           => '/root/tasks/reboot-customer.sh',
      hour          => '2',
      minute        => '10',
      ok_criteria   => ['exit_status=0','max_age=21d'],
      warn_criteria => ['exit_status=1','max_age=31d'],
    }
  }
  # Opt out of userbuckets
  unless $customer in ['extern', 'gih', 'suni', 'common'] {
    sunet::scriptherder::cronjob { 'makebuckets':
      cmd           => '/root/tasks/makebuckets.sh',
      minute        => '*/5',
      ok_criteria   => ['exit_status=0','max_age=15m'],
      warn_criteria => ['exit_status=1','max_age=30m'],
    }
  }
  # Opt in folder structer for multinode customers
  if $customer in ['common'] {

    file { '/root/tasks/listusers.sh':
      ensure  => file,
      content => template('sunetdrive/script/listusers.erb.sh'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
    }
    file { '/root/tasks/create_folders_in_singlenode_buckets.sh':
      ensure  => file,
      content => template('sunetdrive/script/create_folders_in_singlenode_buckets.erb.sh'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
    }
    sunet::scriptherder::cronjob { 'create_folders_in_singlenode_buckets_for_kmh':
      cmd           => '/root/tasks/create_folders_in_singlenode_buckets.sh kmh true',
      minute        => '*/30',
      ok_criteria   => ['exit_status=0','max_age=1h'],
      warn_criteria => ['exit_status=1','max_age=2h'],
    }
  }
  # Opt in to folder structure in projectbuckets
  if $customer in ['gih', 'mdu'] {
    sunet::scriptherder::cronjob { 'create_folders_in_project_buckets':
      cmd => 'true',
      ensure => absent,
    }
    file { '/root/tasks/create_folders_in_project_buckets.sh':
      ensure => absent,
    }
    file { '/root/tasks/create_folders_in_fullnode_buckets.sh':
      ensure  => file,
      content => template('sunetdrive/script/create_folders_in_fullnode_buckets.erb.sh'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
    }
  }
  if $customer in ['gih'] {
    sunet::scriptherder::cronjob { 'create_folders_in_fullnode_buckets':
      cmd           => '/root/tasks/create_folders_in_fullnode_buckets.sh',
      minute        => '*/30',
      ok_criteria   => ['exit_status=0','max_age=1h'],
      warn_criteria => ['exit_status=1','max_age=2h'],
    }
  }
  if $customer in ['mdu'] {
    sunet::scriptherder::cronjob { 'create_folders_in_fullnode_buckets':
      cmd           => '/root/tasks/create_folders_in_fullnode_buckets.sh "Arbetsmaterial (work material)" "Bevarande (retention)" "Gallringsbart (disposal)"',
      minute        => '*/30',
      ok_criteria   => ['exit_status=0','max_age=1h'],
      warn_criteria => ['exit_status=1','max_age=2h'],
    }
  }
  if $customer == 'common' {
    if $environment == 'prod' {
      file { '/root/tasks/aggregate.sh':
        ensure  => file,
        content => template('sunetdrive/script/aggregate.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
      }
      sunet::scriptherder::cronjob { 'aggregate_billing':
        cmd           => '/root/tasks/aggregate.sh',
        hour          => '4',
        minute        => '10',
        ok_criteria   => ['exit_status=0','max_age=2d'],
        warn_criteria => ['exit_status=1','max_age=3d'],
      }
      file { '/root/tasks/backupsinglenodedb.sh':
        ensure  => file,
        content => template('sunetdrive/script/backupsinglenodedb.erb.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
      }

    }
    else {
      file { '/root/tasks/backupsinglenodedb.sh':
        ensure  => absent,
      }
      file { '/root/tasks/backupmultinodedb.sh':
        ensure  => file,
        content => template('sunetdrive/script/backupmultinodedb.erb.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
      }
      sunet::scriptherder::cronjob { "backupmultinodedb":
        cmd           => "/root/tasks/backupmultinodedb.sh",
        hour          => '2',
        minute        => '0',
        ok_criteria   => ['exit_status=0','max_age=2d'],
        warn_criteria => ['exit_status=1','max_age=3d'],
      }
    }
    $singlenodes.each | $singlenode| {
      $multinode = hiera_hash('multinode_mapping')[$singlenode]['server']
      $multinodeserver = "${multinode}.${site_name}"
      $nccontainer = "nextcloud-${singlenode}_app_1"

      sunet::scriptherder::cronjob { "listusers_${singlenode}":
        cmd           => "/root/tasks/listusers.sh ${singlenode} ${multinodeserver}",
        minute        => '*/5',
        ok_criteria   => ['exit_status=0','max_age=30m'],
        warn_criteria => ['exit_status=1', 'max_age=60m'],
      }
      if $environment == 'prod' {
        sunet::scriptherder::cronjob { "backup${singlenode}db":
          cmd           => "/root/tasks/backupsinglenodedb.sh ${multinodeserver} ${singlenode}",
          hour          => '2',
          minute        => '0',
          ok_criteria   => ['exit_status=0','max_age=2d'],
          warn_criteria => ['exit_status=1','max_age=3d'],
        }
        sunet::scriptherder::cronjob { "statistics${singlenode}":
          cmd           => "/root/tasks/usage.sh ${singlenode} ${multinodeserver}",
          hour          => '2',
          minute        => '0',
          ok_criteria   => ['exit_status=0','max_age=2d'],
          warn_criteria => ['exit_status=1','max_age=3d'],
        }
      }
      else {
        sunet::scriptherder::cronjob { "backup${singlenode}db":
          ensure        => absent,
          cmd           => 'true',
        }
      }
      unless $singlenode in ['mau', 'uu'] {
        sunet::scriptherder::cronjob { "make${singlenode}buckets":
          cmd           => "/root/tasks/makebuckets.sh ${multinodeserver} ${nccontainer} ${singlenode}-${environment}",
          minute        => '*',
          ok_criteria   => ['exit_status=0','max_age=15m'],
          warn_criteria => ['exit_status=1','max_age=30m'],
        }
      }
    }
    $gss_backup_server  = $config['gss_backup_server']
    $lookup_backup_server  = $config['lookup_backup_server']
    sunet::scriptherder::cronjob { 'backupgssdb':
      cmd           => "/root/tasks/backupdb.sh ${gss_backup_server}",
      hour          => '2',
      minute        => '0',
      ok_criteria   => ['exit_status=0','max_age=2d'],
      warn_criteria => ['exit_status=1','max_age=3d'],
    }
    sunet::scriptherder::cronjob { 'backuplookupdb':
      cmd           => "/root/tasks/backupdb.sh ${lookup_backup_server}",
      hour          => '2',
      minute        => '0',
      ok_criteria   => ['exit_status=0','max_age=2d'],
      warn_criteria => ['exit_status=1','max_age=3d'],
    }
  } else {
    sunet::scriptherder::cronjob { 'backupdb':
      cmd           => "/root/tasks/backupdb.sh ${backup_server}",
      hour          => '2',
      minute        => '0',
      ok_criteria   => ['exit_status=0','max_age=2d'],
      warn_criteria => ['exit_status=1','max_age=3d'],
    }
    sunet::scriptherder::cronjob { 'restart_proxysql':
      ensure        => 'absent',
      cmd           => '/bin/true',
      purge_results => true,
    }
    if $environment == 'prod' {
      sunet::scriptherder::cronjob { 'statistics':
        cmd           => '/root/tasks/usage.sh',
        hour          => '2',
        minute        => '0',
        ok_criteria   => ['exit_status=0','max_age=2d'],
        warn_criteria => ['exit_status=1','max_age=3d'],
      }
    }
  }
  sunet::scriptherder::cronjob { 'collect_backup_data':
    cmd           => '/root/tasks/collect_backup_data.sh',
    hour          => '*',
    minute        => '3',
    ok_criteria   => ['exit_status=0','max_age=2d'],
    warn_criteria => ['exit_status=1','max_age=3d'],
  }
  sunet::scriptherder::cronjob { 'backupbuckets':
    cmd           => '/root/tasks/backupbuckets.sh',
    hour          => '2',
    minute        => '0',
    ok_criteria   => ['exit_status=0','max_age=2d'],
    warn_criteria => ['exit_status=1','max_age=3d'],
  }
  #  sunet::scriptherder::cronjob { 'scriptherder_daily':
  #    cmd           => '/bin/true',
  #    special       => 'daily',
  #    ok_criteria   => ['exit_status=0','max_age=4d'],
  #    warn_criteria => ['exit_status=1','max_age=8d'],
  #  }
  #  cron { 'example_job':
  #    ensure  => 'present',
  #    command => '/bin/true',
  #    hour    => ['0'],
  #    target  => 'root',
  #    user    => 'root',
  #  }
}
