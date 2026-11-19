# Daybreak 🌅
> *"Every morning is a fresh start."*

[![Verify & Test](https://github.com/peter14l/daybreak-todo/actions/workflows/build_and_release.yml/badge.svg)](https://github.com/peter14l/daybreak-todo/actions/workflows/build_and_release.yml)
[![Release](https://img.shields.io/github/v/release/peter14l/daybreak-todo?color=orange&label=Release)](https://github.com/peter14l/daybreak-todo/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-amber.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter)](https://flutter.dev)

A modern, high-performance, local-first cross-platform task management application crafted with Flutter, Drift (SQLite), and Supabase. Engineered specifically for **Windows 11** and **Android (Material 3 Expressive)** with zero web-wrapper bloat.

---

## 🎯 Why Daybreak Was Built

Microsoft has announced the retirement of **Microsoft To Do on June 30, 2027**, transitioning enterprise customers to web-heavy Microsoft Planner while leaving millions of personal and power users stranded without an authentic, lightning-fast native desktop and mobile replacement.

Most modern task management alternatives have succumbed to:
- Sluggish, memory-hogging Electron wrappers that take seconds to launch.
- Aggressive subscription paywalls locking basic features like home-screen widgets and reminders behind $4–$8/month fees.
- Overdue red-badge guilt where uncompleted tasks pile up day after day, causing cognitive overload.

**Daybreak** restores the joy of task planning with sub-millisecond local SQLite speed, true native OS aesthetics, and a stress-free daily reset philosophy.

---

## ✨ How Daybreak Outshines Competitors

| Feature | Daybreak 🌅 | Microsoft To Do | Todoist | TickTick | Google Tasks |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Local-First Speed (SQLite)** | ✅ Sub-ms (Drift) | ❌ Cloud-dependent | ❌ Web-sync lag | ❌ Sync latency | ❌ Cloud-dependent |
| **Native Windows 11 UI** | ✅ Mica Alt & Fluent | ⚠️ Legacy UWP/Web | ❌ Electron bloat | ❌ Electron bloat | ❌ Web browser only |
| **Android Material 3 Expressive** | ✅ Dynamic Monet + M3E | ❌ Outdated M2 | ⚠️ Custom UI | ⚠️ Custom UI | ⚠️ Basic M3 |
| **True Midnight "My Day" Reset** | ✅ Never loses parent list | ⚠️ Rollover issues | ❌ Red overdue badges | ❌ Overdue pile-up | ❌ No My Day view |
| **Aesthetic Native Widgets** | ✅ 100% Free (4x3 & 4x1) | ⚠️ Basic | 🔒 Paid paywall | 🔒 Paid paywall | ⚠️ Minimal |
| **Windows Compact Glance Mode** | ✅ 360x540 Always-on-top | ❌ None | ❌ None | 🔒 Mini window paid | ❌ None |
| **1-Click MS To Do Migration** | ✅ Graph API & JSON | — | ⚠️ Manual CSV | ⚠️ Partial CSV | ❌ None |
| **Guest Mode (No Sign-In Req.)** | ✅ Instant access | ❌ Microsoft account | ❌ Mandatory signup | ❌ Mandatory signup | ❌ Google account |

---

## 🚀 Key Architectural Pillars

### 1. Local-First Speed + Cloud Sync
- Built on **Drift (Type-safe SQLite)** with background thread query execution.
- Instant, sub-millisecond local reads and mutations with zero loading spinners or network blockers.
- Full offline resilience with an automated `SyncOutbox` queue.
- Backed by **Supabase** for real-time WebSocket synchronization across devices with Last-Write-Wins (LWW) conflict resolution.

### 2. True Native OS Design (Zero Electron Bloat)
- **Windows 11:** Rendered with native `Mica Alt` (`WindowEffect.tabbed`) surface transparency, acrylic fallback, frameless title bar with native drag-to-move areas, caption controls, and keyboard navigation.
- **Android:** Designed around **Material 3 Expressive (M3E)**, supporting Android 12+ Wallpaper Monet dynamic palettes with a sunrise amber seed fallback, spring-physics transitions, squircle task cards (`20dp` border radius), and tactile haptics.

### 3. True "My Day" Daily Reset
- Start every morning with a clean slate.
- Tasks pinned to "My Day" automatically clear their daily tag at midnight without ever disappearing from their parent list, banishing the anxiety of accumulating overdue red badges.

### 4. Aesthetic Glanceable Widgets
- **Android Home-Screen Widgets:**
  - *My Day Interactive Checklist (`4x3`)*: Dynamic rounded container (`24dp` radius) with date, greeting, progress pill, and direct checkbox toggling from the home screen.
  - *Daybreak Focus Pill (`4x1`)*: Ultra-clean horizontal pill presenting your next priority task and remaining count badge.
- **Windows Compact Glance Mode (`Ctrl+M`):**
  - Resizes the application to a distraction-free `360x540` mini-window with optional "Always on Top" pinning and Mica Alt transparency.

### 5. Microsoft To Do Direct Migration
- Authenticate with your Microsoft Account to pull lists, tasks, notes, due dates, reminders, and recurrence rules directly via the Microsoft Graph API (`/me/todo/lists`).
- Alternatively, import existing local JSON or CSV archive backups with one click.

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Ctrl + N` | Create a new task in active list |
| `Ctrl + F` | Global instant search |
| `Ctrl + M` | Toggle Windows Compact Glance mini-mode |
| `Ctrl + D` | Add / remove selected task from My Day |
| `Delete` | Soft-delete selected task |
| `Ctrl + ,` | Open Settings & Migration |

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart 3.3+)
- **State Management:** [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- **Local Persistence:** [Drift](https://pub.dev/packages/drift) (SQLite) + [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs)
- **Cloud Backend:** [Supabase](https://pub.dev/packages/supabase_flutter)
- **Desktop UI:** [fluent_ui](https://pub.dev/packages/fluent_ui), [flutter_acrylic](https://pub.dev/packages/flutter_acrylic), [window_manager](https://pub.dev/packages/window_manager)
- **Mobile UI:** [dynamic_color](https://pub.dev/packages/dynamic_color) (Material You Monet)
- **Home Screen Widgets:** [home_widget](https://pub.dev/packages/home_widget) + Kotlin `AppWidgetProvider`
- **CI / CD:** GitHub Actions automated matrix build for Windows x64 and signed Android release APKs

---

## 📦 Building from Source (CI / GitHub Actions)

Daybreak utilizes GitHub Actions for continuous integration, testing, code generation, and release packaging:
- **`verify-and-test`**: Code formatting (`dart format`), static analysis (`flutter analyze`), and unit testing (`flutter test --coverage`).
- **`build-android`**: Generates app launcher icons, decodes release keystore, and compiles signed split-per-ABI release APKs (`armeabi-v7a`, `arm64-v8a`, `x86_64`).
- **`build-windows`**: Builds optimized Windows 64-bit release executable and packages `Daybreak-Windows-x64.zip`.
- **`release`**: Automatically packages GitHub Releases with all binaries attached.

---

## 📄 License

Daybreak is licensed under the [MIT License](LICENSE).
