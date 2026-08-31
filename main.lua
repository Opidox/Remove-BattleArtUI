local mod = ...
local BA_ID = "BATTLE_ART_VOXEL_FORK"

local function enabled()
  return mod.options:get("hideBattleUi") == true
end

mod.options:define({
  { key="hideBattleUi", label="HIDE BATTLE UI", type="toggle", default=false,
    description="Hide Battle Art and Stadium 2 battle UI." },
})

mod.hooks:wrap("battle.presentation.suppress_native.v1", function(next, req)
  if not enabled() then return next(req) end
  if type(req) ~= "table" or req.apiVersion ~= 1
      or req.sourceModId ~= BA_ID then return next(req) end
  local s = req.surface
  if s == "hud" or s == "text" or s == "panels" then return true end
  return next(req)
end, 1000)

mod.hooks:wrap("battle.status_hud_visible", function(next, state)
  if enabled() then return false end
  return next(state)
end, 1000)

mod.hooks:wrap("battle.bottom_ui_visible", function(next, state)
  if enabled() then return false end
  return next(state)
end, 1000)

mod.hooks:wrap("battle.overlay", function(next, battle)
  if enabled() and type(battle) == "table"
      and battle.stadium2ImporterGen1Shot ~= nil then return end
  return next(battle)
end, 1000)
