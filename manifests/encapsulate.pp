# ex: syntax=puppet si ts=4 sw=4 et

define racoon::encapsulate (
    $local_ip,
    $remote_ip   = '0.0.0.0/0',
    $port,
    $proto,
) {
    file { "/etc/ipsec-tools.d/${name}.conf":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template('racoon/ipsec-tools/encapsulate.erb'),
        notify  => Exec['setkey restart'],
    }
}
