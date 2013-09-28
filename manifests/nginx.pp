class owncloud::nginx (
  $hostname            = 'owncloud.local',
  $upload_max_filesize = '1000M',
  $php_fpm             = 'unix:/var/run/php5-fpm.sock',
  $ssl                 = false,
  $ssl_key             = '',
  $ssl_cert            = '',
  $access_log          = undef,
  $error_log           = undef,
) {
  $path = $owncloud::path
  $www_path = $owncloud::www_path
  $data_path = $owncloud::data_path

  $domain_log_name = regsubst($hostname, ' ', '_', 'G')
  $access_log_real = $access_log ? {
    undef   => "${nginx::params::nx_logdir}/${domain_log_name}.access.log",
    default => $access_log,
  }
  $error_log_real = $error_log ? {
    undef   => "${nginx::params::nx_logdir}/${domain_log_name}.error.log",
    default => $error_log,
  }

  $nginx_conf_dir = $nginx::params::nx_conf_dir
  $cert = regsubst($name,' ','_')
  if $ssl == true {
    $ssl_access_log = $access_log ? {
      undef   => "${nginx::params::nx_logdir}/ssl-${domain_log_name}.access.log",
      default => $access_log,
    }
    $ssl_error_log = $error_log ? {
      undef   => "${nginx::params::nx_logdir}/ssl-${domain_log_name}.error.log",
      default => $error_log,
    }

    ensure_resource('file', "${nginx::params::nx_conf_dir}/${cert}.crt", {
      owner  => $nginx::params::nx_daemon_user,
      mode   => '0444',
      source => $ssl_cert,
    })

    ensure_resource('file', "${nginx::params::nx_conf_dir}/${cert}.key", {
      owner  => $nginx::params::nx_daemon_user,
      mode   => '0440',
      source => $ssl_key,
    })
  }

  file { '/etc/nginx/conf.d/owncloud.conf':
    content => template('owncloud/nginx.conf.erb'),
    owner => 'root',
    group => 'root',
    notify => Service['nginx']
  }
}
