# Feeding System

## Overview
Player can hold `E` near a power system to drain it over time.  
On completion, the system breaks and alerts nearby crew.

---

## Components

### player.gd
- Starts feeding on `E` (hold)
- Movement locked during feeding but camera still rotates
- Cancels if player (is noticed in future) releases input
- Small cooldown after cancel

### power_system.gd
- Shows `[E] Feed` when in range
- Hides prompt + shows progress while feeding
- On completion → `[BROKEN]` + alerts crew
- `fix_broken_system()` placeholder

### interaction_area.gd
- Detects nearby `power_system` nodes
- Tracks targets + provides closest one

### spring_camera_3D.gd
- Smooth follow camera
- 90° snap rotation (left/right)

---

## Inputs
- Movement: `move_*`
- Feed: `E`
- Camera: `rotate_left` / `rotate_right`

---

## TODO
- Cancel feedback (sound/FX)
- Feeding feedback (screen shake, etc.)
- System repair logic
- Visual effects on break
