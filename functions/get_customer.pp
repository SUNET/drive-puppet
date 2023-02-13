# Lets determin who the customer is by looking at the hostname
function sunetdrive::get_customer() >> String {
  $hostnameparts = split($facts['fqdn'],'\.')
  if $hostnameparts[1] ==  'drive' {
      if $hostnameparts[0] =~ /^gss/ {
        return 'gss'
      } elsif $hostnameparts[0] =~ /^lookup/ {
        return 'lookup'
      } else {
        return 'common'
      }
  } elsif $hostnameparts[0] =~ /idp-proxy/ {
    return 'common'
  }

  return $hostnameparts[1]
}
