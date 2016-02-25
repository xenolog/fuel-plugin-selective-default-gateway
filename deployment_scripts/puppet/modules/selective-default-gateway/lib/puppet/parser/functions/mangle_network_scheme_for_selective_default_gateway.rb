require 'yaml'

Puppet::Parser::Functions::newfunction( :mangle_network_scheme_for_selective_default_gateway,
                                        :type => :rvalue, :doc => <<-EOS
    This function get network_scheme and network_name and returns mangled
    network scheme with changed default gateway.
    EOS
  ) do |argv|

    def bridge_name_max_len
      15
    end

    def nailgun_hardcoded_bridges
      {
        'fuelweb_admin' => 'br-fw-admin',
        'management'    => 'br-mgmt',
        'public'        => 'br-ex',
        'private'       => 'br-mesh'
      }
    end

    def get_endpoint_name_for_network(net_name)
      ep_name = nailgun_hardcoded_bridges[net_name]
      return ep_name if !ep_name.nil?
      ep_name = (net_name =~ /^br-/  ?  net_name  :  "br-#{net_name.to_s.downcase}")
      return ep_name[0...bridge_name_max_len]
    end

    if argv.size != 2
      raise(
        Puppet::ParseError,
        "mangle_network_scheme_for_selective_default_gateway(): Wrong number of arguments. Should be two."
      )
    end
    if !argv[0].is_a?(Hash) or argv[0].empty?
      raise(
        Puppet::ParseError,
        "mangle_network_scheme_for_selective_default_gateway(): Wrong network_scheme. Should be non-empty Hash."
      )
    end
    if argv[0]['version'].to_s.to_f < 1.1
      raise(
        Puppet::ParseError,
        "mangle_network_scheme_for_selective_default_gateway(): You network_scheme hash has wrong format.\nThis parser can work with v1.1 format, please convert you config."
      )
    end
    if !argv[1].is_a?(String)
      raise(
        Puppet::ParseError,
        "mangle_network_scheme_for_selective_default_gateway(): Wrong target endpoint name. Should be String."
      )
    end

    org_network_scheme = argv[0]
    target_network     = argv[1]
    network_scheme     = {}.merge!(org_network_scheme)
    admin_network_name = 'fuelweb_admin'

    # calculate name of endpoint from
    target_endpoint = get_endpoint_name_for_network(target_network)

    # get backup route through admin network
    admin_endpoint = network_scheme['endpoints'][nailgun_hardcoded_bridges['fuelweb_admin']]
    if !admin_endpoint.is_a?(Hash) or admin_endpoint.fetch('vendor_specific', {}).fetch('provider_gateway', nil).nil?
      raise(
        Puppet::ParseError,
        "mangle_network_scheme_for_selective_default_gateway(): Admin network has no information about his own gateway."
      )
    end
    backup_gateway = admin_endpoint['vendor_specific']['provider_gateway']

    # mangle network_scheme
    network_scheme['endpoints'] = {}
    need_backup = true
    org_network_scheme['endpoints'].each do |ep_n, ep_data|
      if ep_n == target_endpoint
        # gateway should be here
        new_gateway = ep_data.fetch('vendor_specific', {}).fetch('provider_gateway', nil)
        if !new_gateway.nil?
          need_backup = false
          ep_data['gateway'] = new_gateway
          ep_data['gateway_metric'] = 0 if ep_data['gateway_metric']
        end
      else
        # remove gateway
        if 0 == ep_data.fetch('gateway_metric', 0)
          # remove only high-priority default gateway
          ep_data['gateway'] = '' if ep_data['gateway']
        end
      end
      network_scheme['endpoints'][ep_n] = ep_data
    end

    if need_backup
      network_scheme['endpoints'][nailgun_hardcoded_bridges['fuelweb_admin']]['gateway'] = backup_gateway
      network_scheme['endpoints'][nailgun_hardcoded_bridges['fuelweb_admin']]['gateway_metric'] = 0 if network_scheme['endpoints'][nailgun_hardcoded_bridges['fuelweb_admin']]['gateway_metric']
    end

    return { 'network_scheme' => network_scheme }.to_yaml() + "\n"
end
# vim: set ts=2 sw=2 et :