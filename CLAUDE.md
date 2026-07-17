# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rogue Dungeon — a multiplayer roguelike dungeon crawler. The repo is a monorepo with three main parts:

- **godot-game/** — Godot 4.6 client (GDScript), uses Jolt Physics, GodotSteam addon
- **be/** — Go backend (Gin + pgx/PostgreSQL), handles auth, runs, inventory, commerce, risk
- **scripts/** + **blender_convert.js** — Node.js asset pipeline (War3 model → glTF → Godot)

## Build & Run

### Backend (Go)

```bash
cd be
go build ./cmd/api        # API server (listens :8080)
go build ./cmd/worker     # Background reward job processor
go test ./...             # Run all tests

# Run without Postgres (in-memory repos):
go run ./cmd/api

# Run with Postgres:
DATABASE_URL="postgres://..." go run ./cmd/api
# Auto-migration runs on startup unless AUTO_MIGRATE=false
```

Environment variables: `DATABASE_URL`, `APP_JWT_SECRET`, `STEAM_WEB_API_KEY`, `STEAM_APP_ID`, `ADMIN_API_TOKEN`

### Godot Client

Open `godot-game/project.godot` in Godot 4.6 editor. Network mode is configured via `godot-game/net_transport.cfg` (enet or steam relay). PowerShell launch scripts in `godot-game/run_*.ps1` for dual-instance testing.

### Asset Pipeline (Node.js)

```bash
npm install               # root package.json — gltf-transform, war3-model, pngjs
node blender_convert.js   # War3 BLP/MDX → PNG/glTF conversion
node scripts/batch_convert_bosses.js
```

## Architecture

### Backend (`be/`)

Standard Go layout: `cmd/` entrypoints, `internal/` for all business logic.

- **bootstrap/** — DI wiring, router setup, middleware (JWT auth, admin token, request ID)
- **modules/** — Domain modules, each with handler/service/repository/model:
  - `run` — Game run lifecycle (start, heartbeat, finish, host-migration, reconnect, anti-cheat, reward jobs)
  - `auth` — Steam login, JWT token management
  - `inventory`, `commerce`, `player` — Player progression and store
  - `risk`, `audit` — Anti-cheat flagging and admin audit logs
- **platform/** — Infrastructure adapters (postgres pool, JWT, migrations)
- **migrations/** — Numbered SQL migrations (auto-applied on startup)

All modules support dual backends: PostgreSQL for production, in-memory for local dev/tests.

### Godot Client (`godot-game/`)

Flat file structure at project root. Key architectural patterns:

- **Network layer** — `net_session_controller.gd` orchestrates transport (ENet direct / Steam SDR / Steam lobby). Delegates to service scripts: `host_sync_flow_service.gd`, `client_sync_flow_service.gd`, `snapshot_serialization_service.gd`, `observe_sync_service.gd`
- **Combat** — `hero_controller.gd` (player hero with RPG stats, skills, flash/haste), `enemy_ai.gd` (boss AI with skills, chase, network authority), `combat_scene_utils.gd` (damage popups, collision helpers)
- **Scene flow** — `scene_flow_controller.gd` manages floor progression (21 floors), shop, boss gates, battle fences, camera
- **Equipment** — `equipment_action_service.gd`, `equipment_authority_service.gd`, `equipment_effects_service.gd`, `equipment_runtime_helper.gd`
- **Visual layer** — 2D sprites with 3D collision (see `placeholders/` scenes). `hero_sprite_8dir.gd`, `prop_sprite_2d.gd`
- **Summoned units** — `summoned_unit_manager.gd`, visual scenes in `summons/`

Network sync uses snapshot-based replication: host collects state → serializes → broadcasts; clients interpolate remote avatars.

### Asset Pipeline

Converts Warcraft 3 assets (BLP textures, MDX models) to Godot-compatible formats (PNG, glTF). Output goes to `outputs/`. Uses `tools/mpqcli.exe` for MPQ archive extraction.

## Conventions

- GDScript files use `snake_case` naming, service-oriented decomposition (one responsibility per `*_service.gd`)
- Backend tests use table-driven style with in-memory repositories (no external deps needed)
- Network config is data-driven via `net_transport.cfg` — avoid hardcoding transport assumptions
- RPG stats follow DotA-style attribute system (strength/agility/intelligence with growth per level)
