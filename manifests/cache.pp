#Class for SUNET-Drive-Cache
class sunetdrive::cache (
  $bootstrap = undef,
  $location  = undef,
  $override_config = undef,
  $override_compose = undef,
  $override_redis_conf = undef
) {
  $cache = sunetdrive::cache_type { 'base_cache':
    bootstrap => $bootstrap,
    location  => $location,
  }
}
