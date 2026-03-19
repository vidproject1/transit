# Project: Gun Control - Systems Overview & AI Reference

This document provides a technical breakdown of the custom systems developed for this Godot 4.6 (Forward Plus) project. It is intended as a reference for future AI sessions and for manual developers to ensure consistency and architectural integrity.

---

## 1. The Global Point System (`PointGrid.gd` & `PointNode.gd`)

**Purpose**: To provide a visually editable, numbered navigation and pathing system in the 3D viewport without the overhead of complex NavMesh logic for every interaction.

### Architecture:
*   **`PointGrid` (Node3D)**: A container node with a `@tool` script that manages a collection of `PointNode` children.
    *   **Features**:
        *   **Automatic Sorting**: Children are sorted by their name (e.g., "1", "2", "3") to define a chronological path.
        *   **Viewport Lines**: Uses an `ImmediateMesh` to draw lines between points in the 3D editor (not at runtime).
*   **`PointNode` (Node3D)**: A single point in the grid.
    *   **Features**:
        *   **Visual Numbering**: Automatically creates a `Label3D` child in the editor to display its node name.
        *   **Billboard & Depth**: The labels are billboarded (always face the camera) and ignore depth (always visible through geometry).

### How to Use:
1.  **Create the Grid**: Create a `Node3D` and attach `PointGrid.gd`.
2.  **Add Points**: Add `Node3D` children and attach `PointNode.gd`.
3.  **Define Order**: Rename children to integers ("1", "2", "3") to define the path.
4.  **Edit Visually**: Drag the cyan spheres in the 3D viewport. The path lines update instantly.

### How to Attach to an NPC:
1.  **Create your NPC**: (e.g., a `CharacterBody3D`).
2.  **Attach a Script**: Use `NpcPathfollower.gd` or similar.
3.  **Assign the Grid**: In the Inspector, set the `Point Grid Path` to your `PointGrid` node.
4.  **How it works**:
    *   The NPC calls `grid.get_sorted_points()` on `_ready`.
    *   It moves toward the first point (`points[0]`).
    *   When it arrives within the `arrival_threshold`, it switches to the next point index.
    *   This allows you to draw any path in the editor and have an NPC follow it immediately.


---

## 2. The Local Component Animator (`LocalAnimator.gd`)

**Purpose**: To provide precise, measurement-driven animation for mechanical weapon components (e.g., slides, triggers, bolts) using local offsets instead of traditional animation files.

### Architecture:
*   **`LocalAnimator` (Node3D)**: A `@tool` script attached to a moving component.
*   **Key Properties**:
    *   **`points` (Array[Vector3])**: A list of local offsets relative to the node's initial position.
        *   *Point 0* is usually `(0, 0, 0)` (Neutral/Forward).
        *   *Point 1* is usually the "Back" position (e.g., `(0, 0, 0.07)` for 7cm/70mm back).
    *   **`transition_speed` (float)**: Controls the `lerp` speed between points.
    *   **`current_point_index` (int)**: The index of the point the component is currently moving toward.
*   **Logic**:
    *   Uses `position.lerp()` in `_process` to smoothly move the component toward its `target_position` based on the selected index.

### How to Use:
1.  Attach `LocalAnimator.gd` to a child node (e.g., the "Slide" of a gun).
2.  In the Inspector, add `Vector3` offsets to the `points` array.
3.  Use `play_sequence([1, 0])` in code to perform a mechanical action (like cocking).

---

## 3. The AAA FPS Controller (`Player.gd`)

**Purpose**: A highly polished, responsive first-person character controller designed for a "AAA" feel with extensive Inspector controls.

### Key Features:
*   **Momentum & Friction**: Uses `lerp` and `move_toward` for smooth acceleration and stops.
*   **Weighted Gravity**: Different gravity scales for rising vs. falling (e.g., 5x up, 8x down) to eliminate "floatiness."
*   **Procedural Effects**:
    *   **Head Bob**: Sine/Cosine waves driven by actual player velocity.
    *   **Landing Impact**: Camera "dips" upon hitting the floor after a fall.
    *   **Peaking (Q/E)**: Smooth camera tilt and X-offset.
    *   **Dynamic FOV**: FOV increases during sprinting.
*   **Editor-First**: Every speed, sensitivity, height, and multiplier is exposed to the Inspector for non-code tuning.

### Hierarchy Requirement:
*   `CharacterBody3D` (Player)
    *   `CollisionShape3D` (Capsule)
    *   `Node3D` (Neck)
        *   `Camera3D` (Camera)
            *   `Weapon` (Weapon Instance)

---

## Technical Constraints & Standards:
1.  **Physics Engine**: Godot Jolt is mandatory for all 3D physics.
2.  **Tool Scripts**: Use `@tool` for all systems to ensure viewport feedback.
3.  **Units**: All distances are in meters (Godot default). For small parts, use fractions (e.g., `0.007` for 7mm).
4.  **Runtime Minimization**: Maximize pre-calculation and editor-side setup. Use signals or event-driven logic instead of heavy `_process` calculations where possible.
