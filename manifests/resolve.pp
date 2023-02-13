include stdlib
# Sunet drive resolver
class sunetdrive::resolve($location=undef) {
  $unbound_conf = '# This file is managed by puppet
server:
    interface: 0.0.0.0
    interface: ::0
    access-control: 37.156.195.0/24 allow
    access-control: 89.45.237.0/24 allow
    access-control: 89.45.20.0/24 allow
    access-control: 89.45.21.0/24 allow
    access-control: 2001:6b0:1c::/64 allow
    access-control: 2001:6b0:6c::/64 allow'

  file { 'sunetdrive_unbound_conf' :
      ensure  => 'file',
      name    => '/etc/unbound/unbound.conf.d/sunetdrive.conf',
      mode    => '0644',
      content => $unbound_conf,
  }
  file_line {'disable_systemd_stubresolver':
    line => 'DNSStubListener=no',
    path => '/etc/systemd/resolved.conf'
  }
  -> exec {'disable_systemd_resolved':
    command => 'systemctl disable --now  systemd-resolved.service',
    onlyif  => 'systemctl is-enabled systemd-resolved.service',
  }
  sunet::misc::ufw_allow { 'dns_port_ufw_udp':
    from  => 'any',
    port  => 53,
    proto => 'udp',
  }
  sunet::misc::ufw_allow { 'dns_port_ufw_tcp':
    from  => 'any',
    port  => 53,
    proto => 'tcp',
  }

}
