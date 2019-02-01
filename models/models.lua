-- MIT License
-- Copyright (c) 2019 Martín Aguilar

local Model = require('plug').Model

-- Horse/Mounts model

local horse = Model {
  property = {
    ride_height = 0,
    ui_scale = 0,
    min_hp = 0,
    max_hp = 0,
    min_jumpheight = 0,
    max_jumpheight = 0,
    born_saddle = 0,
    saddle_model = 1,
  }
}

-- Item model

local item = Model {
  property = {
    id = 0,
    stack_max = 0
  }
}

-- Actor model

local actor = Model {
  property = {
    id = 0,
    Effect = "",
    TextureID = 0,
    attack = 30,
    attack_distance = 1,
    buff_id = 0,
    drop_exp = 0,
    drop_exp_prob = 0,
    drop_item1 = 0,
    drop_item2 = 0,
    drop_item3 = 0,
    drop_item_prob1 = 0,
    drop_item_prob2 = 0,
    drop_item_prob3 = 0,
    life = 150,
    model_scale = 1.1,
    speed = 0,
    team_id = 0,
    view_distance = 16,
    set_ai = {}
  }
}

-- Crafting recipes model

local crafting = Model {
  property = {
		id = 0,
		is_followme = false,
		material_count1 = 0,
		material_count2 = 0,
		material_count3 = 0,
		material_count4 = 0,
		material_count5 = 0,
		material_count6 = 0,
		material_count7 = 0,
		material_count8 = 0,
		material_count9 = 0,
		material_id1 = 0,
		material_id2 = 0,
		material_id3 = 0,
		material_id4 = 0,
		material_id5 = 0,
		material_id6 = 0,
		material_id7 = 0,
		material_id8 = 0,
		material_id9 = 0,
		result_count = 0,
		result_id = 0,
		type = 0
  }
}

-- Block model

local block = Model {
  item_property = {
    id = 0
  },
  property = {
    id = 0,
		anti_explode = 500,
		breakable = true,
		burn_speed = 0,
		catch_fire = 0,
		hardness = 0,
		move_collide = 0,
		slipperiness = 0,
		tool_mine_drop1 = 0
  }
}

-- Ore generation model

local ore = Model {
  property = {
    MaxHeight = 0,
    MaxVeinBlocks = 0,
    MinHeight = 0,
    ReplaceBlock = 0,
    TryGenCount = 0,
    id = 0
  }
}

return {
  horse = horse,
  item = item,
  actor = actor,
  ore = ore,
  crafting = crafting,
  block = block
}
