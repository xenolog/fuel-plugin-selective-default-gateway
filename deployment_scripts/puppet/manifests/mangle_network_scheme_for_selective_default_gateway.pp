# Manifest that creates hiera config overrride
notice('MODULAR: selective_default_gateway/create_hiera_config.pp')

# Initial constants
$plugin_name     = 'selective_default_gateway'
$plugin_settings = hiera_hash("${plugin_name}", {})
$network_scheme  = hiera_hash("network_scheme", {})

# Mangle network_scheme for setup new gateway
if $plugin_settings['metadata']['enabled'] {
  if $plugin_settings['network_name'] == 'another' {
    $network_name = $plugin_settings['another_network_name']
  } else {
    $network_name = $plugin_settings['network_name']
  }
  $mangled_network_scheme = mangle_network_scheme_for_selective_default_gateway(
    $network_scheme,
    $network_name
  )
  file {"/etc/hiera/plugins/${plugin_name}.yaml":
    ensure  => file,
    content => inline_template(
      "<%= @mangled_network_scheme %>"
    )
  }
}
# vim: set ts=2 sw=2 et :