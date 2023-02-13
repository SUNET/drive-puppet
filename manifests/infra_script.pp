#Class for SUNET-Drive-Script
class sunetdrive::infra_script (
  $bootstrap = undef,
  $location  = undef
) {
  $environment = sunetdrive::get_environment()
  $customer = "common"
  $config = hiera_hash($environment)
  $gss_backup_server  = $config['gss_backup_server']
  $lookup_backup_server  = $config['lookup_backup_server']
  $ssh_config = "Host *.sunet.se
  User script
  IdentityFile /root/.ssh/id_script"
  $site_name  = $config['site_name']
  package { 'python3-pip':
    ensure   => installed,
    provider => apt,
  }
  package { 'drive-utils':
    ensure   => installed,
    provider => pip3,
    source   => 'https://pypi.sunet.se/packages/drive-utils-0.1.3.tar.gz',
    require  => Package['python3-pip'],
  }
  file { '/root/.ssh/':
    ensure => directory,
    mode   => '0700',
  }
  file { '/root/tasks/':
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
  file { '/root/tasks/backupdb.sh':
    ensure  => file,
    content => template('sunetdrive/script/backupdb.erb.sh'),
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

