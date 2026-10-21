# Domicile

Give your devices a home address: a Mac-hosted Wi-Fi network whose traffic exits through your VPN tunnel, invisible to the devices themselves.

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flaconicman%2Fdomicile%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/laconicman/domicile)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Flaconicman%2Fdomicile%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/laconicman/domicile)
[![Latest Tag](https://img.shields.io/github/v/tag/laconicman/domicile)](https://github.com/laconicman/domicile/tags)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE.txt)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/laconicman/domicile)

## Why

Some apps must see a home-country IP to work: banks, tax services, government messengers. Putting a VPN app on the device itself is detectable — and on iOS, Personal Hotspot does not pass the phone's VPN to tethered devices (Apple radar FB8257554). So the fix is upstream: a Mac acts as the gateway and the device sees nothing but Wi-Fi.

## How it works

```
 iPhone (USB tethering)
        │  uplink
        ▼
 ┌──────────────┐
 │     Mac      │──► utun (any VPN/VLESS client owns the default route)
 │              │
 │  domicile    │    DNS: resolver override on the uplink service
 │  + Internet  │    no pf rules — the tun stack proxies LAN flows
 │    Sharing   │
 └──────┬───────┘
        │  Wi-Fi AP (bridge100)
        ▼
   your devices — traffic exits through the tunnel
```

The supervisor waits for any `utun` to own the default route, drives Internet Sharing through `com.apple.nat.plist` directly, pins the uplink's DNS at a public resolver, and watches SCDynamicStore/CoreWLAN/signals as a single event stream. No external processes are spawned.

## Requirements

- macOS 13+
- administrator rights (`sudo` for `up`/`down`/`snapshot`)
- a VPN client that produces a `utun` interface (sing-box, Xray-based apps, WireGuard, ...)
- an uplink — an iPhone over USB, or any wired/tethered interface

## Install

```sh
swift build -c release --arch arm64 --arch x86_64
sudo install -m755 "$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/domicile" /usr/local/bin/
```

## One-time setup

System Settings → General → Sharing → Internet Sharing: pick the uplink source, check Wi-Fi, set the network name and WPA2/WPA3 password, turn it on once and verify a client gets internet. Then:

```sh
sudo domicile snapshot
```

and toggle the pane off — `domicile` drives it from then on. The same pane is also where the AP password lives; `up` only verifies it is stored.

## Usage

```sh
sudo domicile up        # start the gateway, wait for your VPN's tunnel
domicile status         # unprivileged health view
domicile status --probe # also measure the tunnel exit IP/country
sudo domicile down      # stop: sharing off, DNS restored, Wi-Fi power-cycled
```

`up` runs in the foreground and supervises; Ctrl-C stops it cleanly. For a Dock launcher, use Automator → Application → Run AppleScript with:

```
do script "sudo /usr/local/bin/domicile up"
```

## Status

Phase B — awaiting hardware validation; see the Roadmap in the rendered docs.

## Documentation

See the Design article in the rendered DocC (`swift package generate-documentation --target DomicileCore`, or <https://swiftpackageindex.com/laconicman/domicile/documentation/domicilecore> once the Swift Package Index indexes the package) for decisions, seams and migration notes — authoritative over code comments.

## Contributing

User-facing strings go through `String(localized:bundle:)`; after changing them run `Scripts/update-strings.sh` to regenerate the catalog.

## Origin

Domicile replaces a pair of shell scripts that did the same job by spawning `networksetup`, `ifconfig`, `route`, `pfctl`, `security`, `PlistBuddy` and `curl`. See Design decisions "No packet filter" and "In-process system APIs, no spawned tools" for why neither survived.

## License

Apache-2.0 — see LICENSE.txt.
