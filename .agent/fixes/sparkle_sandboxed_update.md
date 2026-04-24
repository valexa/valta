# Sparkle Sandboxed Update Fix

**Commit:** `3c00529306b917fd1faaa56009c092b917acf43e`
**Title:** add sandboxed autoupdate entitlements

---

## Description of the Problem

When users on version 1.1 triggered "Check for Updates…" and Sparkle downloaded the v1.2
package, the installation failed with:

```
An error occurred while launching the installer. Please try again later.
```

Pulling the system log revealed the actual Sparkle error underneath:

```
(Sparkle) Failed to submit installer job
(Sparkle) If your application is sandboxed please follow steps at:
          https://sparkle-project.org/documentation/sandboxing/
(Sparkle) Error: Failed to gain authorization required to update target (code -60005)
(Sparkle) Error: An error occurred while launching the installer. Please try again later.
```

**Root cause:** The app is sandboxed (`com.apple.security.app-sandbox = true`). macOS Sandbox
prevents a sandboxed app from overwriting its own bundle in `/Applications` using the
traditional privileged-helper authorization method. Sparkle requires explicit configuration to
opt into its sandboxed XPC installer path instead. Without that configuration, Sparkle fell
back to the unsandboxed authorization method, which macOS blocked with the `-60005` error.

---

## How Sparkle Sandboxing Works (Sparkle 2.2+)

In Sparkle 2.2 and later, the XPC services (`Installer.xpc` and `Downloader.xpc`) are bundled
**inside** the Sparkle framework itself at:

```
valta.app/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/
```

They do **not** need to be added separately via Xcode's "Frameworks, Libraries, and Embedded
Content" panel. If the Sparkle framework is embedded in the app (which it is when using SPM
with `Embed & Sign`), the XPC services are already physically present.

However, Sparkle will not use them unless the app explicitly opts in via two configuration
keys. Without the opt-in, Sparkle falls back silently to the old non-sandboxed path.

---

## The Fix

### 1. `valta/Info.plist` — Enable InstallerLauncher Service

```xml
<key>SUEnableInstallerLauncherService</key>
<true/>
```

This tells Sparkle to use its bundled `InstallerLauncher.xpc` service for the update
installation, instead of the legacy privileged authorization path that the Sandbox blocks.

### 2. `valta/valta.entitlements` — Add Mach Lookup Exception

```xml
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>com.valexa.valta-spks</string>
    <string>com.valexa.valta-spki</string>
</array>
```

These are temporary sandbox exceptions that allow the sandboxed app process to communicate
with Sparkle's XPC helper services over Mach IPC. The suffixes `-spks` (Sparkle Status) and
`-spki` (Sparkle Installer) follow Sparkle's naming convention where the service name is
derived from the app's bundle identifier.

Without these, the app process cannot reach the XPC services even though they are bundled —
the Sandbox blocks the IPC channel at the kernel level.

---

## The v1.1 Catch-22

Version 1.1 was shipped **before** this fix was applied, meaning:
- v1.1 does not have `SUEnableInstallerLauncherService` in its Info.plist
- v1.1 does not have the mach-lookup entitlements
- v1.1's Sparkle will always fall back to the blocked non-sandboxed path

**Version 1.1 cannot self-update to 1.2.** This is a one-time catch-22 inherent to fixing
Sparkle sandboxing retroactively. Users on v1.1 must update manually by downloading v1.2
directly.

Any version from 1.2 onwards has the correct configuration and will update automatically.

---

## Appcast Strategy for v1.1 Users

The `sparkle:minimumAutoupdateVersion` appcast tag was briefly considered to gracefully degrade
the v1.1 update prompt (showing the update is available but requiring manual download instead
of crashing the installer). This was discussed but ultimately left out of the live appcast as
the preference was for users to just re-download manually.

---

## Key Lesson

When shipping a sandboxed macOS app with Sparkle via SPM:
1. The XPC services are embedded automatically with the framework — no manual embedding needed
2. You **must** set `SUEnableInstallerLauncherService = true` in `Info.plist`
3. You **must** add the `com.apple.security.temporary-exception.mach-lookup.global-name`
   entitlement with `<bundleid>-spks` and `<bundleid>-spki` values
4. Get this right in your first shipped build — there is no way to push this fix to users
   who already have a build that lacks it
