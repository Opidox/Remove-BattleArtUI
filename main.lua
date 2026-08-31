-- Gen1 3D Battle UI Toggle
--
-- Small, dependency-light compatibility mod.
-- It does not render anything itself. It only claims native battle UI
-- presentation surfaces from compatible battle UI providers when the
-- corresponding option is enabled.
--
-- Supported providers:
--   * Battle Art Voxel Fork
--   * Stadium 2 Importer

local mod = ...

local BATTLE_ART_SUPPRESS_HOOK = "battle.presentation.suppress_native.v1"
local BATTLE_ART_ID = "BATTLE_ART_VOXEL_FORK"

local function optionEnabled(key)
  return mod.options:get(key) == true
end

mod.options:define({
  {
    key = "hide3dBattleUi",
    label = "HIDE BATTLE ART 3D UI",
    type = "toggle",
    default = true,
    description = "Hide Battle Art Voxel's native 3D battle HUD, text and Pokemon information panels while keeping the 3D battle scene intact.",
  },
  {
    key = "hideStadium2BattleUi",
    label = "HIDE STADIUM 2 BATTLE UI",
    type = "toggle",
    default = true,
    description = "Hide Stadium 2 Importer's native battle HUD and lower battle UI while keeping its 3D battle scene, Pokemon, camera and animations intact.",
  },
})

----------------------------------------------------------------
-- Battle Art Voxel Fork
--
-- Battle Art exposes an explicit presentation-ownership contract.
-- Claim only its native UI surfaces; never touch the battle scene.
----------------------------------------------------------------

mod.hooks:wrap(BATTLE_ART_SUPPRESS_HOOK, function(next, request)
  if not optionEnabled("hide3dBattleUi") then
    return next(request)
  end

  if type(request) ~= "table"
      or request.apiVersion ~= 1
      or request.sourceModId ~= BATTLE_ART_ID then
    return next(request)
  end

  local surface = request.surface
  if surface == "hud" or surface == "text" or surface == "panels" then
    return true
  end

  return next(request)
end, 1000)

----------------------------------------------------------------
-- Stadium 2 Importer
--
-- Stadium 2 already provides cooperative ownership hooks:
--   battle.status_hud_visible
--   battle.bottom_ui_visible
--
-- Returning false tells Stadium's battle UI ownership layer that
-- another presentation owns that region. Stadium consequently leaves
-- its native status cards / lower UI out of the composed battle scene.
--
-- We deliberately do not touch input, the battle state, the 3D scene,
-- models, camera, effects, or animation.
----------------------------------------------------------------

mod.hooks:wrap("battle.status_hud_visible", function(next, state)
  if optionEnabled("hideStadium2BattleUi") then
    return false
  end
  return next(state)
end, 1000)

mod.hooks:wrap("battle.bottom_ui_visible", function(next, state)
  if optionEnabled("hideStadium2BattleUi") then
    return false
  end
  return next(state)
end, 1000)

----------------------------------------------------------------
-- Stadium 2 battle overlay
--
-- Stadium 2 deliberately leaves the engine's battle.overlay pass in place
-- when another UI owns its HUD regions. Some Stadium battle builds use that
-- pass for small in-scene status/type tags. When Stadium's native UI is hidden,
-- suppress that overlay too, but only while Stadium's own Gen 1 battle wrapper
-- is actively drawing. This keeps unrelated battles and overlays untouched.
----------------------------------------------------------------

mod.hooks:wrap("battle.overlay", function(next, battle)
  if optionEnabled("hideStadium2BattleUi")
      and type(battle) == "table"
      and battle.stadium2ImporterGen1Shot ~= nil then
    return
  end
  return next(battle)
end, 1000)
