# Privacy Policy

**Effective date: March 2026**

## What SiteTalkie Is

SiteTalkie is an offline Bluetooth mesh messaging and site intelligence app built for construction sites. Messages travel phone-to-phone via Bluetooth Low Energy (BLE) mesh networking — no central server stores or relays your messages.

## Data Stored Locally on Your Device Only

The following data is created and stored entirely on your device. It is never sent to any external server.

- **Display name** — user-set, no account required
- **Messages** — encrypted, stored on-device, never sent to any server
- **Barometric altimeter readings** — used to determine relative floor level for proximity features, processed entirely on-device, never transmitted to any server
- **BLE proximity data** — used to discover nearby users and deliver location-pinned alerts, processed on-device only
- **Location pins** — hazard markers and notes are shared over the local BLE mesh to nearby devices only, not to any server
- **Snag reports** — shared over the local BLE mesh to nearby devices only, not to any server
- **Photos** — photos attached to pins, snags, or messages are shared over the local BLE mesh only, not uploaded to any server
- **GPS coordinates** — used for location pins, SOS alerts, and proximity features. Processed on-device and shared over the local BLE mesh only, not sent to any external server. Users can disable GPS sharing via Ghost Mode in Settings.

## Data We Collect (Only If You Choose To)

- **Email address** — only if you sign up for launch notifications or the waitlist
- **Bulletin acknowledgments** — if your site uses SiteNode hardware with a cloud dashboard, bulletin read receipts are synced to the site dashboard via Supabase
- **Site configuration data** — the app may download site configuration (site address, equipment locations) from Supabase for offline use in the Emergency Handbook. This is data coming TO your device, not collected FROM you.

## Data We Do NOT Collect

- **Contacts or phone book**
- **Phone number**
- **Message content** — end-to-end encrypted using Noise Protocol with X25519 key exchange and ChaCha20-Poly1305. We cannot read your messages even if we wanted to.
- **Browsing history**
- **Advertising identifiers**

## Bluetooth & Mesh Networking

SiteTalkie uses Bluetooth Low Energy to create a mesh network between nearby phones. Messages hop phone-to-phone (up to 7 hops) without internet, cellular, or Wi-Fi.

All messages are end-to-end encrypted by default. No central server is involved in message delivery. The mesh network is entirely local — your data stays on the devices around you, not in the cloud.

## GPS & Location Features

SiteTalkie uses GPS for location pins, SOS alerts with coordinates, and proximity features. GPS data is:

- Shared over the local BLE mesh only (not sent to any server)
- Used to calculate distance to nearby pins and peers
- Included in SOS alerts so responders can locate the emergency
- Never sent to any external server or third party

Users can disable GPS broadcasting at any time via Ghost Mode in Settings. This stops your location from being shared with other devices on the mesh.

## Barometric & Proximity Features

SiteTalkie uses your phone's built-in barometric altimeter to estimate your relative floor level. This data is used to deliver relevant hazard alerts and snag notifications when you are near a pinned location.

Floor level data is processed entirely on your device and is not transmitted to any external server. BLE proximity detection is used to determine when you are near other SiteTalkie users or location pins.

## Site Alerts & Safety Features

Health and safety alerts are delivered to ALL users — safety is never gated behind a paywall. The entire app is free.

Site Alert broadcasts (cardiac arrest, fall from height, fire, evacuation, medical emergency, and 11 other emergency types) are transmitted over the local BLE mesh only. The Emergency Handbook with 11 HSE-sourced first aid protocols is stored entirely on-device and works offline.

Snag workflow data (creation, assignment, completion) is shared over the local mesh and stored on participating devices.

## Third-Party Services

- **Cloudflare** — website hosting and DNS
- **Supabase** — site configuration sync and bulletin delivery for sites using SiteNode hardware. No user accounts required in the app.
- **Google Fonts** — loaded on the website only, not in the app

## Cookies (Website Only)

We use minimal essential cookies for website functionality. No tracking cookies. No advertising cookies. No third-party analytics cookies.

## Your Rights Under UK GDPR

- Right to access your personal data
- Right to correct inaccurate data
- Right to delete your data
- Right to data portability
- Right to withdraw consent at any time

To exercise these rights, contact hello@sitetalkie.com.

## Children

SiteTalkie is not intended for users under 16.

## Open Source

SiteTalkie is open source under the GNU General Public License v3 (GPLv3). Source code is available at:

- iOS: https://github.com/sitetalkie/sitetalkie-ios
- Android: https://github.com/sitetalkie/sitetalkie-android

## Changes to This Policy

We will update this page if our practices change. Material changes will be communicated via the app or email where possible.

## Contact

Email: hello@sitetalkie.com

Gridmark Technologies Ltd
