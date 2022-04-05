CustomHeartAPI = RegisterMod("CustomHeartAPI", 1)

--GET HEART POSITION--

local HalfHeartTypes = {
	HEART_EMPTY = 0,
	HEART_RED = 1,
	HEART_SOUL = 2,
	HEART_BLACK = 3,
	HEART_ROTTEN = 4,
	HEART_BONE_EMPTY = 5,
	HEART_BONE_RED = 6,
	HEART_BONE_ROTTEN = 7,
	HEART_BROKEN = 8
}
HeartTypes = {
	HEART_RED_EMPTY = 0,
	HEART_RED_HALF = 1,
	HEART_RED_FULL = 2,
	HEART_SOUL_HALF = 3,
	HEART_SOUL_FULL = 4,
	HEART_BLACK_HALF = 5,
	HEART_BLACK_FULL = 6,
	HEART_ROTTEN = 7,
	HEART_BONE_EMPTY = 8,
	HEART_BONE_RED_HALF = 9,
	HEART_BONE_RED_FULL = 10,
	HEART_BONE_ROTTEN = 11,
	HEART_BROKEN = 12
}
HeartTable = {}
local playerIndex = 0
local LazList = {}

--table will store hearts in three layers
--layer 1 red heart/bone heart slot
--layer 2 red/soul heart in layer 1 slot
--layer 3 golden heart overlays
--layer 4 eternal heart layer


local function CheckPlayersHearts(player) --This function assigns the hearts and their corresponding position, not a nice name tho
	local HeartsInOrder = {}
	local HalfHeartsInOrder = {}
	local RedHeartContainers = player:GetMaxHearts()
	local SoulHearts = player:GetSoulHearts()
	local BlackHeartMask = player:GetBlackHearts()
	local BoneHearts = player:GetBoneHearts()*2
	local RottenHearts = player:GetRottenHearts()*2
	local BrokenHearts = player:GetBrokenHearts()*2
	local RedHearts = player:GetHearts()-RottenHearts
	local SoulHeartContainers = SoulHearts
	if SoulHeartContainers % 2 == 1 then
		SoulHeartContainers = SoulHeartContainers + 1
	end
	local NonRedHeartContainers = SoulHeartContainers + BoneHearts
	local offset = 0
	local effectiveOffset = offset
	--the following just organizes RedHearts and RottenHearts into HalfHeartsInOrder
	for i=1, RedHeartContainers do
		if RedHearts > 0 then
			RedHearts = RedHearts - 1
			HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_RED
		elseif RottenHearts > 0 and (HalfHeartsInOrder[i+effectiveOffset-1] == HalfHeartTypes.HEART_ROTTEN or i%2 == 1) then
			RottenHearts = RottenHearts - 1
			HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_ROTTEN
		else
			HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_EMPTY
		end
		offset = offset + 1
	end
	effectiveOffset = offset
	local checkedBoneHearts = 0
	--the following just organizes NonRedHeartContainers into HalfHeartsInOrder
	for i=1, NonRedHeartContainers do
		if player:IsBoneHeart(math.ceil((i)/2)-1) then
			if RedHearts > 0 then
				RedHearts = RedHearts - 1
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_BONE_RED
			elseif RottenHearts > 0 and (HalfHeartsInOrder[i+effectiveOffset-1] == HalfHeartTypes.HEART_BONE_ROTTEN or i%2 == 1) then
				RottenHearts = RottenHearts - 1
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_BONE_ROTTEN
			else
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_BONE_EMPTY
			end
			checkedBoneHearts = checkedBoneHearts + 1
		elseif (1 << (math.ceil((i-checkedBoneHearts)/2)-1)) & BlackHeartMask ~= 0 then
			if SoulHearts > 0 then
				SoulHearts = SoulHearts - 1
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_BLACK
			else
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_EMPTY
			end
		else
			if SoulHearts > 0 then
				SoulHearts = SoulHearts - 1
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_SOUL
			else
				HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_EMPTY
			end
		end
		offset = offset + 1
	end
	effectiveOffset = offset
	--the following just organizes BrokenHearts into HalfHeartsInOrder
	for i=1, BrokenHearts do
		HalfHeartsInOrder[i+effectiveOffset] = HalfHeartTypes.HEART_BROKEN
		offset = offset + 1
	end
	--the following just organizes HalfHeartsInOrder into HalfHeartsInOrder
	for i=1, #HalfHeartsInOrder do
		if i%2 ~= 0 then
			if HalfHeartsInOrder[i] == HalfHeartTypes.HEART_RED and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_RED then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_RED_FULL
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_RED and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_RED_HALF
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_EMPTY and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_RED_EMPTY
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_SOUL and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_SOUL then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_SOUL_FULL
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_SOUL and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_SOUL_HALF
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BLACK and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BLACK then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BLACK_FULL
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BLACK and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BLACK_HALF
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_ROTTEN and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_ROTTEN then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_ROTTEN
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BONE_EMPTY and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BONE_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BONE_EMPTY
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BONE_RED and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BONE_RED then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BONE_RED_FULL
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BONE_RED and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BONE_EMPTY then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BONE_RED_HALF
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BONE_ROTTEN and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BONE_ROTTEN then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BONE_ROTTEN
			elseif HalfHeartsInOrder[i] == HalfHeartTypes.HEART_BROKEN and HalfHeartsInOrder[i+1] == HalfHeartTypes.HEART_BROKEN then
				HeartsInOrder[math.ceil(i/2)] = HeartTypes.HEART_BROKEN
			end
		end
	end
	--the following inserts EternalHearts into HeartsInOrder
	if player:GetEternalHearts() > 0 then
		local pos = -1
		for i=1, #HeartsInOrder do
			if HeartsInOrder[i] == HeartTypes.HEART_RED_FULL or
			   HeartsInOrder[i] == HeartTypes.HEART_RED_HALF or
			   HeartsInOrder[i] == HeartTypes.HEART_RED_EMPTY or
			   HeartsInOrder[i] == HeartTypes.HEART_ROTTEN or
			   HeartsInOrder[i] == HeartTypes.HEART_BONE_RED_FULL or
			   HeartsInOrder[i] == HeartTypes.HEART_BONE_RED_HALF then
				pos = i
			end
		end
		if pos == -1 then
			pos = 1
		end
		--if #HeartsInOrder > 0 then
		print(HeartsInOrder[pos])
		HeartsInOrder[pos] = HeartsInOrder[pos] + 32 --32 seems to mean eternal
		print(HeartsInOrder[pos])
		--end
	end
	--the following inserts GoldenHearts into HeartsInOrder
	if player:GetGoldenHearts() > 0 then
		for i=0, player:GetGoldenHearts()-1 do
			HeartsInOrder[#HeartsInOrder-i-player:GetBrokenHearts()] = HeartsInOrder[#HeartsInOrder-i-player:GetBrokenHearts()] + 16
		end
	end
	return HeartsInOrder
end

function CustomHeartAPI:GetOrderedHearts(player)
	local currentPlayerType = player:GetPlayerType()
	if player.ControllerIndex == 0 and currentPlayerType == Isaac.GetPlayer(0):GetPlayerType() then
		HeartTable = {}
		playerIndex = 0
	end
	if not player:GetData()["HeartTypesChecked"] then
		if currentPlayerType == PlayerType.PLAYER_THELOST or currentPlayerType == PlayerType.PLAYER_THELOST_B then
			player:GetData()["HideHealth"] = true
			player:GetData()["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_KEEPER or currentPlayerType == PlayerType.PLAYER_KEEPER_B then
			player:GetData()["CoinHearts"] = true
			player:GetData()["HeartTypesChecked"] = true
		end
		if currentPlayerType == PlayerType.PLAYER_JACOB then
			player:GetData()["TwinCharacter"] = true
			player:GetData()["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_ESAU or currentPlayerType == PlayerType.PLAYER_THESOUL_B then
			player:GetData()["SkipCharacter"] = true
			player:GetData()["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN_B then
			player:GetData()["TForgotten"] = true
			player:GetData()["HeartTypesChecked"] = true
		else 
			player:GetData()["HeartTypesChecked"] = true
		end
	end
	if currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN then
		player:GetData()["UsesSubPlayer"] = true
		player:GetData()["IsSubPlayer"] = false
	elseif currentPlayerType == PlayerType.PLAYER_THESOUL then
		player:GetData()["UsesSubPlayer"] = true
		player:GetData()["IsSubPlayer"] = true
	end
	if player:GetData()["TaintedLazA"] then
		local OtherLaz = LazList[(player.ControllerIndex*2)+1]
		Isaac.ConsoleOutput(tostring(OtherLaz).."\n")
		HeartTable[#HeartTable+1] = {player, false, CheckPlayersHearts(player)}
		HeartTable[#HeartTable+1] = {OtherLaz, false, CheckPlayersHearts(OtherLaz)}
	elseif player:GetData()["TaintedLazB"] then
		local OtherLaz = LazList[player.ControllerIndex*2]
		Isaac.ConsoleOutput(tostring(OtherLaz).."\n")
		HeartTable[#HeartTable+1] = {player, false, CheckPlayersHearts(player)}
		HeartTable[#HeartTable+1] = {OtherLaz, false, CheckPlayersHearts(OtherLaz)}
	elseif player:GetData()["UsesSubPlayer"] and not player:GetData()["IsSubPlayer"] then
		HeartTable[#HeartTable+1] = {player, false, CheckPlayersHearts(player)}
		HeartTable[#HeartTable+1] = {player, true, CheckPlayersHearts(player:GetSubPlayer())}
	elseif player:GetData()["UsesSubPlayer"] and player:GetData()["IsSubPlayer"] then
		HeartTable[#HeartTable+1] = {player, true, CheckPlayersHearts(player:GetSubPlayer())}
		HeartTable[#HeartTable+1] = {player, false, CheckPlayersHearts(player)}
	elseif player:GetData()["TwinCharacter"] then
		HeartTable[#HeartTable+1] = {player:GetMainTwin(), false, CheckPlayersHearts(player:GetMainTwin())}
		HeartTable[#HeartTable+1] = {player:GetOtherTwin(), false, CheckPlayersHearts(player:GetOtherTwin())}
	elseif player:GetData()["TForgotten"] then
		HeartTable[#HeartTable+1] = {player:GetOtherTwin(), false, CheckPlayersHearts(player)}
		HeartTable[#HeartTable+1] = {player, false, {}}
	elseif not player:GetData()["SkipCharacter"] then
		HeartTable[#HeartTable+1] = {player, false, CheckPlayersHearts(player)}
		HeartTable[#HeartTable+1] = {-1}
	end
	playerIndex = playerIndex + 1
end
function CustomHeartAPI:SetPlayerHeartTypes(player)
	player:GetData()["HideHealth"] = false
	player:GetData()["CoinHearts"] = false
	player:GetData()["UsesCustomUI"] = false

	player:GetData()["TwinCharacter"] = false
	player:GetData()["SkipCharacter"] = false
	player:GetData()["UsesSubPlayer"] = false
	player:GetData()["IsSubPlayer"] = false
	player:GetData()["TaintedLazA"] = false
	player:GetData()["TaintedLazB"] = false
	player:GetData()["TSoul"] = false

	if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS_B then
		LazList[player.ControllerIndex*2] = player
		Isaac.ConsoleOutput(tostring(player).."\n")
		player:GetData()["TaintedLazA"] = true
	elseif player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
		LazList[(player.ControllerIndex*2)+1] = player
		Isaac.ConsoleOutput(tostring(player).."\n")
		player:GetData()["TaintedLazB"] = true
	end
end
CustomHeartAPI:AddCallback( ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHeartAPI.GetOrderedHearts)
CustomHeartAPI:AddCallback( ModCallbacks.MC_POST_PLAYER_INIT, CustomHeartAPI.SetPlayerHeartTypes)

--RENDER HEARTS--

VectorZero = Vector.Zero
HeartSprites = Sprite()
HeartSprites:Load("gfx/ui/ui_hearts_custom2.anm2", true)

local HeartPosTable = {
	Vector(68, 24), Vector(80, 24), Vector(92, 24), Vector(104, 24), Vector(116, 24), Vector(128, 24),
	Vector(68, 34), Vector(80, 34), Vector(92, 34), Vector(104, 34), Vector(116, 34), Vector(128, 34),
	Vector(140, 34), Vector(152, 34), Vector(164, 34),

	Vector(68, 49), Vector(80, 49), Vector(92, 49), Vector(104, 49), Vector(116, 49), Vector(128, 49),
	Vector(68, 59), Vector(80, 59), Vector(92, 59), Vector(104, 59), Vector(116, 59), Vector(128, 59),
	Vector(140, 69), Vector(152, 69), Vector(164, 69),

	Vector(405, 24), Vector(393, 24), Vector(381, 24), Vector(369, 24), Vector(357, 24), Vector(345, 24),
	Vector(405, 34), Vector(393, 34), Vector(381, 34), Vector(369, 34), Vector(357, 34), Vector(345, 34),
	Vector(333, 34), Vector(321, 34), Vector(309, 34),
	
	Vector(405, 49), Vector(393, 49), Vector(381, 49), Vector(369, 49), Vector(357, 49), Vector(345, 49),
	Vector(405, 59), Vector(393, 59), Vector(381, 59), Vector(369, 59), Vector(357, 59), Vector(345, 59),
	Vector(333, 59), Vector(321, 59), Vector(309, 59),

	Vector(68, 237), Vector(80, 237), Vector(92, 237), Vector(104, 237), Vector(116, 237), Vector(128, 237),
	Vector(68, 247), Vector(80, 247), Vector(92, 247), Vector(104, 247), Vector(116, 247), Vector(128, 247),
	Vector(140, 247), Vector(152, 247), Vector(164, 247),

	Vector(68, 212), Vector(80, 212), Vector(92, 212), Vector(104, 212), Vector(116, 212), Vector(128, 212),
	Vector(68, 222), Vector(80, 222), Vector(92, 222), Vector(104, 222), Vector(116, 222), Vector(128, 222),
	Vector(140, 222), Vector(152, 222), Vector(164, 222),
	
	Vector(405, 237), Vector(393, 237), Vector(381, 237), Vector(369, 237), Vector(357, 237), Vector(345, 237),
	Vector(405, 247), Vector(393, 247), Vector(381, 247), Vector(369, 247), Vector(357, 247), Vector(345, 247),
	Vector(333, 247), Vector(321, 247), Vector(309, 247),
	
	Vector(405, 212), Vector(393, 212), Vector(381, 212), Vector(369, 212), Vector(357, 212), Vector(345, 212),
	Vector(405, 222), Vector(393, 222), Vector(381, 222), Vector(369, 222), Vector(357, 222), Vector(345, 222),
	Vector(333, 222), Vector(321, 222), Vector(309, 222),

	Vector(-30, -35), Vector(-18, -35), Vector(-6, -35), Vector(6, -35), Vector(18, -35), Vector(30, -35),
	Vector(-30, -45), Vector(-18, -45), Vector(-6, -45), Vector(6, -45), Vector(18, -45), Vector(30, -45),
	Vector(42, -45), Vector(54, -45), Vector(66, -45),
}
local HeartAnimTable = {
	HEART_GOLD = "GoldHeartOverlay",
	HEART_ETERNAL = "WhiteHeartOverlay",
	HEART_RED_EMPTY = "EmptyHeart",
	HEART_RED_HALF = "RedHeartHalf",
	HEART_RED_FULL = "RedHeartFull",
	HEART_SOUL_HALF = "BlueHeartHalf",
	HEART_SOUL_FULL = "BlueHeartFull",
	HEART_BLACK_HALF = "BlackHeartHalf",
	HEART_BLACK_FULL = "BlackHeartFull",
	HEART_ROTTEN = "RottenHeartFull",
	HEART_BONE_EMPTY = "BoneHeartEmpty",
	HEART_BONE_RED_HALF = "BoneHeartHalf",
	HEART_BONE_RED_FULL = "BoneHeartFull",
	HEART_BONE_ROTTEN = "RottenBoneHeartFull",
	HEART_BROKEN = "BrokenHeart",
	HEART_COIN_EMPTY = "CoinEmpty",
	HEART_COIN_HALF = "CoinHeartHalf",
	HEART_COIN_FULL = "CoinHeartFull",
	HEART_COIN_BROKEN = "BrokenCoinHeart",
}

local function GetHeartAnimName(useCoinHearts, heart)
	local Animation = "WhiteHeartHalf"
	if heart % 16 == HeartTypes.HEART_RED_FULL then
		if useCoinHearts then
			Animation = HeartAnimTable.HEART_COIN_FULL
		else 
			Animation = HeartAnimTable.HEART_RED_FULL
		end
	elseif heart % 16 == HeartTypes.HEART_RED_HALF then
		if useCoinHearts then
			Animation = HeartAnimTable.HEART_COIN_HALF
		else 
			Animation = HeartAnimTable.HEART_RED_HALF
		end
	elseif heart % 16 == HeartTypes.HEART_RED_EMPTY then
		if useCoinHearts then
			Animation = HeartAnimTable.HEART_COIN_EMPTY
		else 
			Animation = HeartAnimTable.HEART_RED_EMPTY
		end
	elseif heart % 16 == HeartTypes.HEART_SOUL_FULL then
		Animation = HeartAnimTable.HEART_SOUL_FULL
	elseif heart % 16 == HeartTypes.HEART_SOUL_HALF then
		Animation = HeartAnimTable.HEART_SOUL_HALF
	elseif heart % 16 == HeartTypes.HEART_BLACK_FULL then
		Animation = HeartAnimTable.HEART_BLACK_FULL
	elseif heart % 16 == HeartTypes.HEART_BLACK_HALF then
		Animation = HeartAnimTable.HEART_BLACK_HALF
	elseif heart % 16 == HeartTypes.HEART_ROTTEN then
		Animation = HeartAnimTable.HEART_ROTTEN
	elseif heart % 16 == HeartTypes.HEART_BONE_EMPTY then
		Animation = HeartAnimTable.HEART_BONE_EMPTY
	elseif heart % 16 == HeartTypes.HEART_BONE_RED_FULL then
		Animation = HeartAnimTable.HEART_BONE_RED_FULL
	elseif heart % 16 == HeartTypes.HEART_BONE_RED_HALF then
		Animation = HeartAnimTable.HEART_BONE_RED_HALF
	elseif heart % 16 == HeartTypes.HEART_BONE_ROTTEN then
		Animation = HeartAnimTable.HEART_BONE_ROTTEN
	elseif heart % 16 == HeartTypes.HEART_BROKEN then
		if useCoinHearts then
			Animation = HeartAnimTable.HEART_COIN_BROKEN
		else 
			Animation = HeartAnimTable.HEART_BROKEN
		end
	end
	return Animation
end

function CustomHeartAPI:RenderHearts()
	if HeartTable then
		local Strawmen = 0
		for p,table in pairs(HeartTable) do
			if table[1] ~= -1 then
				local player = table[1]
				if not player:GetData()["HideHealth"] and not player:GetData()["UsesCustomUI"] then
					if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 then
						for i, heart in ipairs(table[3]) do
							local HeartPos
							if not player.Parent then
								HeartPos = HeartPosTable[i+((p-1-Strawmen)*15)]
							else
								HeartPos = Isaac.WorldToScreen(player.Position) + HeartPosTable[i+8*15]
								Strawmen = Strawmen + 1
							end
							local Animation = GetHeartAnimName(player:GetData()["CoinHearts"], heart)
							HeartSprites:Play(Animation, true)
							HeartSprites:Render(HeartPos, VectorZero, VectorZero)
							if heart & 32 == 32 then
								HeartSprites:Play(HeartAnimTable.HEART_ETERNAL, true)
								HeartSprites:Render(HeartPos, VectorZero, VectorZero)
							end
							if heart & 16 == 16 then
								HeartSprites:Play(HeartAnimTable.HEART_GOLD, true)
								HeartSprites:Render(HeartPos, VectorZero, VectorZero)
							end
						end
					else
						local HeartPos
						if not player.Parent then
							HeartPos = HeartPosTable[1+((p-1-Strawmen)*15)]
						else
							HeartPos = Isaac.WorldToScreen(player.Position) + Vector(0, -35)
							Strawmen = Strawmen + 1
						end
						HeartSprites:Play("CurseHeart", true)
						HeartSprites:Render(HeartPos, VectorZero, VectorZero)
					end
				end
			end
		end
	end
end
CustomHeartAPI:AddCallback( ModCallbacks.MC_POST_RENDER, CustomHeartAPI.RenderHearts)