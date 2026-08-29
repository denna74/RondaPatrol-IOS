# Ronda Patrol iOS

iOS port of Ronda Patrol, built with Godot 4.6.

## iOS configuration

- Bundle identifier: `com.rondapatrol`
- Minimum iOS version: 14.0
- Orientation: landscape
- In-app purchases use OpenIAP / StoreKit 2.
- Rewarded ads use the Unity Ads iOS bridge under `ios/plugins/unity-ads`.

The App Store Connect consumable products are:

- `com.rondapatrol.instant_coins_1`
- `com.rondapatrol.instant_coins_2`
- `com.rondapatrol.instant_coins_3`

## Local export

Install Godot 4.6 with the iOS export templates, then export the `iOS` preset
to `build/ios/RondaPatrol.xcodeproj`. The Unity Ads native bridge and its
framework are built by `ios/plugins/unity-ads/build.sh` on macOS.

## TestFlight delivery

The GitHub Actions workflows in `.github/workflows` export the Xcode project,
build it with Fastlane, and upload the resulting IPA to TestFlight. Configure
the App Store Connect API key and signing certificate secrets before running
the workflow.
