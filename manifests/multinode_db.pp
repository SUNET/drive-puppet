class sunetdrive::multinode_db(){
    $is_multinode = true;
    $environment = sunetdrive::get_environment()
    $allcustomers = hiera_hash('multinode_mapping')
    $customers = $allcustomers.keys

    $customers.each |$customer| {
      file { "/etc/mariadb/backups/${customer}":
        ensure => directory,
      }
      file { "/etc/mariadb/init/04-nextcloud.${customer}.sql":
        ensure  => present,
        content => "CREATE SCHEMA nextcloud_${customer};\nCREATE USER 'nextcloud_${customer}'@'%' IDENTIFIED BY '${hiera("${customer}_mysql_user_password")}';\nGRANT ALL PRIVILEGES ON nextcloud_${customer}.* TO 'nextcloud_${customer}'@'%' IDENTIFIED BY '${hiera("${customer}_mysql_user_password")}';\n",
        mode    => '0744',
      }
    }
}
