# Tech Debt

Numbered register. Each entry lists what it costs and the change that retires it. Code markers use `// TODO(TD-n):`.

## TD-1 — Process identity compares executable basenames

**Cost.** `Gateway.isOurProcess` compares the last path component of `proc_pidpath` output; a renamed or symlinked binary is a blind spot.

**Discharge.** Compare a stronger identity — e.g. the full resolved path or a Mach-O UUID — when the menu bar helper makes misidentification costly.

## TD-2 — Console writes stdout directly

**Cost.** `Console.emit` is a hardwired stdout/stderr + os.Logger sink; it blocks the XPC future, where output must travel to the app.

**Discharge.** Put output behind a reporter seam (protocol + injected sink) when the SMAppService helper lands.

## TD-3 — NetworkState opens a dynamic store per read

**Cost.** Every `linkActive`/`ipv4Addresses`/`globalDNSServers`/`primaryInterface` call creates a fresh `SCDynamicStore`.

**Discharge.** Share one store between `NetworkState` and `NetworkWatcher` when read volume makes it worth the bookkeeping.

## TD-4 — `bridge100` is an assumed constant

**Cost.** macOS names the sharing bridge `bridge100` on current releases; if that changes, the bridge-up wait and status line read the wrong interface.

**Discharge.** Discover the bridge interface from the dynamic store or NAT prefs when Apple renames it.

## TD-5 — NAT `Enabled` written as Int, read as Int or Bool

**Cost.** The writer stores `1`/`0` as Int while readers accept either Int or Bool — the schema is undocumented, so the shape it actually persists is inferred.

**Discharge.** Converge on the type the Sharing pane itself writes once a real plist confirms it.

## TD-6 — ArgumentParser help strings localized through the core bundle

**Cost.** Command `abstract`/`help` strings go through `L10n.bundle` because ArgumentParser has no localization hook of its own.

**Discharge.** Adopt ArgumentParser's native localization if upstream adds one.

## TD-7 — Keychain presence check relies on root's default search list

**Cost.** `APPassword.exists` runs a plain `SecItemCopyMatching` with no keychain argument; whether root's default search list includes System.keychain is unverified until the hardware run.

**Discharge.** If the check misses, target System.keychain explicitly (`kSecMatchSearchList` with a legacy `SecKeychain` reference (itself deprecated) or a documented successor).

## See Also

- <doc:Design>
- <doc:Roadmap>
