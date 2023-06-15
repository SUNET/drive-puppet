#Class for SUNET-Drive-Script-receiver
class sunetdrive::scriptreceiver()
{
  include sunet::packages::yq
  sunet::system_user {'script': username => 'script', group => 'script', managehome => true, shell => '/bin/bash' }

  # These tasks correspond to a ${task}.erb.sh template
  $tasks = ['list_users', 'list_files_for_user', 'create_bucket', 'backup_db', 'purge_backups', 'maintenancemode', 'restart_sunet_service', 'start_sentinel', 'stop_sentinel', 'removeswap', 'backup_multinode_db']

  $environment = sunetdrive::get_environment()
  $config = hiera_hash($environment)
  $script_server = $config['script_server']
  $script_ipv4 = $config['script']
  $script_ipv6 = $config['script_v6']
  $script_pub_key = $config['script_pub_key']
  file { '/etc/sudoers.d/99-script-user':
    ensure  => absent,
  }

  file { '/home/script/bin':
    ensure => directory,
    mode   => '0750',
    owner  => 'script',
    group  => 'script',
  }
  $kano_shell = ['89.46.21.246','2001:6b0:6c::1bc']
  sunet::misc::ufw_allow { 'script_port':
    from => $script_ipv4 + $script_ipv6 + $kano_shell,
    port => 22,
  }

  ssh_authorized_key { "script@${script_server}":
    ensure => present,
    user   => 'script',
    type   => 'ssh-ed25519',
    key    => $script_pub_key,
  }

  file { '/opt/rotate':
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }
  -> file { '/opt/rotate/conf.d':
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }
  file { '/usr/local/bin/safer_reboot':
    ensure  => file,
    content => template('sunetdrive/scriptreceiver/safer_reboot.erb'),
    mode    => '0744',
    owner   => 'root',
    group   => 'root',
  }
  file { '/root/.bashrc':
    ensure  => file,
    content => template('sunetdrive/scriptreceiver/baschrc.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
  file { "/etc/sudoers.d/99-safer_reboot":
    ensure  => file,
    content => "script ALL=(root) NOPASSWD: /usr/local/bin/safer_reboot\n",
    mode    => '0440',
    owner   => 'root',
    group   => 'root',
  }
  file { '/usr/local/bin/rotatefiles':
    ensure  => file,
    content => template('sunetdrive/scriptreceiver/rotatefiles.erb'),
    mode    => '0740',
    owner   => 'root',
    group   => 'root',
  }
  file { '/usr/local/bin/ini2json':
    ensure  => file,
    content => template('sunetdrive/scriptreceiver/ini2json.py'),
    mode    => '0740',
    owner   => 'root',
    group   => 'root',
  }
  -> file { '/etc/scriptherder/check/rotatefiles.ini':
    ensure  => file,
    content => "[check]\nok      = exit_status=0, max_age=35m\nwarning = exit_status=0, max_age=1h\n",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
  cron { 'rotate_logs':
    command => ' /usr/local/bin/scriptherder --mode wrap --syslog --name rotatefiles -- /usr/local/bin/rotatefiles',
    require => File['/usr/local/bin/rotatefiles'],
    user    => 'root',
    minute  =>  '*',
    hour    =>  '*',
  }
  file { '/usr/local/bin/clear_scriptherder':
    ensure  => file,
    content => template('sunetdrive/scriptreceiver/clear_scriptherder.erb.sh'),
    mode    => '0740',
    owner   => 'root',
    group   => 'root',
  }
  file { '/home/script/bin/makeswap.sh':
    ensure  => absent,
  }
  file { '/etc/sudoers.d/99-makeswap':
    ensure  => absent,
  }
  $tasks.each |String $task| {
    file { "/home/script/bin/${task}.sh":
      ensure  => file,
      content => template("sunetdrive/scriptreceiver/${task}.erb.sh"),
      mode    => '0740',
      owner   => 'script',
      group   => 'script',
    }
    file { "/etc/sudoers.d/99-${task}":
      ensure  => file,
      content => "script ALL=(root) NOPASSWD: /home/script/bin/${task}.sh\n",
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
    }
  }
}

