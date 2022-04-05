CustomHeartAPI = RegisterMod("CustomHeartAPI", 1)

--How this API works/or at least how I expected it to work

--First the game takes the vanilla placement of vanilla hearts and converts them into CustomHeartAPI.VanillaTemplateHeartTypes
--CustomHeartAPI.VanillaTemplateHeartTypes are values used to set hearts into the PlayerHearts table into layers:
--table will store hearts in three layers
--layer 0 red heart/bone heart slot
--layer 1 soul heart in layer 1 slot
--layer 2 red/rotten hearts
--layer 3 golden heart overlays
--layer 4 eternal heart layer
--layer 5 custom hearts, which you have to manually set the layers (no plans to make it functional yet)

--Then the game renders the healthbar with each update(on damage or when health increases or decreases through devil deals, donation, or item update)
--This api should render according to the data given in CustomHeartAPI.PlayerHearts

--Game would have mods which define classes of custom hearts based by CustomHeartAPI.VanillaTemplateHeartTypes which can be added ingame during the game
--Available methods allow us to check if player has the heart, how many, if a heart is lost, etc. The api will provide everything necessary in hopes that we can replicate the
--vanilla functionalities of hearts while even extending it to our power provided by the Isaac API.

--On game start, CustomHeartAPI.PlayerHearts gets refreshed while on game end CustomHeartAPI.PlayerHearts is saved

function CustomHeartAPI.GetPlayerData(player) --im gonna have to do this becauSE ISAAC API SUCKS AND FORGOTTEN AND ITS DAMN SOUL SHARES GETDATA 
	local currentPlayerType = player:GetPlayerType()
	local data = player:GetData()
	--[[	local specialDataForTheseTwats 
		if not data.ForgottenTwat then data.ForgottenTwat = {} end
		if not data.ForgottensSoulTwat then data.ForgottensSoulTwat = {} end
		if currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN then
			specialDataForTheseTwats = data.ForgottenTwat
		else
			specialDataForTheseTwats = data.ForgottensSoulTwat
		end
		return specialDataForTheseTwats
	else]]
		return data
	--end
end

--enums! --

CustomHeartAPI.VanillaTemplateHeartTypes = {
	HEART_EMPTY = 0,
	HEART_SOUL = 1,
	HEART_RED = 2,
	HEART_BONE = 3,
	HEART_GOLD = 4, --sounds annoying to do
	HEART_ETERNAL = 5, --why
	HEART_BLACK = 6, --just use soul heart
	HEART_ROTTEN = 7,
	HEART_BROKEN = 8, --whats the point
	HEART_CUSTOM = 9
}

CustomHeartAPI.CustomHeartTypes = {} --table that stores custom hearts

CustomHeartAPI.CustomHeart = {} --table turned into a class

CustomHeartAPI.oldHearts = {--keeps track on how much old max hearts there are
	Max = {},
	Red = {},
	Rotten = {},
	Soul = {},
	Evil = {},
	Bone = {},
	Golden = {},
	Eternal = {},
	Broken = {}
} 

CustomHeartAPI.PlayerHearts = { --table that stores every heart of each player, by player index
	--BaseHearts = {},
	--SoulHearts = {},
	--RedHearts = {},
	--BoneHearts = {},
	--HasEternal = {},
	--GoldenHearts = {},
	--CustomHearts = {}
}

CustomHeartAPI.PlayerHeartAnimations = { 
	--BaseHearts = {},
	--SoulHearts = {},
	--RedHearts = {},
	--HasEternal = {},
	--GoldenHearts = {},
	--CustomHearts = {}
}


function CustomHeartAPI.CustomHeart:New(name, hearttype, anm2, health)

	o = {};
	o.name = name
	o.hearttype = hearttype
	o.anm2 = anm2
	o.health = health
	
	setmetatable(o,self);
	self.__index = self;

	CustomHeartAPI.CustomHeartTypes[#CustomHeartAPI.CustomHeartTypes + 1] = o

	return o;
end



function CustomHeartAPI.GetRedHearts(player)
	local RottenHearts = player:GetRottenHearts()*2
	return player:GetHearts()-RottenHearts
end

function CustomHeartAPI.GetBlackHearts(player) --this black heart actually picks up how much black hearts there are
	-- Kilburn's code thingy that came from SOul Heart Rebalnce mod thingy that happens to be authored by Cucco. SO uhm, thanks Cucco and Kilburn or both of ya!
    local soulHearts = player:GetSoulHearts()
    local blackHearts = 0
    local currentSoulHeart = 0
    for i=0, (math.ceil(player:GetSoulHearts() / 2) + player:GetBoneHearts())-1 do
        if not player:IsBoneHeart(i) then
            if player:IsBlackHeart(currentSoulHeart+1) then
                if soulHearts - currentSoulHeart >= 2 then
                    blackHearts = blackHearts + 2
                elseif soulHearts - currentSoulHeart == 1 then
                    blackHearts = blackHearts + 1
                end
            end
            currentSoulHeart = currentSoulHeart + 2
        end
    end
    return blackHearts
end

function CustomHeartAPI.GetTotalHealth(player) --this is getting EVERY KIND OF HEART 
	return player:GetMaxHearts() + player:GetSoulHearts() + (player:GetBoneHearts() * 2)
end

function CustomHeartAPI.GetHeartLimit(player)
	local maxHearts = 12
    if player:GetPlayerType() == PlayerType.PLAYER_MAGDALENA and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
        maxHearts = 18
    end
	return maxHearts
end

function CustomHeartAPI.GetRightmostAvailableHeartIndex(player, index)
    local totalHealth = CustomHeartAPI.GetTotalHealth(player)
    -- Round up to the nearest whole heart
    local rightmostHeartIndex = math.ceil(totalHealth * 0.5)

    -- Now that we have the rightmost heart, find the first one that isn't yet taken
    local lastRedHeartIndex = player:GetMaxHearts() * 0.5
	print(rightmostHeartIndex)
	print(lastRedHeartIndex)
    for i = rightmostHeartIndex, (lastRedHeartIndex + 1), -1 do -----???????? what is this
        --if not playerImmortalHealth[index][i] then
            return i
       -- end
    end

    return false
end

function CustomHeartAPI.GetStoredHealth(player)
	local playerIndex = CustomHeartAPI.GetPlayerIndex(player)
	return CustomHeartAPI.PlayerHearts[playerIndex]
end

function CustomHeartAPI.GetPlayerHearts(player, layer)
	if not layer or layer == 0 then
		return CustomHeartAPI.GetStoredHealth(player).BaseHearts
	elseif layer == 1 then
		return CustomHeartAPI.GetStoredHealth(player).SoulHearts
	elseif layer == 2 then
		return CustomHeartAPI.GetStoredHealth(player).RedHearts
	elseif layer == 3 then
		return CustomHeartAPI.GetStoredHealth(player).BoneHearts
	elseif layer == 4 then
		return CustomHeartAPI.GetStoredHealth(player).GoldenHearts
	elseif layer == 5 then
		return CustomHeartAPI.GetStoredHealth(player).EternalHearts
	end
end

local json = require("json")
local function tableToString(table)
    local output = {}
    for player_index, player_healthtype in pairs(table) do
        local playerdata_output = {}
        for hearts_type, hearts_info in pairs(player_healthtype) do
			local heart_infooutput = {} 
			--Isaac.DebugString("hearts_type")
			--Isaac.DebugString(tostring(hearts_type))
			--Isaac.DebugString(tostring(hearts_info))
			if type(hearts_info) == "boolean" then
				 playerdata_output[hearts_type] = hearts_info
			else
				for heart_index, heart_info in pairs(hearts_info) do
				--	Isaac.DebugString("heart_index")
				--	Isaac.DebugString(tostring(heart_index))
				--	Isaac.DebugString(tostring(heart_info))
					heart_infooutput[tostring(heart_index)] = heart_info
				end
				playerdata_output[hearts_type] = heart_infooutput
			end
        end
        output[tostring(player_index)] = playerdata_output
    end

    return json.encode(output)
end

-- Convert string to health table
local function stringToTable(str)
    local table = json.decode(str)
    local output = {}
    for player_index, player_healthtype in pairs(table) do
        local playerdata_output = {}
        for hearts_type, hearts_info in pairs(player_healthtype) do
			local heart_infooutput = {} 
			--Isaac.DebugString("hearts_type")
			--Isaac.DebugString(tostring(hearts_type))
			--Isaac.DebugString((hearts_info))
			if type(hearts_info) == "boolean" then
			else
				for heart_index, heart_info in pairs(hearts_info) do
					--Isaac.DebugString("heart_index")
					--Isaac.DebugString(tonumber(heart_index))
					--Isaac.DebugString((heart_info))
					heart_infooutput[tonumber(heart_index)] = heart_info
				end
				if hearts_type then
					playerdata_output[hearts_type] = heart_infooutput
				end
			end
        end
        output[tonumber(player_index)] = playerdata_output
    end

    return output
end

local playerIndexCount = 0
local playerIndexTable = { --do i even use this?
}

function CustomHeartAPI.GetPlayerIndex(player)
	return CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex
	--[[for i, v in pairs(playerIndexTable) do
		if GetPtrHash(v) == GetPtrHash(player) then
			return i
		end
	end
	return nil]]
end

local hasLoadedData = false --i put this outside of player init because of multiple init stuff
CustomHeartAPI:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player) --Player "Init"
	-- First, check if the custom hearts table is empty.
    -- If it is, try loading the saved data.
	if not CustomHeartAPI.GetPlayerData(player).Init then
		if CustomHeartAPI:HasData() and next(CustomHeartAPI.PlayerHearts) == nil then
			local savedData = CustomHeartAPI:LoadData()
			if savedData then
				local decodedSavedData = stringToTable(savedData)
				if decodedSavedData and type(decodedSavedData) == "table" then
					CustomHeartAPI.PlayerHearts = decodedSavedData
					hasLoadedData = true
					Isaac.DebugString("hasLoadedData")
				end
			end
		end     
		--Isaac.DebugString("How many times?")
		--Isaac.DebugString(tostring(player:GetPlayerType()))
		if player:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B then
		--	Isaac.DebugString("did this go here")
			if not CustomHeartAPI.PlayerHearts[playerIndexCount] then
		--		Isaac.DebugString("im really tired of doing this")
				CustomHeartAPI.PlayerHearts[playerIndexCount] = {
					BaseHearts = {},
					SoulHearts = {},
					RedHearts = {},
					BoneHearts = {},
					HasEternal = {},
					GoldenHearts = {},
					CustomHearts = {
						["1"] = "test",
						["2"] = "test again"
					}
				}
			end
			
			if not playerIndexTable[playerIndexCount] then
				playerIndexTable[playerIndexCount] = player
			end
			--[[if not CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex then
				if player:GetPlayerType() == 16 then
					--Isaac.DebugString(tostring(player:GetName())..tostring(playerIndexCount - 1))
					CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex = playerIndexCount --- 1
					--player:GetData().ForgottensSoulTwat.CustomHeartAPI_PlayerIndex = playerIndexCount
				elseif player:GetPlayerType() == 17 then
					CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex = playerIndexCount --+ 1
					--Isaac.DebugString(tostring(player:GetName())..tostring(playerIndexCount + 1))
				else]]
			CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex = playerIndexCount
			--[[	end
			end]]
			
			--if player:GetPlayerType() ~= 16 then
			playerIndexCount = playerIndexCount + 1
			--end
			if player:GetPlayerType() == 16 then --if Forgotten
				playerIndexCount = playerIndexCount + 1 --add extra for that soul guy
				playerIndexTable[playerIndexCount + 1] = player
			end
			CustomHeartAPI.oldHearts = {
				Max = {},
				Red = {},
				Rotten = {},
				Soul = {},
				Evil = {},
				Bone = {},
				Golden = {},
				Eternal = {},
				Broken = {}
			}
			if not CustomHeartAPI.PlayerHeartAnimations then --gotta make it an if statement because multiple players break this lol
				CustomHeartAPI.PlayerHeartAnimations = {}
			end
			--animation things lmao
			if not CustomHeartAPI.PlayerHeartAnimations[CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex] then
				CustomHeartAPI.PlayerHeartAnimations[CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex] = {
					BaseHearts = {},
					SoulHearts = {},
					RedHearts = {},
					BoneHearts = {},
					HasEternal = {},
					GoldenHearts = {}
				}
				if player:GetPlayerType() == 16 then --if Forgotten
					CustomHeartAPI.PlayerHeartAnimations[CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex + 1] = {
						BaseHearts = {},
						SoulHearts = {},
						RedHearts = {},
						BoneHearts = {},
						HasEternal = {},
						GoldenHearts = {}
					}
				end
			end
			
			if not hasLoadedData then
				CustomHeartAPI.GetPlayerData(player).FinalStoredHearts = CustomHeartAPI.SetPlayerHeartInit(player)
				if player:GetPlayerType() == 16 then --if Forgotten
					CustomHeartAPI.GetPlayerData(player).FinalStoredSubHearts = CustomHeartAPI.SetPlayerHeartInit(player:GetSubPlayer(), CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex + 1)
				end
			end
			CustomHeartAPI.UpdateHeartAnimation(CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex], CustomHeartAPI.GetPlayerIndex(player), player)
			if player:GetPlayerType() == 16 then --if Forgotten
				CustomHeartAPI.UpdateHeartAnimation(CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerData(player).CustomHeartAPI_PlayerIndex + 1], CustomHeartAPI.GetPlayerIndex(player) + 1, player)
				--if player:GetSubPlayer() then
				--	player:GetSubPlayer():GetData().CustomHeartAPI_PlayerIndex = player:GetData().CustomHeartAPI_PlayerIndex
				--	Isaac.DebugString("cmon man you can do this man")
				--	Isaac.DebugString(tostring(player:GetSubPlayer():GetData().CustomHeartAPI_PlayerIndex))
				--end
			end
		else --if forgotten's soul
			if player:GetSubPlayer() then
				--Isaac.DebugString("cmon man you can do thissss")
				--CustomHeartAPI.GetPlayerData(player:GetSubPlayer()).CustomHeartAPI_PlayerIndex = playerIndexCount -2 --lucky prediction i hope???
				--Isaac.DebugString(tostring(player:GetSubPlayer():GetData().CustomHeartAPI_PlayerIndex))
				--Isaac.DebugString(tostring(player:GetSubPlayer():GetPlayerType()))
			end
		end
		CustomHeartAPI.GetPlayerData(player).Init = true
	end
end)

-- If the player starts a new game, clear out all existing save data and rebuild the immortalhealth array fresh.
function CustomHeartAPI:OnNewGameStart(isContinued)
    if not isContinued then
        --[[CustomHeartAPI.PlayerHearts = {}
		for p = 0, Game():GetNumPlayers() - 1 do
            CustomHeartAPI.PlayerHearts[p] = {
				BaseHearts = {},
				SoulHearts = {},
				RedHearts = {},
				BoneHearts = {},
				HasEternal = {},
				GoldenHearts = {},
				CustomHearts = {}
			}
        end]]
		Isaac.DebugString("hellooooo punks")
        CustomHeartAPI:RemoveData()
    end

    -- Seed the RNG with the current run's seed
    RNG():SetSeed(Game():GetSeeds():GetStartSeed(), 0)
end
CustomHeartAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CustomHeartAPI.OnNewGameStart)

-- Run on game end
-- Clear the existing array of nonsense
function CustomHeartAPI:clearDataOnGameEnd( isSaving)
    -- If we're saving the game, save our immortal heart data to JSON BEFORE we exit.
	playerIndexCount = 0
    if isSaving then
		CustomHeartAPI:SaveData(tableToString(CustomHeartAPI.PlayerHearts))
    else
        -- Clear out existing data on exit
        CustomHeartAPI:RemoveData()
    end

    CustomHeartAPI.PlayerHearts = {}
	CustomHeartAPI.PlayerHeartAnimations = { }
	hasLoadedData = false
	playerIndexTable = {}
end

CustomHeartAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CustomHeartAPI.clearDataOnGameEnd)


--GET HEART POSITION--

local HalfHeartTypes = { --each vanilla type of hearts available
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

local HeartTypes = { --each vanilla heart's state
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
--local playerIndex = 0
local LazList = {}

function CustomHeartAPI.CheckPlayerVanillaHearts(player) --This function assigns the hearts and their corresponding position
	local HeartsInOrder = {}
	local HalfHeartsInOrder = {}
	local SimulatedHeartsInOrder = {}
	
	local RedHeartContainers = player:GetMaxHearts()
	local SoulHearts = player:GetSoulHearts()
	local BlackHeartMask = player:GetBlackHearts()
	local BoneHearts = player:GetBoneHearts()*2
	local RottenHearts = player:GetRottenHearts()*2
	local BrokenHearts = player:GetBrokenHearts()*2
	local RedHearts = CustomHeartAPI.GetRedHearts(player)
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
		HeartsInOrder[pos] = HeartsInOrder[pos] + 32 --32 seems to mean eternal
		--end
	end
	--the following inserts GoldenHearts into HeartsInOrder
	if player:GetGoldenHearts() > 0 then
		for i=0, player:GetGoldenHearts()-1 do
			HeartsInOrder[#HeartsInOrder-i-player:GetBrokenHearts()] = HeartsInOrder[#HeartsInOrder-i-player:GetBrokenHearts()] + 16
		end
	end
	
	--nest in HeartsInOrder to SimulatedHeartsInOrder
	for i=1, #HeartsInOrder do
		local HeartInfo = HeartsInOrder[i]
		SimulatedHeartsInOrder[i] = HeartInfo
	end
	
	return SimulatedHeartsInOrder
end

function CustomHeartAPI.GetPlayerHeartInit(player) --This function assigns the hearts and their corresponding potential customized attributes
	local SimulatedHeartsInOrder = CustomHeartAPI.CheckPlayerVanillaHearts(player)
	
	local OrganizedSlots = {}
	local OrganizedHearts = {}
	local OrganizedRedHearts = {}
	local OrganizedBone = {}
	local HasEternal = false
	local OrganizedGoldHearts = {}
	
	local playerIndex = CustomHeartAPI.GetPlayerIndex(player)
	
	--first change each heart into a necessary state
	for i=1, #SimulatedHeartsInOrder do
		local HeartInfo = SimulatedHeartsInOrder[i]
		if HeartInfo % 16 == HeartTypes.HEART_RED_FULL then
			OrganizedSlots[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_EMPTY,
				health = 0
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_RED,
				health = 2
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_RED_HALF then
			OrganizedSlots[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_EMPTY,
				health = 0
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_RED,
				health = 1
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_RED_EMPTY then
			OrganizedSlots[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_EMPTY,
				health = 0
			}
			OrganizedRedHearts[i] = nil
		elseif HeartInfo % 16 == HeartTypes.HEART_SOUL_FULL then
			OrganizedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_SOUL,
				health = 2
			}
			Isaac.DebugString("WTFFFFFFF")
		elseif HeartInfo % 16 == HeartTypes.HEART_SOUL_HALF then
			OrganizedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_SOUL,
				health = 1
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BLACK_FULL then
			OrganizedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BLACK,
				health = 2
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BLACK_HALF then
			OrganizedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BLACK,
				health = 1
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_ROTTEN then
			OrganizedSlots[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_EMPTY,
				health = 0
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_ROTTEN,
				health = 2
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BONE_EMPTY then
			OrganizedBone[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BONE,
				isCustom = nil,
				health = 1
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BONE_RED_FULL then
			OrganizedBone[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BONE,
				isCustom = nil,
				health = 1
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_RED,
				health = 2
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BONE_RED_HALF then
			OrganizedBone[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BONE,
				isCustom = nil,
				health = 1
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_RED,
				health = 1
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BONE_ROTTEN then
			OrganizedBone[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BONE,
				isCustom = nil,
				health = 1
			}
			OrganizedRedHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_ROTTEN,
				health = 2
			}
		elseif HeartInfo % 16 == HeartTypes.HEART_BROKEN then
			OrganizedSlots[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BROKEN,
				isCustom = nil,
				health = 2
			}
		end
		if HeartInfo & 16 == 16 then --gold
			OrganizedGoldHearts[i] = {
				id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_GOLD,
				isCustom = nil,
				health = 1
			}
			Isaac.DebugString("senator")
		end
		if HeartInfo & 32 == 32 then --eternal
			HasEternal = true
			Isaac.DebugString("armstrong")
		end
	end
	
	local table = {
		BaseHearts = {},
		SoulHearts = {},
		RedHearts = {},
		BoneHearts = {},
		HasEternal = {},
		GoldenHearts = {}
	}
	
	Isaac.DebugString("done")
	table.BaseHearts = OrganizedSlots
    table.SoulHearts = OrganizedHearts
	table.RedHearts = OrganizedRedHearts
	table.BoneHearts = OrganizedBone
	table.GoldenHearts = OrganizedGoldHearts
	table.HasEternal = HasEternal
	return table --CustomHeartAPI.PlayerHearts[playerIndex]
end

function CustomHeartAPI.SetPlayerHeartInit(player, index)
	local playerIndex = index or CustomHeartAPI.GetPlayerIndex(player)
	local table = CustomHeartAPI.GetPlayerHeartInit(player)
	
	CustomHeartAPI.PlayerHearts[playerIndex] = table
	return CustomHeartAPI.PlayerHearts[playerIndex]
end

function CustomHeartAPI.GetHeartAnimation(heart, id) --supposed to get the vanilla animation
	local Animation = "gfx/ui/hearts/vanilla/empty.anm2"
	if heart == "BoneHearts" then
		Animation = "gfx/ui/hearts/vanilla/bone.anm2"
	elseif heart == "RedHearts" then
		if id == CustomHeartAPI.VanillaTemplateHeartTypes.HEART_ROTTEN then
			Animation = "gfx/ui/hearts/vanilla/rotten.anm2"
		else
			Animation = "gfx/ui/hearts/vanilla/red.anm2"
		end
	elseif heart == "SoulHearts" then
		if id == CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BLACK then
			Animation = "gfx/ui/hearts/vanilla/evil.anm2"
		else
			Animation = "gfx/ui/hearts/vanilla/soul.anm2"
		end
	elseif heart == "BaseHearts" then
		if id == CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BROKEN then
			Animation = "gfx/ui/hearts/vanilla/broken.anm2"
		end
	elseif heart == "GoldenHearts" then
		Animation = "gfx/ui/hearts/vanilla/gold.anm2"
	elseif heart == "HasEternal" then
		Animation = "gfx/ui/hearts/vanilla/eternal.anm2"
	end
	return Animation
end

function CustomHeartAPI.IsCustomHeart(index)
	return CustomHeartAPI.GetPlayerHearts(player)[index].isCustom
end

function CustomHeartAPI.GetHeart(player, index, layer)
	print("peaceful")
	if CustomHeartAPI.GetPlayerHearts(player, layer)[index] then
		return CustomHeartAPI.GetPlayerHearts(player, layer)[index].id
	end
end

--TO DO: Update the vanilla stored hearts somehow
function CustomHeartAPI.AddCustomHeart(player, name, amount)
	local index = CustomHeartAPI.GetTotalHealth(player)
	--print(index)
	--print(CustomHeartAPI.GetPlayerHearts(player))
	local heartTable = CustomHeartAPI.GetStoredHealth(player)
	if name.hearttype == CustomHeartAPI.VanillaTemplateHeartTypes.HEART_SOUL then
		player:AddSoulHearts(amount or 2)
		heartTable = heartTable.SoulHearts
		heartTable[index] = {
			id = CustomHeartAPI.VanillaTemplateHeartTypes.HEART_SOUL,
			health = 2,
			isCustom = name.name
		}
		--[[for k, v in pairs(heartTable) do
			print(k)
			for k2, v2 in pairs(v) do
				print("pain")
				print(k2)
				print(v2)
			end
		end]]
	end
end

function CustomHeartAPI.UpdateHeartAnimation(hearttable, playerIndex, player) --used to update the files/sprite of heart
	local spriteTable = {} --contains what will be returned later

	for name, hearts in pairs(hearttable) do
		if name ~= "HasEternal" then
			for index, heart in pairs(hearts) do
				--[[for animName, animHearts in pairs(CustomHeartAPI.PlayerHeartAnimations[playerIndex]) do
					Isaac.DebugString(tostring(animName).." fucking headache")
				end]]
				for animName, animHearts in pairs(CustomHeartAPI.PlayerHeartAnimations[playerIndex]) do
				--	Isaac.DebugString("gura")
				--	Isaac.DebugString(tostring(animName).." animName")
				--	Isaac.DebugString(tostring(name).." name")
					if animName == name then
				--		Isaac.DebugString(tostring(index))
						if not spriteTable[name] then spriteTable[name] = {} end
						spriteTable[name][index] = Sprite()
						local Animation = CustomHeartAPI.GetHeartAnimation(name, heart.id)
						if CustomHeartAPI.GetPlayerData(player)["CoinHearts"] then --if keeper
							if heart.id == CustomHeartAPI.VanillaTemplateHeartTypes.HEART_BROKEN then
								Animation = "gfx/ui/hearts/vanilla/brokencoin.anm2"
							else
								Animation = "gfx/ui/hearts/vanilla/coin.anm2"
							end
						end
						spriteTable[name][index]:Load(Animation, true)
				--		Isaac.DebugString("it worked, what")
						--Isaac.DebugString(spriteTable[name][index])
					end
				end
			end
		else --this is a special case for eternal hearts, and since i doubt people is gonna replicate this son of a gun, ill just do this
			local boolean = hearts
			
			spriteTable[name] = Sprite()
			local Animation = CustomHeartAPI.GetHeartAnimation(name, CustomHeartAPI.VanillaTemplateHeartTypes.HEART_ETERNAL)
			spriteTable[name]:Load(Animation, true)
		end
	end
	CustomHeartAPI.PlayerHeartAnimations[playerIndex] = spriteTable
	return CustomHeartAPI.PlayerHeartAnimations[playerIndex]
end

-- Shift hearts to the right when an HP upgrade is picked up
function CustomHeartAPI.ShiftCustomNonRedHealth(player, shiftAmount)
    local playerIndex = CustomHeartAPI.GetPlayerIndex(player)
	local simulatedHealth = CustomHeartAPI.GetPlayerHearts(player, 1)

    -- Max hearts is 12, but can be 18 with Maggy's Birthright
    local maxHearts = CustomHeartAPI.GetHeartLimit(player)
	--for _, heart in pairs(simulatedHealth) do
	
		if shiftAmount > 0 then
			-- Loop backwards over the immortal hearts and shift them all to the right if possible.
			-- If possible, copy the data to the new location and erase the old location.
			-- If this is not possible, erase the old location (this happens if, say, the rightmost soul heart is an immortal heart and gets bumped out)
			for i=maxHearts,1,-1 do
				if simulatedHealth[i] and (i + shiftAmount) <= maxHearts then
					simulatedHealth[i + shiftAmount] = simulatedHealth[i]
					simulatedHealth[i] = nil
				else
					simulatedHealth[i] = nil
				end
			end
		elseif shiftAmount < 0 then
			for i=1,maxHearts,1 do
				if simulatedHealth[i] and (i + shiftAmount) >= 1 then
					simulatedHealth[i + shiftAmount] = simulatedHealth[i]
					simulatedHealth[i] = nil
				else
					simulatedHealth[i] = nil
				end
			end
		end
    --end
end

function CustomHeartAPI:CheckHeartValidity(player)
    local maxHealth = player:GetMaxHearts()
    local soulHealth = player:GetSoulHearts()
    local boneHealth = (player:GetBoneHearts() * 2) -- We don't care if it's filled or not
    local totalHealth = CustomHeartAPI.GetTotalHealth(player)
	local redHealth = CustomHeartAPI.GetRedHearts(player)
	local rottenHealth = player:GetRottenHearts()
	local evilHealth = CustomHeartAPI.GetBlackHearts(player)
	local boneHealth = player:GetBoneHearts()
	local goldHealth = player:GetGoldenHearts()
	local eternalHealth = player:GetEternalHearts()
	local brokenHealth = player:GetBrokenHearts()
	
	--get custom hearts and vanilla heart table thingy, whatever thats called
	local playerIndex = CustomHeartAPI.GetPlayerIndex(player)
	
	--local simulatedHealth = CustomHeartAPI.GetPlayerHearts(player, 1) --am i even gonna use this?
    -- Round up to the nearest whole heart
    local rightmostHeartIndex = math.ceil(totalHealth * 0.5)
	local oldHearts = CustomHeartAPI.oldHearts
	
	local function updateOldHearts()
		oldHearts.Max[playerIndex] = maxHealth
		oldHearts.Red[playerIndex] = redHealth
		oldHearts.Rotten[playerIndex] = rottenHealth
		oldHearts.Soul[playerIndex] = soulHealth
		oldHearts.Evil[playerIndex] = evilHealth
		oldHearts.Bone[playerIndex] = boneHealth
		oldHearts.Golden[playerIndex] = goldHealth
		oldHearts.Eternal[playerIndex] = eternalHealth
		oldHearts.Broken[playerIndex] = brokenHealth
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN or player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		maxHealth = maxHealth + player:GetSubPlayer():GetMaxHearts()
		soulHealth = soulHealth + player:GetSubPlayer():GetSoulHearts()
		boneHealth = (boneHealth + player:GetSubPlayer():GetBoneHearts() * 2)
		redHealth = redHealth + CustomHeartAPI.GetRedHearts(player:GetSubPlayer())
		rottenHealth = rottenHealth + player:GetSubPlayer():GetRottenHearts()
		evilHealth = evilHealth + CustomHeartAPI.GetBlackHearts(player:GetSubPlayer())
		boneHealth = boneHealth + player:GetSubPlayer():GetBoneHearts()
		goldHealth = goldHealth + player:GetSubPlayer():GetGoldenHearts()
		eternalHealth = eternalHealth + player:GetSubPlayer():GetEternalHearts()
		brokenHealth = brokenHealth + player:GetSubPlayer():GetBrokenHearts()
	end
	
    -- Evaluate the players' hearts individually.
    -- Is an immortal heart occupying a slot that no longer exists? If so, remove the immortal heart.

    -- Check if the player index exists
    if not playerIndex then
        return
    end

    -- Check for any gained/lost max HP and shift immortal hearts to the left or the right.
    -- Finally!
    if not oldHearts.Max[playerIndex] and Game():GetFrameCount() > 1 then --predicting a nil Max is enough
        -- Fix for this being nil the first frame
        updateOldHearts()
    end
	
	local function SetAndGetHearts(player, index) --sets both hearts and its animation?
		--set hearts into player
		local FinalStoredHearts = CustomHeartAPI.SetPlayerHeartInit(player, index) --hope this stores enough for the others idk
		
		CustomHeartAPI.PlayerHearts[index] = FinalStoredHearts
		CustomHeartAPI.PlayerHeartAnimations[index] = {
			BaseHearts = {},
			SoulHearts = {},
			RedHearts = {},
			BoneHearts = {},
			HasEternal = {},
			GoldenHearts = {}
		}
		CustomHeartAPI.UpdateHeartAnimation(CustomHeartAPI.PlayerHearts[index], index, player) --TO DO: Needs to be placed after custom hearts are updated or something
		return FinalStoredHearts
	end
	
	local OldStoredHearts = CustomHeartAPI.GetStoredHealth(player)
	--First take the new vanilla health
	if maxHealth ~= oldHearts.Max[playerIndex] or redHealth ~= oldHearts.Red[playerIndex] or rottenHealth ~= oldHearts.Rotten[playerIndex] or soulHealth ~= oldHearts.Soul[playerIndex] or evilHealth ~= oldHearts.Evil[playerIndex] or boneHealth ~= oldHearts.Bone[playerIndex] or goldHealth ~= oldHearts.Golden[playerIndex] or eternalHealth ~= oldHearts.Eternal[playerIndex] or brokenHealth ~= oldHearts.Broken[playerIndex] then
		
		if player:GetPlayerType() == 16 or player:GetPlayerType() == 17 then
			if player:GetPlayerType() == 17 then
				SetAndGetHearts(player:GetSubPlayer(), playerIndex)
				SetAndGetHearts(player, playerIndex + 1)
			else
				SetAndGetHearts(player, playerIndex)
				SetAndGetHearts(player:GetSubPlayer(), playerIndex + 1)
			end
		else
			SetAndGetHearts(player, playerIndex)
		end
		
		-- Remember the amount of health the player had currently, to track changes in HP.
		updateOldHearts()
	end
	
	
	--Now update it with the custom hearts
	
    --[[if maxHealth > oldHearts.Max[playerIndex] then
        -- We gained more health.
		Isaac.DebugString((maxHealth - oldHearts.Max[playerIndex])* 0.5)
		CustomHeartAPI.ShiftCustomNonRedHealth(player, (maxHealth - oldHearts[playerIndex].Max[playerIndex]) * 0.5)
		Isaac.DebugString("intothemooooon!")
    elseif maxHealth < oldHearts.Max[playerIndex] then
        -- We lost health.
		Isaac.DebugString((oldHearts[playerIndex].Max[playerIndex] - maxHealth)* 0.5)
		CustomHeartAPI.ShiftCustomNonRedHealth(player, -((oldHearts.Max[playerIndex] - maxHealth) * 0.5))
		Isaac.DebugString("babooom!")
    end]]

    -- Still no valid soul hearts in a slot? Remove that particular slot.
   --[[ for heart_index, heart_info in pairs(playerImmortalHealth[playerIndex]) do
        -- Check if the current immortal heart occupies a slot held by red health. If so, remove the immortal heart and try to refund it.
        if (maxHealth > 0 and heart_index <= (maxHealth * 0.5)) or player:IsBoneHeart(heart_index) then
            playerImmortalHealth[playerIndex][heart_index] = nil
            refundImmortalHeart(player, heart_index)
        end

        -- Check if the current immortal heart occupies a slot where *no* health exists. If so, remove it.
        if heart_index > rightmostHeartIndex then
            playerImmortalHealth[playerIndex][heart_index] = nil
        end
    end]]

end
CustomHeartAPI:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHeartAPI.CheckHeartValidity)

function CustomHeartAPI:GetOrderedHearts(player)
	Isaac.DebugString(tostring(CustomHeartAPI.GetPlayerIndex(player)).."gura makes me sad")
	local currentPlayerType = player:GetPlayerType()
	if player.ControllerIndex == 0 and currentPlayerType == Isaac.GetPlayer(0):GetPlayerType() then
		HeartTable = {}
		playerIndex = 0
	end
	if not CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] then
		if currentPlayerType == PlayerType.PLAYER_THELOST or currentPlayerType == PlayerType.PLAYER_THELOST_B then
			CustomHeartAPI.GetPlayerData(player)["HideHealth"] = true
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_KEEPER or currentPlayerType == PlayerType.PLAYER_KEEPER_B then
			CustomHeartAPI.GetPlayerData(player)["CoinHearts"] = true
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		end
		if currentPlayerType == PlayerType.PLAYER_JACOB then
			CustomHeartAPI.GetPlayerData(player)["TwinCharacter"] = true
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_ESAU or currentPlayerType == PlayerType.PLAYER_THESOUL_B then
			CustomHeartAPI.GetPlayerData(player)["SkipCharacter"] = true
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		elseif currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN_B then
			CustomHeartAPI.GetPlayerData(player)["TForgotten"] = true
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		else 
			CustomHeartAPI.GetPlayerData(player)["HeartTypesChecked"] = true
		end
	end
	if currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN then
		CustomHeartAPI.GetPlayerData(player)["UsesSubPlayer"] = true
		CustomHeartAPI.GetPlayerData(player)["IsSubPlayer"] = false
		--CustomHeartAPI.GetPlayerData(player)["SkipCharacter"] = true
		--print("testo")
		--print(player:GetSoulHearts())
		--print(CustomHeartAPI.GetRedHearts(player))
		--print(player:GetSubPlayer():GetData().Ping)
		--print(player:GetData().Ping)
		--print(player:GetData().CustomHeartAPI_PlayerIndex)
		--print(player:GetSubPlayer():GetData().CustomHeartAPI_PlayerIndex)
		--player:GetData().Ping = true
	elseif currentPlayerType == PlayerType.PLAYER_THESOUL then
		CustomHeartAPI.GetPlayerData(player)["UsesSubPlayer"] = true
		CustomHeartAPI.GetPlayerData(player)["IsSubPlayer"] = true
		--CustomHeartAPI.GetPlayerData(player)["SkipCharacter"] = true
		--print("flippo")
		--print(player:GetSoulHearts())
		--print(CustomHeartAPI.GetRedHearts(player))
		--print(player:GetSubPlayer():GetData().Ping)
		--print(player:GetData().Ping)
		--print(player:GetData().CustomHeartAPI_PlayerIndex)
		--print(player:GetSubPlayer():GetData().CustomHeartAPI_PlayerIndex)
	end
	if CustomHeartAPI.GetPlayerData(player)["TaintedLazA"] then
		local OtherLaz = LazList[(player.ControllerIndex*2)+1]
		Isaac.ConsoleOutput(tostring(OtherLaz).."\n")
		HeartTable[#HeartTable+1] = {player, false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		HeartTable[#HeartTable+1] = {OtherLaz, false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(OtherLaz)]}
	elseif CustomHeartAPI.GetPlayerData(player)["TaintedLazB"] then
		local OtherLaz = LazList[player.ControllerIndex*2]
		Isaac.ConsoleOutput(tostring(OtherLaz).."\n")
		HeartTable[#HeartTable+1] = {player, false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		HeartTable[#HeartTable+1] = {OtherLaz, false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(OtherLaz)]}
	elseif CustomHeartAPI.GetPlayerData(player)["UsesSubPlayer"] and not CustomHeartAPI.GetPlayerData(player)["IsSubPlayer"] then
		HeartTable[#HeartTable+1] = {player, CustomHeartAPI.GetPlayerIndex(player), CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		HeartTable[#HeartTable+1] = {player:GetSubPlayer(), CustomHeartAPI.GetPlayerIndex(player) + 1, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)+1]}
		--print(CustomHeartAPI.GetPlayerIndex(player))
		--[[for i, v in pairs (CustomHeartAPI.PlayerHearts) do
			print(i)
			for k2, v2 in pairs(v) do
				print(k2)
				--print(v2)
			end
		end]]
		print(CustomHeartAPI.GetPlayerIndex(player))
		print(CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)])
		print(CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)+1])
		--[[for i, v in pairs (CustomHeartAPI.PlayerHeartAnimations) do
			Isaac.DebugString(i.."help")
			for k2, v2 in pairs(v) do
				Isaac.DebugString(k2)
				for k3, v3 in pairs(v2) do
					Isaac.DebugString(k3)
					--print(v2)
				end
			end
		end]]
	elseif CustomHeartAPI.GetPlayerData(player)["UsesSubPlayer"] and CustomHeartAPI.GetPlayerData(player)["IsSubPlayer"] then
		HeartTable[#HeartTable+1] = {player, CustomHeartAPI.GetPlayerIndex(player)+1, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)+1]}
		HeartTable[#HeartTable+1] = {player:GetSubPlayer(), CustomHeartAPI.GetPlayerIndex(player), CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		--print(CustomHeartAPI.GetPlayerIndex(player))
		for i, v in pairs (CustomHeartAPI.PlayerHeartAnimations) do
			--Isaac.DebugString(i.."help")
			for k2, v2 in pairs(v) do
			--	Isaac.DebugString(k2)
				for k3, v3 in pairs(v2) do
			--		Isaac.DebugString(k3)
					--print(v2)
				end
			end
		end
	elseif CustomHeartAPI.GetPlayerData(player)["TwinCharacter"] then
		HeartTable[#HeartTable+1] = {player:GetMainTwin(), false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player:GetMainTwin())]}
		HeartTable[#HeartTable+1] = {player:GetOtherTwin(), false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player:GetOtherTwin())]}
	elseif CustomHeartAPI.GetPlayerData(player)["TForgotten"] then
		HeartTable[#HeartTable+1] = {player:GetOtherTwin(), CustomHeartAPI.GetPlayerIndex(player), CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		--HeartTable[#HeartTable+1] = {player, false, {}}
	elseif not CustomHeartAPI.GetPlayerData(player)["SkipCharacter"] then
		HeartTable[#HeartTable+1] = {player, false, CustomHeartAPI.PlayerHearts[CustomHeartAPI.GetPlayerIndex(player)]}
		HeartTable[#HeartTable+1] = {-1}
	end
	playerIndex = playerIndex + 1
	--Isaac.DebugString("oh my pls why are you dumb")
	--Isaac.DebugString(tostring(player:GetMainTwin()))
	--Isaac.DebugString(tostring(player:GetOtherTwin()))
	--Isaac.DebugString(tostring(player:IsSubPlayer()))
	
	for i, v in pairs (CustomHeartAPI.PlayerHeartAnimations) do
		--print(i)
		--[[for k2, v2 in pairs(v) do
			print(k2)
			print(v2)
		end]]
	end
end

function CustomHeartAPI:SetPlayerHeartTypes(player) --sets tags for certain kinds of players
	CustomHeartAPI.GetPlayerData(player)["HideHealth"] = false
	CustomHeartAPI.GetPlayerData(player)["CoinHearts"] = false
	CustomHeartAPI.GetPlayerData(player)["UsesCustomUI"] = false

	CustomHeartAPI.GetPlayerData(player)["TwinCharacter"] = false
	CustomHeartAPI.GetPlayerData(player)["SkipCharacter"] = false
	CustomHeartAPI.GetPlayerData(player)["UsesSubPlayer"] = false
	CustomHeartAPI.GetPlayerData(player)["IsSubPlayer"] = false
	CustomHeartAPI.GetPlayerData(player)["TaintedLazA"] = false
	CustomHeartAPI.GetPlayerData(player)["TaintedLazB"] = false
	CustomHeartAPI.GetPlayerData(player)["TSoul"] = false

	if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS_B then
		LazList[player.ControllerIndex*2] = player
		Isaac.ConsoleOutput(tostring(player).."\n")
		CustomHeartAPI.GetPlayerData(player)["TaintedLazA"] = true
	elseif player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
		LazList[(player.ControllerIndex*2)+1] = player
		Isaac.ConsoleOutput(tostring(player).."\n")
		CustomHeartAPI.GetPlayerData(player)["TaintedLazB"] = true
	end
	
	--Isaac.DebugString(tostring(player:GetPlayerType()).."lol")
end
CustomHeartAPI:AddCallback( ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHeartAPI.GetOrderedHearts)
CustomHeartAPI:AddCallback( ModCallbacks.MC_POST_PLAYER_INIT, CustomHeartAPI.SetPlayerHeartTypes)

--RENDER HEARTS--

VectorZero = Vector.Zero
HeartSprites = Sprite()
HeartSprites:Load("gfx/ui/ui_hearts_custom2.anm2", true)

local HeartPosTable = {
	--top left
	Vector(68, 24), Vector(80, 24), Vector(92, 24), Vector(104, 24), Vector(116, 24), Vector(128, 24),
	Vector(68, 34), Vector(80, 34), Vector(92, 34), Vector(104, 34), Vector(116, 34), Vector(128, 34),
	Vector(140, 34), Vector(152, 34), Vector(164, 34),

	Vector(68, 49), Vector(80, 49), Vector(92, 49), Vector(104, 49), Vector(116, 49), Vector(128, 49),
	Vector(68, 59), Vector(80, 59), Vector(92, 59), Vector(104, 59), Vector(116, 59), Vector(128, 59),
	Vector(140, 69), Vector(152, 69), Vector(164, 69),

	--top right?
	Vector(405, 24), Vector(393, 24), Vector(381, 24), Vector(369, 24), Vector(357, 24), Vector(345, 24),
	Vector(405, 34), Vector(393, 34), Vector(381, 34), Vector(369, 34), Vector(357, 34), Vector(345, 34),
	Vector(333, 34), Vector(321, 34), Vector(309, 34),
	
	Vector(405, 49), Vector(393, 49), Vector(381, 49), Vector(369, 49), Vector(357, 49), Vector(345, 49),
	Vector(405, 59), Vector(393, 59), Vector(381, 59), Vector(369, 59), Vector(357, 59), Vector(345, 59),
	Vector(333, 59), Vector(321, 59), Vector(309, 59),
	
	--bottom left
	Vector(68, 237), Vector(80, 237), Vector(92, 237), Vector(104, 237), Vector(116, 237), Vector(128, 237),
	Vector(68, 247), Vector(80, 247), Vector(92, 247), Vector(104, 247), Vector(116, 247), Vector(128, 247),
	Vector(140, 247), Vector(152, 247), Vector(164, 247),

	Vector(68, 212), Vector(80, 212), Vector(92, 212), Vector(104, 212), Vector(116, 212), Vector(128, 212),
	Vector(68, 222), Vector(80, 222), Vector(92, 222), Vector(104, 222), Vector(116, 222), Vector(128, 222),
	Vector(140, 222), Vector(152, 222), Vector(164, 222),
	
	--bottom right
	Vector(405, 237), Vector(393, 237), Vector(381, 237), Vector(369, 237), Vector(357, 237), Vector(345, 237),
	Vector(405, 247), Vector(393, 247), Vector(381, 247), Vector(369, 247), Vector(357, 247), Vector(345, 247),
	Vector(333, 247), Vector(321, 247), Vector(309, 247),
	
	Vector(405, 212), Vector(393, 212), Vector(381, 212), Vector(369, 212), Vector(357, 212), Vector(345, 212),
	Vector(405, 222), Vector(393, 222), Vector(381, 222), Vector(369, 222), Vector(357, 222), Vector(345, 222),
	Vector(333, 222), Vector(321, 222), Vector(309, 222),
	
	--what is this??
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

local mantleSprite = Sprite()
mantleSprite:Load("gfx/ui/hearts/vanilla/mantle.anm2", true)

function CustomHeartAPI:RenderHearts(shaderName)
	if HeartTable and shaderName == "HeartAPI-HUD" then
		local Strawmen = 0
		local checkedForMantle
		for p,table in pairs(HeartTable) do
			if table[1] ~= -1 then
				local player = table[1]

				local playerIndex = table[2] or CustomHeartAPI.GetPlayerIndex(player)

				if not CustomHeartAPI.GetPlayerData(player)["HideHealth"] and not CustomHeartAPI.GetPlayerData(player)["UsesCustomUI"] then
					if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 and table[3] then
						--mantle indicator					
						for layerId = 0, 7, 1 do
							local name
							if layerId == 0 then
								name = "BaseHearts"
							elseif layerId == 1 then
								name = "SoulHearts"
							elseif layerId == 2 then
								name = "RedHearts"
							elseif layerId == 3 then
								name = "BoneHearts"
							elseif layerId == 4 then
								name = "HasEternal"
							elseif layerId == 5 then
								name = "GoldenHearts"
							end
							local hearts = table[3][name] -- heart contents of the heart layer set, like BaseHearts and stuff
							--	print("test")
						--for name, hearts in pairs(table[3]) do
							--if (name == "BaseHearts" and layerId == 0 ) or (name == "SoulHearts" and layerId == 1 ) or (name == "RedHearts" and layerId == 2 ) or (name == "BoneHearts" and layerId == 3 ) or (name == "HasEternal" and layerId == 4 ) or (name == "GoldenHearts" and layerId == 5 ) then
							if name ~= "HasEternal" and name then
								--Isaac.DebugString(tostring(name)..tostring(name)..tostring(name))
								for i, heart in pairs(hearts) do
									local HeartPos
									if not player.Parent then
										HeartPos = HeartPosTable[i+((p-1-Strawmen)*15)]
									else
										HeartPos = Isaac.WorldToScreen(player.Position) + HeartPosTable[i+8*15]
										Strawmen = Strawmen + 1
										--Isaac.DebugString("yeeeha")
									end
									
									--call the table with the right index to render then pew!
									if CustomHeartAPI.PlayerHeartAnimations[playerIndex][name] then
										local BaseHeartSprites = CustomHeartAPI.PlayerHeartAnimations[playerIndex][name][i]
										if BaseHeartSprites then
											BaseHeartSprites:SetFrame("Heart", heart.health)
											BaseHeartSprites:Render(HeartPos, VectorZero, VectorZero)
										end
									end
								end
							else
								local boolean = hearts
								if boolean then
									--print(boolean)
									local HeartPos
									local i= player:GetMaxHearts()/2
									if not player.Parent then
										HeartPos = HeartPosTable[i+((p-1-Strawmen)*15)]
									else
										HeartPos = Isaac.WorldToScreen(player.Position) + HeartPosTable[i+8*15]
										Strawmen = Strawmen + 1
										--Isaac.DebugString("yeeeha")
									end
									if CustomHeartAPI.PlayerHeartAnimations[playerIndex][name] then
										local BaseHeartSprites = CustomHeartAPI.PlayerHeartAnimations[playerIndex][name]
										BaseHeartSprites:SetFrame("Heart", 0)
										BaseHeartSprites:Render(HeartPos, VectorZero, VectorZero)
									end
								end
							end
							if layerId == 7 and player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) then --mantle check
								local limit = CustomHeartAPI.GetHeartLimit(player) 
								local i= player:GetMaxHearts()/2
								local extraOffset = VectorZero
								if i < limit then
									i = i + 1
								else
									extraOffset = Vector(3,3)
								end
								local HeartPos
								if not player.Parent then
									HeartPos = HeartPosTable[i+((p-1-Strawmen)*15)]
								else
									HeartPos = Isaac.WorldToScreen(player.Position) + HeartPosTable[i+8*15]
									Strawmen = Strawmen + 1
									--Isaac.DebugString("yeeeha")
								end
								if mantleSprite then
									local BaseHeartSprites = mantleSprite
									BaseHeartSprites:SetFrame("Heart", 2)
									BaseHeartSprites:Render(HeartPos + extraOffset, VectorZero, VectorZero)
								end
							end
						end
					else
					--[[	local HeartPos
						if not player.Parent then
							HeartPos = HeartPosTable[1+((p-1-Strawmen)*15)]
						else
							HeartPos = Isaac.WorldToScreen(player.Position) + Vector(0, -35)
							Strawmen = Strawmen + 1
						end
						HeartSprites:Play("CurseHeart", true)
						HeartSprites:Render(HeartPos, VectorZero, VectorZero)]]
					end
				end
			end
		end
	end
end
CustomHeartAPI:AddCallback( ModCallbacks.MC_GET_SHADER_PARAMS, CustomHeartAPI.RenderHearts)