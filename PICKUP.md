# Pickup Prompt: Gun Control Project

## Current Status:
- **AAA FPS Controller**: Implemented with smooth movement, sprint, crouch, peaking, head bob, and landing impacts.
- **Global Point System**: `PointGrid.gd` and `PointNode.gd` are ready. They allow visual path building in the editor with cyan spheres and yellow lines.
- **Local Component Animator**: `LocalAnimator.gd` is ready for mechanical component animations (e.g., slides, triggers) using measurement-based offsets.
- **Cleanup**: Test assets (`TestGrid`, `Weapon.tscn`, `Weapon.gd`) have been removed from the main scenes, but the system scripts remain.

## Next Steps:
1.  **Integrate User Assets**: The user is creating 3D assets to replace the test blocks.
2.  **NPC Navigation**: Implement the `NpcPathfollower.gd` (already written) into a real NPC character that uses the `PointGrid`.
3.  **Weapon System**: Build a full weapon system using the `LocalAnimator` on the new 3D models.

## Reference Documents:
- `SYSTEMS_OVERVIEW.md`: Technical details on how the Point systems and the FPS controller work.
- `PLANNING.md`: Original project vision and architecture goals.

## Critical Settings:
- **Physics**: Godot Jolt is enabled.
- **Gravity**: 5x Up, 8x Down for AAA feel.
- **Jump**: Snap-to-ground and high velocity (12.0) implemented.
