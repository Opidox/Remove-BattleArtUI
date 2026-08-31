-- Gen1 3D Battle UI Toggle
-- Standalone compatibility addon for Battle Art Voxel Fork.
-- When enabled, Battle Art keeps the 3D battle scene but suppresses its
-- native battle HUD, text, and Pokemon information panels.

local mod = ...

local SUPPRESS_HOOK = "battle.presentation.suppress_native.v1"
local BATTLE_ART_ID = "BATTLE_ART_VOXEL_FORK"

mod.options:define({
  {
    key = "hide3dBattleUi",
    label = "HIDE 3D BATTLE UI",
    type = "toggle",
    default = false,
    description = "Hide Battle Art Voxel's native 3D battle HUD, text and Pokemon information panels while keeping the 3D battle scene intact.",
  },
})

local function enabled()
  return mod.options:get("hide3dBattleUi") == true
end

-- Battle Art calls this hook once per native presentation surface.
-- Claim only the three surfaces that belong to its battle UI.
mod.hooks:wrap(SUPPRESS_HOOK, function(next, request)
  if not enabled() then
    return next(request)
  end

  if type(request) ~= "table" then
    return next(request)
  end

  if request.apiVersion ~= 1 or request.sourceModId ~= BATTLE_ART_ID then
    return next(request)
  end

  local surface = request.surface
  if surface == "hud" or surface == "text" or surface == "panels" then
    return true
  end

  return next(request)
end, 1000)
