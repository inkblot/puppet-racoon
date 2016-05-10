# ex: si ts=4 sw=4 et

class racoon (
    $package_name    = 'racoon',
    $version         = 'present',
    $ipsec_tools_package_name = 'ipsec-tools',
    $ipsec_tools_version = 'present',
    $service_name    = 'racoon',
    $restart         = 'restart',
    $setkey_restart  = 'restart',
    $local_gateway   = $::ipaddress,
    $policy_level    = 'require',
    $pre_shared_keys = {},
    $encapsulate     = {},
    $iptunnels       = {},
    $remotes         = {},
    $log_level       = 'notify',
) {
    File {
        ensure => present,
        owner => 'root',
        group => 'root',
        mode  => '0644',
    }

    package { 'racoon':
        name   => $package_name,
        ensure => $version,
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
        subscribe  => File['/etc/racoon/racoon.conf', '/etc/racoon/psk.txt'],
    }
    case $restart {
        'restart': {
            Service['racoon'] {
                hasrestart => true
            }
        }
        'reload': {
            Service['racoon'] {
                restart    => "/usr/sbin/service ${service_name} ${restart}",
            }
        }
        false: {
            Service['racoon'] {
                restart    => '/bin/true',
            }
        }
        default: {
            fail("Invalid value for racoon::restart: ${restart}")
        }
    }
    exec { 'setkey restart':
        user        => 'root',
        refreshonly => true,
        subscribe   => [ File['/etc/ipsec-tools.conf'], Service['racoon'] ],
    }
    case $setkey_restart {
        'restart', 'start', 'reload': {
            # reload is not supported in Ubuntu yet
            Exec['setkey restart'] {
                command => "/usr/sbin/service setkey ${setkey_restart}"
            }
        }
        false: {
            Exec['setkey restart'] {
                command => '/bin/true'
            }
        }
        default: {
            fail("Invalid value for racoon::setkey_restart: ${setkey_restart}")
        }
    }

}
