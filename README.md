# NMZ Lua Library

A collection of high-performance Lua scripts designed for environment diagnostics and client-side visualization enhancements. Formerly a private personal repository, this library has been transitioned to open source to support the developer community under strict public-use guidelines.

---

## Overview

This repository contains two core components:

1. **NewG.lua**: An optimized, feature-rich script providing advanced client-side features, including a custom user interface, aim assistance, sensory perception (ESP) overlays, hitbox adjustments, and weapon behavior modifiers.
2. **exec_test.lua**: A spoof-resistant diagnostic tool that comprehensively measures Unified Naming Convention (UNC) coverage and verifies environment integrity using actual function execution tests rather than simple global existence checks.

---

## Repository Shift: Personal to Open Source

This codebase was originally developed as a private project for personal research and development. It has now been released as a fully open-source project. This transition aims to:
- Provide developers with clean, robust references for screen-to-world projections, weapon hook patterns, and advanced memory referencing.
- Offer an objective, standardized environment capability scanner (`exec_test.lua`) to assess standard executor compatibility.

---

## Core Components

### 1. Enhancement Suite (`NewG.lua`)

A highly modular script featuring an integrated configuration panel and high-performance drawing systems.

* **Aim Assistance**: Support for standard Camera smoothing and VirtualInputManager/mousemoverel simulations, with configurable Field of View (FOV) circles, target selection prioritization (Head, Torso, HumanoidRootPart), and automatic target projection (prediction).
* **Sensory Perception (ESP)**: Highly responsive client-side outlines using native Highlight objects or legacy 2D bounding boxes using the Drawing API.
* **Weapon Modifications**: Direct function manipulation via `hookfunction` to safely override game-side weapon values (removing recoil, spread, and cycling animations).
* **Hitbox Extension**: Multiplies base collision geometries temporarily for improved target acquisition.
* **Utility Configurations**: Integrated anti-AFK systems, performance boosters, and customizable keybind controls.

### 2. Executor Diagnostic (`exec_test.lua`)

 A strict, spoof-resistant benchmark script designed to verify that environment functions are fully operational rather than simulated or empty stubs.

* **UNC Coverage Scanning**: Automatically tests the presence and structure of standard environment globals.
* **Spoof-Proof Testing (sUNC)**: Validates performance integrity for critical hooks and memory operations:
  * `hookfunction` and `hookmetamethod` hook integrity checks.
  * `cloneref` and `clonefunction` reference isolation.
  * `newcclosure` wrapper validation.
  * Metatable manipulation (`getrawmetatable`, `setreadonly`, `isreadonly`).

---

## License & Distribution Terms

This library is open-source software licensed under the **GNU General Public License v3.0 (GPL-3.0)**. A complete copy of the license is available in the [LICENSE.md](file:///c:/Users/HP/Desktop/lua/LICENSE.md) file.

By using, modifying, distributing, or referencing this codebase, you agree to the GPL-3.0 terms and the following primary tenets:

### 1. Mandatory Copyleft (Open-Source)
Any derivative work, modification, or project integrating portions of this codebase must remain 100% open-source under the same GPL-3.0 license. The modified source code must be made freely and publicly available to all users.

### 2. Absolute Keyless & Free Use
This software and any derived projects must never be placed behind paywalls, key systems, monetization gateways, advertising redirectors, or any restricted validation protocols. Access must remain completely direct and cost-free.

### 3. Attribution
Proper attribution to the original creators (NMZ Team) must be retained at all times within the source code comments and any relevant user interfaces.

---

## Getting Started

### Diagnostic Execution
Run `exec_test.lua` in your environment to output standard compatibility diagnostics:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/username/repo/main/exec_test.lua"))()
```

### Script Execution
Execute `NewG.lua` to load the interface and associated client enhancement modules:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/username/repo/main/NewG.lua"))()
```
