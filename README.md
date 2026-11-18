# Hatch a Brainrot Egg

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/mitakripto/hatch-a-brainrot-egg/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/mitakripto/hatch-a-brainrot-egg/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A 3D Roblox brainrot game, built by an AI agent for make.fun's
[Make the best AI Roblox brainrot game](https://make.fun/bounty/roblox-brainrot-01) bounty ($1,000 in USDC).

Walk through a 3D hatchery world, hatch eggs on pedestals, and collect twelve absurd original
characters — from Sir Slurpsalot the noodle knight to Chrono Croissant, a time-travelling pastry.
Every brainrot you hatch moves onto your own base plot and earns coins every second. Spend coins
on rarer eggs, roll Golden (x3) and Rainbow (x8) mutations, rebirth for a permanent income
multiplier, and watch out for the Snatcher: a shadowy NPC that stalks unlocked bases and runs off
with your brainrots unless you scare it away. Other players can steal from your base too — unless
you hit the Lock button. Every few minutes an Egg Rush doubles your hatch luck and spawns a
Golden Egg.

## How to play

- Walk up to an egg pedestal and press **E** to hatch the egg.
- Hatched brainrots appear on your base plot and earn coins automatically.
- Press **E** near another player's brainrot to steal it (only while their base is unlocked).
- **Lock Base** locks your base for 60 seconds. **Rebirth** (10,000 coins) resets your money and
  brainrots for a permanent +50% income multiplier and unlocks the Void Egg.
- Touch or click the Snatcher to make it drop what it carries.

## Run it

```sh
rojo build default.project.json --output game.rbxl
```

Open `game.rbxl` in Roblox Studio and press Play. To hand the game in:

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Layout

- `src/server/` — the server: one state module (`GameState`) plus a service per system
  (hatching, bases, money, stealing, the Snatcher, events) and the procedural world builder.
- `src/shared/BrainrotData.luau` — the cast, rarity ladder, egg tiers and roll rules.
- `src/client/` — the HUD: money counter, egg prices, rarity guide, Lock and Rebirth buttons,
  and the Egg Rush banner.
- `game.rbxl` — the built place. `screenshots/` — captures of the game running in Studio.
- `PLAY.json` — the link to the published Public experience on Roblox.

---

<sub>Entered on [make.fun](https://make.fun/?ref=xavpy24p&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
