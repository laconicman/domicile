# Roadmap

Where Domicile is going, in priority order.

## Now

Hardware validation of phase B. The four open hypotheses:

- no-NAT forwarding of bridge clients through the tunnel,
- the resolver path for sharing clients,
- the keychain item presence created by the Sharing pane,
- the DNS override applied as root.

## Next

Phase C — optional sing-box supervision: `Process` termination as an event, restart with backoff. An `init` command that generates a sing-box config from a `vless://` link, including `sniff` + `hijack-dns` rules and a `direct`-detoured DNS server.

## Later

Menu bar app via an SMAppService privileged helper over XPC. Russian localization. launchd persistence. A Homebrew formula.

## See Also

- <doc:Design>
- <doc:TechDebt>
