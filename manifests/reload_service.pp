# == Class consul::reload_service
#
# This class is meant to be called from certain
# configuration changes that support reload.
#
# https://www.consul.io/docs/agent/options.html#reloadable-configuration
#
class consul::reload_service {

  # Don't attempt to reload if we're not supposed to be running.
  # This can happen during pre-provisioning of a node.
  if $consul::manage_service == true and $consul::service_ensure == 'running' {

    # Make sure we don't try to connect to 0.0.0.0, use 127.0.0.1 instead
    # This can happen if the consul agent RPC port is bound to 0.0.0.0
    if $consul::http_addr == '0.0.0.0' {
      $http_addr = '127.0.0.1'
    } else {
      $http_addr = $consul::http_addr
    }

    # The reload service should connect to http if possible (http port different from -1)
    if $consul::http_port != -1 {
      $reload_options = "-http-addr=${http_addr}:${consul::http_port}"
    }
    elsif $consul::verify_incoming  { # in case incoming connections are verified correct certificate files should be used
      $reload_options = "-http-addr=https://localhost:${consul::https_port} -client-cert=${consul::cert_file} -client-key=${consul::key_file}"
    }
    else {
      $reload_options = "-http-addr=https://localhost:${consul::https_port}}"
    }


    case $consul::install_method {
      'docker': { $command = "docker exec consul consul reload  ${reload_options}"}
      default: { $command = "consul reload ${reload_options}"}
    }

    exec { 'reload consul service':
      path        => [$consul::bin_dir,'/bin','/usr/bin'],
      environment => [ 'CONSUL_HTTP_SSL_VERIFY=false',],
      command     => $command,
      refreshonly => true,
      tries       => 3,
    }
  }
}
