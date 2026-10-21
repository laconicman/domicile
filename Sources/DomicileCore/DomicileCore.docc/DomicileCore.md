# ``DomicileCore``

A Mac-hosted Wi-Fi gateway that routes its clients' traffic through whichever VPN tunnel owns the Mac's default route.

## Overview

Domicile turns a Mac into a gateway: devices join the Wi-Fi network that macOS Internet Sharing hosts, and their traffic exits through any VPN tunnel (a `utun` interface) that owns the default route — sing-box, Xray, or any other client. The package spawns no external processes; everything runs on SystemConfiguration, CoreWLAN, the PF_ROUTE socket, Security, and URLSession.

## Topics

### Project Direction

- <doc:Design>
- <doc:Roadmap>
- <doc:TechDebt>

### Essentials

- ``Gateway``
- ``EventHub``
- ``NetworkState``
- ``InternetSharing``
- ``DNSOverride``
