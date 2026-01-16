# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"万剑归宗" (Wan Jian Gui Zong) is an iOS mobile game built with SpriteKit. It's a merge-style puzzle game with a cultivation/xianxia theme where players drag and merge flying swords on a hexagonal grid to achieve combos and ultimately trigger the "Ten Thousand Swords Return" ultimate ability.

## Build and Run Commands

### Running the Project
Open `wjgz.xcodeproj` in Xcode and use:
- **Run**: Cmd + R
- **Build**: Cmd + B
- **Recommended simulator**: iPhone 15 Pro or any iOS device

This is a standard iOS project with no external dependencies or build tools - all development is done through Xcode.

## High-Level Architecture

### Game Structure (SpriteKit-based)
The game uses a scene-based architecture typical of SpriteKit games:

**GameViewController.swift** → Entry point that configures and presents the GameScene
- Sets scene anchor point to (0.5, 0.5) for centered coordinate system
- Enables FPS and node count debugging displays

**GameScene.swift** → Main game logic controller (~650 lines)
- Manages three distinct layers: gridLayer (hexagonal tiles), swordLayer (sword entities), and uiLayer (score, energy bar, buttons)
- Uses axial coordinate system for hexagonal grid (q, r coordinates with radius 2 = 19 total hexagons)
- Grid data stored as dictionary mapping "q_r" strings to Sword nodes
- Core game loop: drag → swap/move → checkForMatches → merge → replenish

**Sword.swift** → Flying sword entity
- Visual representation with type-based coloring and Chinese character labels (凡/灵/仙)
- Stores grid position (q, r) and handles upgrade animations

**Constants.swift** → Game configuration
- Defines three sword types: fan (凡剑), ling (灵剑), xian (仙剑)
- Grid visual constants: tileRadius (35.0), gridSpacing (5.0)

### Hexagonal Grid System
The core spatial system uses **axial coordinates** (q, r):
- `hexToPixel(q:r:)` converts grid coordinates to screen positions
- `pixelToHex(point:)` converts touch locations to grid coordinates
- `hexRound(q:r:)` handles floating-point coordinate rounding
- `getNeighbors(q:r:)` returns 6 adjacent hexagon positions using direction vectors

This is critical for all spatial logic. When modifying movement or placement code, always work in grid coordinates first, then convert to pixel positions for rendering.

### Match and Merge System
Uses BFS flood-fill algorithm:
1. After any drag operation, `checkForMatches()` scans entire grid
2. `findMatches(startNode:)` performs BFS to find connected components of same-type swords
3. If 3+ swords match, they merge into next tier
4. Special abilities trigger based on merged sword type:
   - **ling (灵)** → `triggerLineClear()` clears entire row (same r coordinate)
   - **xian (仙)** → `triggerAreaClear()` clears neighboring hexagons
5. Empty slots are filled by `replenishSwords()` which spawns 1-3 new swords with weighted randomness (80% fan, 20% ling)

### Game State and Progression
- **Score (修为)**: Increments from matches and clears
- **Energy (能量)**: Fills toward 100 to unlock ultimate ability
- **Ultimate ability (万剑归宗)**: When energy is full, button appears; clicking removes 70% of swords randomly with screen flash effect
- **Game over**: Triggers when all 19 slots fill with no possible matches

## Key Design Patterns

### PRD-Driven Development
The `docs/万剑归宗prd.md` defines the complete product vision:
- **5-minute onboarding flow**: Players should experience 3 "satisfying moments" in first 5 minutes
- **MVP scope**: Intentionally limited to 4 modules (board, 3 sword types, 1 ultimate, 1 progression line)
- **"Not doing" list**: Explicitly defers world-building, characters, factions, story, leaderboards to future phases

When adding features, check if they align with MVP scope or should be deferred.

### Visual Feedback System
Every game action includes juice/polish:
- Merge → scale pulse + floating text label (剑意+1)
- Line clear → "剑气纵横!" text
- Area clear → "一剑开天!" text
- Ultimate → full-screen white flash + "万剑归宗!" large text with scale animation

When implementing new mechanics, always add corresponding visual feedback following this pattern: create floating SKLabelNode, animate with moveBy + fadeOut, then remove.

## Testing the Game

Currently no automated tests. Manual testing checklist:
1. **Drag mechanics**: Verify swords can be dragged to empty slots and swapped with other swords
2. **Match detection**: Create groups of 3+ same-type swords and verify they merge
3. **Special abilities**: Test ling sword line clear and xian sword area clear
4. **Energy system**: Verify energy bar fills and ultimate button appears at 100
5. **Ultimate ability**: Verify 70% clear and visual effects
6. **Game over**: Fill board completely and verify "剑道未成" overlay appears with restart button

## Chinese Text Labels
All in-game text is in Chinese:
- 万剑归宗 (Wan Jian Gui Zong) - Game title / Ultimate ability
- 修为 (Xiū Wéi) - Cultivation level / Score
- 剑道未成 (Jiàn Dào Wèi Chéng) - "The Way of the Sword is incomplete" / Game over message
- 再修一局 (Zài Xiū Yī Jú) - "Cultivate again" / Restart button

When adding UI elements, maintain Chinese text for thematic consistency unless specifically creating English localization.
