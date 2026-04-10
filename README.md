# Space Shooter Game 🚀

[![Build Status](https://github.com/dhruvpatel59/Space-Shooter-Guardian/actions/workflows/ci.yml/badge.svg)](https://github.com/dhruvpatel59/Space-Shooter-Guardian/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://apple.com/ios)

An adrenaline-pumping, high-octane space shooter game built for iOS using Swift and SpriteKit. Battle through endless waves of enemies, dodge asteroids, and upgrade your ship to survive the cosmic onslaught.

---

## 🎮 Features

- **Epic Boss Battles**: Face off against massive, multi-part bosses every 5 levels with unique radial attack patterns.
- **Pilot Authentication**: Persistent local storage for multiple pilots with high-score tracking and secure login.
- **Modern Space UI**: Immersive glassmorphism interface with parallax motion effects that react to device tilt.
- **Dynamic Gameplay**: Fast-paced action with procedural enemy spawning and level-based difficulty scaling.
- **Combat AI**: Enemies retaliate with their own laser systems, requiring tactical dodging and precision flight.
- **Power-up System**: Diverse strategic power-ups, including Shields and the high-output **Triple Shot**.
- **Object Pooling**: Highly optimized 60FPS performance using memory-efficient object reuse for all entities.
- **Juicy UX**: Advanced haptic feedback, combo-multiplier systems, and screen-shake effects for an arcade-pure experience.

---

## 📸 Screenshots & Demos

| Main Menu | Gameplay | Game Over |
| :---: | :---: | :---: |
| ![Main Menu](https://via.placeholder.com/200x400?text=Main+Menu) | ![Gameplay](https://via.placeholder.com/200x400?text=Gameplay+GIF) | ![Game Over](https://via.placeholder.com/200x400?text=Game+Over) |

> [!TIP]
> Check out the [Video Demo](https://youtube.com/link_to_your_video) to see the game in action!

---

## 🛠️ Installation

### Prerequisites
- macOS Sequoia (or latest)
- Xcode 15+
- iOS Device or Simulator (iOS 15.0+)

### Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/dhruvpatel59/Space-Shooter-Guardian.git
   cd Space-Shooter-Guardian
   ```
2. **Open the project:**
   ```bash
   open "Space Shooter Game.xcodeproj"
   ```
3. **Select your target** (iPhone Simulator or connected device) and press `Cmd + R` to run.

---

## 🏗️ Architecture

The project follows a clean **MVC-S** (Model-View-Controller-Scene) architecture specifically designed for SpriteKit games:

- **GameScene.swift**: The heart of the game logic, physics, and efficient object pooling.
- **GameViewController.swift**: Manages the transitions and game lifecycle.
- **Assets.xcassets**: Centralized management for textures and sound effects.

For a deeper dive, see [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📧 Contact

Dhruv Patel - [LinkedIn](https://www.linkedin.com/in/dhruvpatel59/)

Project Link: [https://github.com/dhruvpatel59/Space-Shooter-Game](https://github.com/dhruvpatel59/Space-Shooter-Guardian)

---

### Acknowledgments
- [SpriteKit Documentation](https://developer.apple.com/documentation/spritekit)
- [OpenGameArt.org](https://opengameart.org) (for assets)
- My cosmic inspiration ✨
