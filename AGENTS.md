# Core Rules

## Confirmation First, Don't Create Assumptions
Always confirm understanding before acting. Ask when unsure. Don't assume intent, context, or root cause. Verify before fixing.

## iOS-Specific Notes

- This project targets iOS using Godot 4.7.
- **Godot 4.7 is required for the force-quit life penalty.** Godot 4.6.x iOS never delivers `NOTIFICATION_APPLICATION_PAUSED`/`RESUMED`/`FOCUS_IN`/`FOCUS_OUT` (upstream bug #115936, SwiftUI lifecycle migration; fixed in 4.7 via PR #116395, no 4.6 backport). `Gameplay.gd` `_notification()` sets/clears the `pending_quit_penalty` flag on PAUSED/RESUMED — on 4.6 those never fired on iOS, so the penalty never applied. Do NOT downgrade below 4.7 or this regresses.
