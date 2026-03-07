# SiteTalkie iOS

A construction safety communication app built on BLE mesh networking.

## Attribution

This project is a fork of [BitChat](https://github.com/permissionlesstech/bitchat) by permissionless tech, llc, published under the GNU General Public License v3.

SiteTalkie extends BitChat's BLE mesh protocol with construction-specific features including emergency first aid protocols, SOS alerts, location pins, snag tracking, bulletin boards, and integration with SiteNode relay hardware.

## License

This project is licensed under the GNU General Public License v3.0 — see the [LICENSE](LICENSE) file for details.

## What's Original to SiteTalkie

- 11 HSE-sourced Emergency First Aid protocols with CPR metronome
- Construction SOS system with 16 emergency types and handbook deep linking
- Location pins with geofencing (hazard and note types)
- Snag/defect reporting and tracking
- Bulletin board with acknowledgment tracking
- Trade badges for construction disciplines
- SiteNode BLE relay hardware integration
- Channel system (#site, #general, #defects, #deliveries)
- Equipment location display with offline cached photos
- Supabase backend integration
- BitChat Emergency Mode (switch to full BitChat client)
- Translation service for multi-language construction sites
- Amber construction theme and glove-friendly UI

## Upstream

The BLE mesh protocol code in `localPackages/` is unmodified from upstream BitChat and can be updated independently.

Upstream repository: https://github.com/permissionlesstech/bitchat

## Developer

Built by Gridmark Technologies Ltd
