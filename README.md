fuel-plugin-selective-default-gateway
=====================================

**Table of Contents**

  * [Purpose](#purpose)
  * [Compatibility](#compatibility)
  * [Configuration](#configuration)
  * [How it works](#how-it-works)

## Purpose
The main purpose of this plugin is to provide ability to define network,
which should be used as network for default route.

## Compatibility

| Plugin version | Fuel version |
| -------------- | ------------ |
| 9.x.x          | Fuel-9.x     |

## Configuration
Plugin settings are available on Environment -> Networks -> Other page. Some important notes:
* Networks, which carry default route function should be configured with
  gateway defined.
* Admin network will be used if choosed network gas no default gateway
* endpoints in the network_scheme should contain vendor_specific section with
  provider_gateway field, that specify ability of route external traffic through this network.

Be carefully, if you move default route from Public network, traffic from and to VIPs will be non-symmetrical. You network topology should should handle such situation.

## How it works
General workflow
* It change default gateway, given from Nailgun, to provider_gateway from the
  vendor_specific section of endpoint.
