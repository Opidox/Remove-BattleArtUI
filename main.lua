local mod = ...
local BA_ID = "BATTLE_ART_VOXEL_FORK"

local function enabled()
  return mod.options:get("hideBattleUi") == true
end

local function trainersHidden()
  return mod.options:get("hideTrainers") == true
end

mod.options:define({
  { key="hideBattleUi", label="HIDE BATTLE UI", type="toggle", default=false,
    description="Hide Battle Art and Stadium 2 battle UI." },
  { key="hideTrainers", label="HIDE TRAINERS", type="toggle", default=false,
    description="Hide player and enemy trainer pics during 3D battle intro." },
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
  if enabled() then return end
  return next(battle)
end, 1000)

local blankPic = nil
local function blankImage()
  if blankPic ~= nil then return blankPic or nil end
  local ok, img = pcall(function()
    return love.graphics.newImage(love.image.newImageData(1, 1))
  end)
  blankPic = (ok and img) or false
  return blankPic or nil
end

local okBS, BattleState = pcall(require, "src.battle.BattleState")
if okBS and BattleState then
  if not BattleState.hideTrainerIntroHook then
    local innerPics = BattleState.drawPicsLayer
    function BattleState:drawPicsLayer(slide, sx, sy, onlySide, skipMenuClip)
      if not trainersHidden() then
        return innerPics(self, slide, sx, sy, onlySide, skipMenuClip)
      end
      if onlySide ~= "enemy" and self.showPlayerBack and self.playerBackPic then
        return
      end
      local savedShow, savedPic = self.showEnemyTrainer, self.trainerPic
      self.showEnemyTrainer, self.trainerPic = false, nil
      local okCall, result = pcall(innerPics, self, slide, sx, sy,
                                   onlySide, skipMenuClip)
      self.showEnemyTrainer, self.trainerPic = savedShow, savedPic
      if not okCall then error(result, 0) end
      return result
    end
    BattleState.hideTrainerIntroHook = true
  end

  if not BattleState.hideTrainerPicHook then
    local innerPic = BattleState.picImage
    function BattleState:picImage(img)
      if trainersHidden() and img and img == self.trainerPic
          and blankImage() then
        return blankPic
      end
      return innerPic(self, img)
    end
    BattleState.hideTrainerPicHook = true
  end
end