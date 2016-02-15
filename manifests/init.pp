# == Class: owncloud
#
# === Parameters
#
# [path] The path were owncloud should be installed to (default: /srv/owncloud)
# [user] The owncloud user (default: www-data)
# [group] The owncloud group (default: www-data)
# [db_type] The database's type
# [db_name] The database's name
# [db_user] The database's user
# [db_pass] The database's password
# [db_host] The database's host
# [db_prefix] The database's table prefix
# [admin_login] The admin's login name
# [admin_pass] The admin's password
#
# === Examples
#
#  class { 'owncloud':
#    path => "/srv/owncloud",
#    user => "www-data",
#  }
#
# === Authors
#
# Arthur Leonard Andersen <leoc.git@gmail.com>
#
# === Copyright
#
# See LICENSE file, Arthur Leonard Andersen (c) 2013
#
# Class:: owncloud
#
class owncloud (
  $path        = '/srv/owncloud',
  $user        = 'www-data',
  $group       = 'www-data',

  $db_type      = undef,
  $db_name      = undef,
  $db_user      = undef,
  $db_pass      = undef,
  $db_host      = undef,
  $db_prefix    = '',

  $admin_login  = undef,
  $admin_pass   = undef,
) {

  $archive_url = 'https://download.owncloud.org/community/owncloud-8.2.2.tar.bz2'
  $www_path = "${path}/www"
  $data_path = "${path}/data"

  ensure_packages(['bzip2', 'memcached', 'varnish'])

  exec { 'owncloud-purge-old':
    path    => '/bin:/usr/bin',
    onlyif  => "test -f ${www_path}/ARCHIVE_URL && grep -qv '${archive_url}' ${www_path}/ARCHIVE_URL",
    command => "bash -c 'rm -rf ${www_path}/*'",
    user    => $user,
  }

  file { [ $path, $www_path, $data_path ]:
    ensure  => 'directory',
    owner   => $user,
    require => Exec['owncloud-purge-old'],
  }

  exec { 'owncloud-download':
    path    => '/bin:/usr/bin',
    unless  => "test -f ${www_path}/index.php",
    creates => '/tmp/owncloud.tar.bz2',
    command => "bash -c 'wget -O/tmp/owncloud.tar.bz2 ${archive_url}'",
    require => File[$path],
    user    => $user,
  }

  exec { 'owncloud-extract':
    path    => '/bin:/usr/bin',
    unless  => "test -f ${www_path}/index.php",
    creates => '/tmp/owncloud',
    command => "bash -c 'cd /tmp; tar xfj /tmp/owncloud.tar.bz2'",
    require => [ Exec['owncloud-download'], Package['bzip2'] ],
    user    => $user,
  }

  exec { 'owncloud-copy':
    path    => '/bin:/usr/bin',
    creates => "${www_path}/index.php",
    command => "bash -c 'cp -rf /tmp/owncloud/* ${www_path}/'",
    require => Exec['owncloud-extract'],
    user    => $user,
  }

  file { "${www_path}/ARCHIVE_URL":
    content => $archive_url,
    owner   => $user,
    require => Exec['owncloud-copy'],
  }

  file { [ '/tmp/owncloud.tar.bz2', '/tmp/owncloud' ]:
    ensure  => absent,
    recurse => true,
    force   => true,
    require => Exec['owncloud-copy'],
  }

  file { "${www_path}/config/memcache.config.php":
    ensure  => present,
    owner   => $user,
    group   => $group,
    source  => 'puppet:///modules/owncloud/memcache.config.php',
    require => Exec['owncloud-copy']
  }

  if $db_type {
    file { "${www_path}/config/autoconfig.php":
      ensure  => present,
      owner   => $user,
      group   => $group,
      content => template('owncloud/autoconfig.php.erb'),
      require => Exec['owncloud-copy']
    }
  }

} # Class:: owncloud
