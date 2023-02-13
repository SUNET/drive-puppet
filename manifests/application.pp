# A Class using the app resurce
class sunetdrive::application (
  $bootstrap = undef,
  $location  = undef,
  $override_config = undef,
  $override_compose = undef
) {

  $app = sunetdrive::app_type { 'base_app':
    bootstrap => $bootstrap,
    location  => $location,
  }
}
