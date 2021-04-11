# @summary
#   Defines wireguard tunnel interfaces
# @param private_key
#   Private key for data encryption
# @param listen_port
#   The port to listen
# @param ensure
#   State of the interface
# @param address
#   List of IP (v4 or v6) addresses (optionally with CIDR masks) to
#   be assigned to the interface.
# @param mtu
#   Set MTU for the wireguard interface
# @param preup
#   List of commands to run before the interface is brought up
# @param postup
#   List of commands to run after the interface is brought up
# @param predown
#   List of commands to run before the interface is taken down
# @param postup
#   List of commands to run after the interface is taken down
# @param peers
#   List of peers for wireguard interface
# @param dns
#   List of IP (v4 or v6) addresses of DNS servers to use
# @param saveconfig
#    save current state of the interface upon shutdown
# @param config_dir
#   Path to wireguard configuration files
define wireguard::interface (
  String                          $private_key,
  Integer[1,65535]                $listen_port,
  Enum['present','absent']        $ensure   = 'present',
  Optional[Variant[Array,String]] $address  = undef,
  Optional[Integer[1,9202]]       $mtu      = undef,
  Optional[Enum['on','off']]      $table    = undef,
  Optional[Variant[Array,String]] $preup    = undef,
  Optional[Variant[Array,String]] $postup   = undef,
  Optional[Variant[Array,String]] $predown  = undef,
  Optional[Variant[Array,String]] $postdown = undef,
  Optional[Array[Struct[
    {
      'PublicKey'           => String,
      'AllowedIPs'          => Optional[String],
      'Endpoint'            => Optional[String],
      'PersistentKeepalive' => Optional[Integer],
      'PresharedKey'        => Optional[String],
      'Comment'             => Optional[String],
    }
  ]]]                   $peers        = [],
  Optional[String]      $dns          = undef,
  Boolean               $saveconfig   = false,
  Stdlib::Absolutepath  $config_dir   = '/etc/wireguard',
) {

  case $ensure {
    default, 'present': {
      file {"${config_dir}/${name}.conf":
        ensure    => present,
        mode      => '0600',
        owner     => 'root',
        group     => 'root',
        content   => template("${module_name}/interface.conf.erb"),
        notify    => Exec["wg-quick-${name}"],
      }
      Exec {"wg-quick-${name}":
       command => "/usr/bin/wg-quick up ${name}",
       refresh => "/usr/bin/wg-quick down ${name} && /usr/bin/wg-quick up ${name}",
       unless  => "/usr/bin/wg | grep ${name}",
       require => File["${config_dir}/${name}.conf"],
      }
    }
    'absent': {
      Exec {"wg-quick down ${name}":
        command => "/usr/bin/wg-quick down ${name}",
        unless  => "/bin/test ! -f ${config_dir}/${name}.conf",
      } ~>
      file {"${config_dir}/${name}.conf":
        ensure    => absent,
      }
    }
  }
}
