# Lets determin where we are by looking at the hostname
function sunetdrive::get_node_number() >> Integer {
  Integer(regsubst($::fqdn, /^[a-zA-Z\-]+(\d).*$/, '\\1'))
}
