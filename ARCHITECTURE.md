# Project Architecture

## Overview
This Space Shooter game is built using **SpriteKit**, Apple's 2D game framework. The architecture focuses on high performance, low memory footprint, and maintainability.

## Core Components

### 1. Scene Management (`GameScene.swift`)
The central controller for the game world. It handles:
- **Physics**: Collision detection between bullets, enemies, and the player.
- **Update Loop**: `update(_:)` method handles frame-by-frame movements and spawning.
- **Input**: Touch handling for player ship movement.

### 2. State Management
The game flows through multiple states:
- `Loading`: Preparing assets and initializing the scene.
- `Playing`: The active gameplay loop.
- `GameOver`: Handled via UI overlays, allowing for restarts.

### 3. Shaders & Visuals
- **ShipShader.fsh**: Custom SKShafers used for ship shield effects or engine glows.
- **Emitter Nodes**: SpriteKit `.sks` files used for explosions and starfield backgrounds.

## Directory Structure
```text
Space Shooter Game/
├── Space Shooter Game/      # Source Code
│   ├── Assets.xcassets     # Textures and Images
│   ├── GameScene.swift     # Main Game Loop
│   └── ShipShader.fsh      # Custom Graphics Logic
├── Space Shooter Game.xcodeproj
└── README.md
```

## Performance Considerations
- **Draw Calls**: Minimized by using Texture Atlases (`.xcassets`).
- **Memory**: Managed via Object Pooling and proactive asset disposal.
- **Frame Rate**: Optimized for a consistent 60/120 FPS.
