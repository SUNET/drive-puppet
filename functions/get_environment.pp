# Lets determin where we are by looking at the hostname
function sunetdrive::get_environment() >> String {
  $hostname = $facts['fqdn']
  if $hostname =~ /^.*\.drive\.sunet\.se$/ {
    if $hostname =~ /^.*\.pilot\.drive\.sunet\.se$/ {
      return 'pilot'
    }
    else {
      return 'prod'
    }
  }
  'test'
}
