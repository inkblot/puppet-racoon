# ex: si ts=4 sw=4 et

class racoon (
    $package_name,
    $version,
    $ipsec_tools_package_name,
    $ipsec_tools_version,
    $service_name,
    $pre_shared_keys = {},
    $encapsulate     = {},
    $iptunnels       = {},
    $remotes         = {},
    $associations    = {},
) {
    File {
        ensure => present,
        owner => 'root',
        group => 'root',
        mode  => '0644',
    }

    package { 'racoon':
        name   => $package_name,
        ensure => $package_version,
    }

    package { 'ipsec-tools':
        name   => $ipsec_tools_package_name,
        ensure => $ipsec_tools_version,
    }

    file { '/etc/racoon/racoon.conf':
        content => template('racoon/racoon.conf.erb'),
        require => Package['racoon'],
    }

    file { '/etc/racoon/psk.txt':
        mode    => '0600',
        content => template('racoon/psk.txt.erb'),
        require => Package['racoon'],
    }

    file { '/etc/ipsec-tools.conf':
        content => template('racoon/ipsec-tools/ipsec-tools.conf.erb'),
        require => Package['ipsec-tools'],
    }

    file { '/etc/ipsec-tools.d':
        ensure  => directory,
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    create_resources(racoon::encapsulate, $encapsulate)
    create_resources(racoon::iptunnel, $iptunnels)

    service { 'racoon':
        name       => $service_name,
        ensure     => running,
        pattern    => '/usr/sbin/racoon',
        hasstatus  => false,
        hasrestart => true,
        subscribe  => File['/etc/racoon/racoon.conf', '/etc/racoon/psk.txt'],
    }

    exec { 'setkey restart':
        command     => '/usr/sbin/service setkey restart',
        user        => 'root',
        refreshonly => true,
        subscribe   => File['/etc/ipsec-tools.conf'],
    }
}
