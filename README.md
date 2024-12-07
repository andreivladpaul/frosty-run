# SkiGame

![Screenshot 2024-12-07 alle 15 38 36](https://github.com/user-attachments/assets/7105fa0e-e4fb-48ec-8cc5-5363681799d5)
![Screenshot 2024-12-07 alle 15 38 08](https://github.com/user-attachments/assets/af019644-9793-4ccd-8ec9-115e74a02220)


A dynamic iOS skiing game built with Swift and SpriteKit where players navigate a skier down a slope while avoiding obstacles.

## Description

SkiGame is an engaging mobile game where players control a skier descending a slope. The game features dynamic obstacle generation, increasing difficulty, and responsive touch controls.

## Features

- Intuitive touch controls for skier movement
- Dynamic obstacle generation (trees, rocks, poles, and other skiers)
- Progressive difficulty system
- Score tracking and high score system
- Smooth animations and sprite transitions
- Collision detection system

## Controls

- Touch the left side of the screen to move left
- Touch the right side of the screen to move right
- Release touch to return to center position

## Game Elements

### Player
- Front-facing skier when stationary
- Left/right turning animations during movement

### Obstacles
- Trees
- Rocks (stationary)
- Poles
- Other skiers

## Technical Details

- Built with Swift and SpriteKit
- Target Platform: iOS
- Minimum iOS Version: 18.1
- Device Support: iPhone and iPad

## Development

### Requirements
- Xcode 16.1 or later
- iOS 18.1 or later
- Swift 5.0

### Project Structure
- [GameScene.swift](cci:7://file:///Users/vlad/Desktop/SkiGame/SkiGame/GameScene.swift:0:0-0:0): Main game logic and scene management
- `ContentView.swift`: SwiftUI view container
- `SkiGameApp.swift`: App entry point
- Assets: Various game sprites and images

## Installation

1. Clone the repository
2. Open `SkiGame.xcodeproj` in Xcode
3. Build and run the project on your iOS device or simulator

## Game Mechanics

- The game starts with a "Start Game" button
- Obstacles are randomly generated as the player descends
- Score increases based on survival time and game speed
- Game over occurs upon collision with any obstacle
- High scores are saved locally

## Future Enhancements

- Power-ups and special abilities
- Multiple difficulty levels
- Achievement system
- Online leaderboards
- Additional obstacle types
- Sound effects and background music

## Credits

Created by Vlad
