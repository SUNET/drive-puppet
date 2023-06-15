#Class for SUNET-Drive-Cache
class sunetdrive::redis_cluster (
  $location  = undef,
)
{
  $customer = sunetdrive::get_customer()
  $redis_password = safe_hiera('redis_password')
  package { 'redis-tools': ensure => latest, provider => 'apt' }

  file { '/usr/local/bin/bootstrap_cluster':
      ensure  => present,
      content => template('sunetdrive/redis_cluster/bootstrap_cluster.erb.sh'),
      mode    => '0700',
  }
  file { '/usr/local/bin/reset_cluster':
      ensure  => present,
      content => template('sunetdrive/redis_cluster/reset_cluster.erb.sh'),
      mode    => '0700',
  }
}
