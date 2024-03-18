/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "otpch.h"

#include <algorithm>
#if __has_include("luajit/lua.hpp")
#include <luajit/lua.hpp>
#else
#include <lua.hpp>
#endif

#include "configmanager.h"
#include "game.h"
#include "monster.h"
#include "pugicast.h"

#if LUA_VERSION_NUM >= 502
#undef lua_strlen
#define lua_strlen lua_rawlen
#endif

extern Game g_game;

namespace {

std::string getGlobalString(lua_State* L, const char* identifier, const char* defaultValue)
{
	lua_getglobal(L, identifier);
	if (!lua_isstring(L, -1)) {
		lua_pop(L, 1);
		return defaultValue;
	}

	size_t len = lua_strlen(L, -1);
	std::string ret(lua_tostring(L, -1), len);
	lua_pop(L, 1);
	return ret;
}

int32_t getGlobalNumber(lua_State* L, const char* identifier, const int32_t defaultValue = 0)
{
	lua_getglobal(L, identifier);
	if (!lua_isnumber(L, -1)) {
		lua_pop(L, 1);
		return defaultValue;
	}

	int32_t val = lua_tonumber(L, -1);
	lua_pop(L, 1);
	return val;
}

bool getGlobalBoolean(lua_State* L, const char* identifier, const bool defaultValue)
{
	lua_getglobal(L, identifier);
	if (!lua_isboolean(L, -1)) {
		if (!lua_isstring(L, -1)) {
			lua_pop(L, 1);
			return defaultValue;
		}

		size_t len = lua_strlen(L, -1);
		std::string ret(lua_tostring(L, -1), len);
		lua_pop(L, 1);
		return booleanString(ret);
	}

	int val = lua_toboolean(L, -1);
	lua_pop(L, 1);
	return val != 0;
}

float getGlobalFloat(lua_State* L, const char* identifier, const float defaultValue = 0.0f)
{
	lua_getglobal(L, identifier);
	if (!lua_isnumber(L, -1)) {
		lua_pop(L, 1);
		return defaultValue;
	}

	float val = lua_tonumber(L, -1);
	lua_pop(L, 1);
	return val;
}

}

ConfigManager::ConfigManager()
{
	string[CONFIG_FILE] = "config.lua";
}

namespace {

ExperienceStages loadLuaStages(lua_State* L)
{
	ExperienceStages stages;

	lua_getglobal(L, "experienceStages");
	if (!lua_istable(L, -1)) {
		return {};
	}

	lua_pushnil(L);
	while (lua_next(L, -2) != 0) {
		const auto tableIndex = lua_gettop(L);
		auto minLevel = LuaScriptInterface::getField<uint32_t>(L, tableIndex, "minlevel", 1);
		auto maxLevel = LuaScriptInterface::getField<uint32_t>(L, tableIndex, "maxlevel", std::numeric_limits<uint32_t>::max());
		auto multiplier = LuaScriptInterface::getField<float>(L, tableIndex, "multiplier", 1);
		stages.emplace_back(minLevel, maxLevel, multiplier);
		lua_pop(L, 4);
	}
	lua_pop(L, 1);

	std::sort(stages.begin(), stages.end());
	return stages;
}

ExperienceStages loadXMLStages()
{
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/stages.xml");
	if (!result) {
		printXMLError("Error - loadXMLStages", "data/XML/stages.xml", result);
		return {};
	}

	ExperienceStages stages;
	for (auto stageNode : doc.child("stages").children()) {
		if (strcasecmp(stageNode.name(), "config") == 0) {
			if (!stageNode.attribute("enabled").as_bool()) {
				return {};
			}
		} else {
			uint32_t minLevel = 1, maxLevel = std::numeric_limits<uint32_t>::max(), multiplier = 1;

			if (auto minLevelAttribute = stageNode.attribute("minlevel")) {
				minLevel = pugi::cast<uint32_t>(minLevelAttribute.value());
			}

			if (auto maxLevelAttribute = stageNode.attribute("maxlevel")) {
				maxLevel = pugi::cast<uint32_t>(maxLevelAttribute.value());
			}

			if (auto multiplierAttribute = stageNode.attribute("multiplier")) {
				multiplier = pugi::cast<uint32_t>(multiplierAttribute.value());
			}

			stages.emplace_back(minLevel, maxLevel, multiplier);
		}
	}

	std::sort(stages.begin(), stages.end());
	return stages;
}

}

bool ConfigManager::load()
{
	lua_State* L = luaL_newstate();
	if (!L) {
		throw std::runtime_error("Failed to allocate memory");
	}

	luaL_openlibs(L);

	if (luaL_dofile(L, getString(CONFIG_FILE).c_str())) {
		std::cout << "[Error - ConfigManager::load] " << lua_tostring(L, -1) << std::endl;
		lua_close(L);
		return false;
	}

	//parse config
	if (!loaded) { //info that must be loaded one time (unless we reset the modules involved)
		boolean[BIND_ONLY_GLOBAL_ADDRESS] = getGlobalBoolean(L, "bindOnlyGlobalAddress", false);
		boolean[OPTIMIZE_DATABASE] = getGlobalBoolean(L, "startupDatabaseOptimization", true);

		if (string[IP_STRING] == "") {
			string[IP_STRING] = getGlobalString(L, "ip", "127.0.0.1");
		}

		string[MAP_NAME] = getGlobalString(L, "mapName", "forgotten");
		string[MAP_AUTHOR] = getGlobalString(L, "mapAuthor", "Unknown");
		string[HOUSE_RENT_PERIOD] = getGlobalString(L, "houseRentPeriod", "never");
		string[MYSQL_HOST] = getGlobalString(L, "mysqlHost", "127.0.0.1");
		string[MYSQL_USER] = getGlobalString(L, "mysqlUser", "forgottenserver");
		string[MYSQL_PASS] = getGlobalString(L, "mysqlPass", "");
		string[MYSQL_DB] = getGlobalString(L, "mysqlDatabase", "forgottenserver");
		string[MYSQL_SOCK] = getGlobalString(L, "mysqlSock", "");

		std::string ipString = string[IP_STRING];
		uint32_t ip = inet_addr(ipString.c_str());
		if (ip == INADDR_NONE) {
			hostent* hostname = gethostbyname(ipString.c_str());
			if (hostname) {
				ipString = std::string(inet_ntoa(**(in_addr**)hostname->h_addr_list));
				ip = inet_addr(ipString.c_str());
			}
		}

		if (ip == INADDR_NONE) {
			std::cout << "[Error - ConfigManager::load] cannot resolve given ip address, make sure you typed correct IP or hostname." << std::endl;
			lua_close(L);
			return false;
		}

		integer[IP] = ip;
		integer[SQL_PORT] = getGlobalNumber(L, "mysqlPort", 3306);

		if (integer[GAME_PORT] == 0) {
			integer[GAME_PORT] = getGlobalNumber(L, "gameProtocolPort", 7172);
		}

		if (integer[LOGIN_PORT] == 0) {
			integer[LOGIN_PORT] = getGlobalNumber(L, "loginProtocolPort", 7171);
		}

		integer[STATUS_PORT] = getGlobalNumber(L, "statusProtocolPort", 7171);
	}

	boolean[ALLOW_CHANGEOUTFIT] = getGlobalBoolean(L, "allowChangeOutfit", true);
	boolean[ONE_PLAYER_ON_ACCOUNT] = getGlobalBoolean(L, "onePlayerOnlinePerAccount", true);
	boolean[AIMBOT_HOTKEY_ENABLED] = getGlobalBoolean(L, "hotkeyAimbotEnabled", true);
	boolean[REMOVE_RUNE_CHARGES] = getGlobalBoolean(L, "removeChargesFromRunes", true);
	boolean[REMOVE_WEAPON_AMMO] = getGlobalBoolean(L, "removeWeaponAmmunition", true);
	boolean[REMOVE_WEAPON_CHARGES] = getGlobalBoolean(L, "removeWeaponCharges", true);
	boolean[REMOVE_POTION_CHARGES] = getGlobalBoolean(L, "removeChargesFromPotions", true);
	boolean[PZLOCK_SKULL_ATTACKER] = getGlobalBoolean(L, "pzLockSkullAttacker", false);
	boolean[EXPERIENCE_FROM_PLAYERS] = getGlobalBoolean(L, "experienceByKillingPlayers", false);
	boolean[FREE_PREMIUM] = getGlobalBoolean(L, "freePremium", false);
	boolean[REPLACE_KICK_ON_LOGIN] = getGlobalBoolean(L, "replaceKickOnLogin", true);
	boolean[ALLOW_CLONES] = getGlobalBoolean(L, "allowClones", false);
	boolean[ALLOW_WALKTHROUGH] = getGlobalBoolean(L, "allowWalkthrough", true);
	boolean[EMOTE_SPELLS] = getGlobalBoolean(L, "emoteSpells", false);
	boolean[STAMINA_SYSTEM] = getGlobalBoolean(L, "staminaSystem", true);
	boolean[WARN_UNSAFE_SCRIPTS] = getGlobalBoolean(L, "warnUnsafeScripts", true);
	boolean[CONVERT_UNSAFE_SCRIPTS] = getGlobalBoolean(L, "convertUnsafeScripts", true);
	boolean[CLASSIC_EQUIPMENT_SLOTS] = getGlobalBoolean(L, "classicEquipmentSlots", false);
	boolean[CLASSIC_ATTACK_SPEED] = getGlobalBoolean(L, "classicAttackSpeed", false);
	boolean[SCRIPTS_CONSOLE_LOGS] = getGlobalBoolean(L, "showScriptsLogInConsole", true);
	boolean[SERVER_SAVE_NOTIFY_MESSAGE] = getGlobalBoolean(L, "serverSaveNotifyMessage", true);
	boolean[SERVER_SAVE_CLEAN_MAP] = getGlobalBoolean(L, "serverSaveCleanMap", false);
	boolean[SERVER_SAVE_CLOSE] = getGlobalBoolean(L, "serverSaveClose", false);
	boolean[SERVER_SAVE_SHUTDOWN] = getGlobalBoolean(L, "serverSaveShutdown", true);
	boolean[ONLINE_OFFLINE_CHARLIST] = getGlobalBoolean(L, "showOnlineStatusInCharlist", false);
	boolean[YELL_ALLOW_PREMIUM] = getGlobalBoolean(L, "yellAlwaysAllowPremium", false);
	boolean[PREMIUM_TO_SEND_PRIVATE] = getGlobalBoolean(L, "premiumToSendPrivate", false);
	boolean[FORCE_MONSTERTYPE_LOAD] = getGlobalBoolean(L, "forceMonsterTypesOnLoad", true);
	boolean[DEFAULT_WORLD_LIGHT] = getGlobalBoolean(L, "defaultWorldLight", true);
	boolean[HOUSE_OWNED_BY_ACCOUNT] = getGlobalBoolean(L, "houseOwnedByAccount", false);
	boolean[LUA_ITEM_DESC] = getGlobalBoolean(L, "luaItemDesc", false);
	boolean[CLEAN_PROTECTION_ZONES] = getGlobalBoolean(L, "cleanProtectionZones", false);
	boolean[HOUSE_DOOR_SHOW_PRICE] = getGlobalBoolean(L, "houseDoorShowPrice", true);
	boolean[ONLY_INVITED_CAN_MOVE_HOUSE_ITEMS] = getGlobalBoolean(L, "onlyInvitedCanMoveHouseItems", true);
	boolean[REMOVE_ON_DESPAWN] = getGlobalBoolean(L, "removeOnDespawn", true);
	boolean[SORT_LOOT_BY_CHANCE] = getGlobalBoolean(L, "sortLootByChance", false);
	boolean[STAMINA_TRAINER] = getGlobalBoolean(L, "staminaTrainer", false);
	boolean[STAMINA_PZ] = getGlobalBoolean(L, "staminaPz", false);
	boolean[BLOCK_LOGIN] = getGlobalBoolean(L, "blockLogin", false);
	boolean[SHOW_PACKETS] = getGlobalBoolean(L, "showPackets", false);
	boolean[NPCS_USING_BANK_MONEY] = getGlobalBoolean(L, "npcsUsingBankMoney", false);

	string[DEFAULT_PRIORITY] = getGlobalString(L, "defaultPriority", "high");
	string[SERVER_NAME] = getGlobalString(L, "serverName", "");
	string[OWNER_NAME] = getGlobalString(L, "ownerName", "");
	string[OWNER_EMAIL] = getGlobalString(L, "ownerEmail", "");
	string[URL] = getGlobalString(L, "url", "");
	string[LOCATION] = getGlobalString(L, "location", "");
	string[MOTD] = getGlobalString(L, "motd", "");
	string[WORLD_TYPE] = getGlobalString(L, "worldType", "pvp");
	string[BLOCK_LOGIN_TEXT] = getGlobalString(L, "blockLoginText", "Server is closed for bug fixing.");

	integer[MAX_PLAYERS] = getGlobalNumber(L, "maxPlayers");
	integer[PZ_LOCKED] = getGlobalNumber(L, "pzLocked", 60000);
	integer[DEFAULT_DESPAWNRANGE] = Monster::despawnRange = getGlobalNumber(L, "deSpawnRange", 2);
	integer[DEFAULT_DESPAWNRADIUS] = Monster::despawnRadius = getGlobalNumber(L, "deSpawnRadius", 50);
	integer[DEFAULT_WALKTOSPAWNRADIUS] = getGlobalNumber(L, "walkToSpawnRadius", 15);
	integer[RATE_EXPERIENCE] = getGlobalNumber(L, "rateExp", 5);
	integer[RATE_SKILL] = getGlobalNumber(L, "rateSkill", 3);
	integer[RATE_LOOT] = getGlobalNumber(L, "rateLoot", 2);
	integer[RATE_MAGIC] = getGlobalNumber(L, "rateMagic", 3);
	integer[SPAWN_MULTIPLIER] = getGlobalNumber(L, "spawnMultiplier", 1);
	integer[HOUSE_PRICE] = getGlobalNumber(L, "housePriceEachSQM", 1000);
	integer[RED_DAILY_LIMIT] = getGlobalNumber(L, "redDailyLimit", 3);
	integer[RED_WEEKLY_LIMIT] = getGlobalNumber(L, "redWeeklyLimit", 5);
	integer[RED_MONTHLY_LIMIT] = getGlobalNumber(L, "redMonthlyLimit", 10);
	integer[RED_SKULL_LENGTH] = getGlobalNumber(L, "redSkullLength", 30 * 24 * 60 * 60);
	integer[BLACK_DAILY_LIMIT] = getGlobalNumber(L, "blackDailyLimit", 6);
	integer[BLACK_WEEKLY_LIMIT] = getGlobalNumber(L, "blackWeeklyLimit", 10);
	integer[BLACK_MONTHLY_LIMIT] = getGlobalNumber(L, "blackMonthlyLimit", 20);
	integer[BLACK_SKULL_LENGTH] = getGlobalNumber(L, "blackSkullLength", 45 * 24 * 60 * 60);
	integer[MAX_MESSAGEBUFFER] = getGlobalNumber(L, "maxMessageBuffer", 4);
	integer[PROTECTION_LEVEL] = getGlobalNumber(L, "protectionLevel", 1);
	integer[DEATH_LOSE_PERCENT] = getGlobalNumber(L, "deathLosePercent", -1);
	integer[STATUSQUERY_TIMEOUT] = getGlobalNumber(L, "statusTimeout", 5000);
	integer[WHITE_SKULL_TIME] = getGlobalNumber(L, "whiteSkullTime", 15 * 60);
	integer[STAIRHOP_DELAY] = getGlobalNumber(L, "stairJumpExhaustion", 2000);
	integer[EXP_FROM_PLAYERS_LEVEL_RANGE] = getGlobalNumber(L, "expFromPlayersLevelRange", 75);
	integer[MAX_PACKETS_PER_SECOND] = getGlobalNumber(L, "maxPacketsPerSecond", 25);
	integer[SERVER_SAVE_NOTIFY_DURATION] = getGlobalNumber(L, "serverSaveNotifyDuration", 5);
	integer[YELL_MINIMUM_LEVEL] = getGlobalNumber(L, "yellMinimumLevel", 2);
	integer[MINIMUM_LEVEL_TO_SEND_PRIVATE] = getGlobalNumber(L, "minimumLevelToSendPrivate", 1);
	integer[VIP_FREE_LIMIT] = getGlobalNumber(L, "vipFreeLimit", 20);
	integer[VIP_PREMIUM_LIMIT] = getGlobalNumber(L, "vipPremiumLimit", 100);
	integer[DEPOT_FREE_LIMIT] = getGlobalNumber(L, "depotFreeLimit", 2000);
	integer[DEPOT_PREMIUM_LIMIT] = getGlobalNumber(L, "depotPremiumLimit", 10000);
	integer[PROTECTION_TIME] = getGlobalNumber(L, "protectionTime", 10);
	integer[STAMINA_REGEN_MINUTE] = getGlobalNumber(L, "timeToRegenMinuteStamina", 3 * 60);
	integer[STAMINA_REGEN_PREMIUM] = getGlobalNumber(L, "timeToRegenMinutePremiumStamina", 10 * 60);
	integer[STAMINA_PZ_GAIN] = getGlobalNumber(L, "staminaPzGain", 1);
	integer[STAMINA_ORANGE_DELAY] = getGlobalNumber(L, "staminaOrangeDelay", 1);
	integer[STAMINA_GREEN_DELAY] = getGlobalNumber(L, "staminaGreenDelay", 5);
	integer[STAMINA_TRAINER_DELAY] = getGlobalNumber(L, "staminaTrainerDelay", 5);
	integer[STAMINA_TRAINER_GAIN] = getGlobalNumber(L, "staminaTrainerGain", 1);
	integer[RATE_START_EFFECT] = getGlobalNumber(L, "timeStartEffect", 4200);
	integer[RATE_BETWEEN_EFFECT] = getGlobalNumber(L, "timeBetweenTeleportEffects", 1400);
	integer[MAX_ALLOWED_ON_A_DUMMY] = getGlobalNumber(L, "maxAllowedOnADummy", 5);
	integer[RATE_EXERCISE_TRAINING_SPEED] = getGlobalNumber(L, "rateExerciseTrainingSpeed", 1.0);
	integer[MAGIC_WALL_ID] = getGlobalNumber(L, "magicWallId", 2129);
	integer[OLD_MAGIC_WALL_ID] = getGlobalNumber(L, "oldMagicWallId", 2130);
	integer[MAGIC_WALL_STORAGE] = getGlobalNumber(L, "magicWallStorage", 90000);
	integer[STORAGEVALUE_EMOTE] = getGlobalNumber(L, "emoteStorage", 90001);
	integer[NPCS_SHOP_DELAY] = getGlobalNumber(L, "npcsShopDelay", 400);
	
	//Floating Config
	floating[MLVL_BONUSDMG] = getGlobalFloat(L, "monsterBonusDamage", 0);
	floating[MLVL_BONUSSPEED] = getGlobalFloat(L, "monsterBonusSpeed", 0);
	floating[MLVL_BONUSHP] = getGlobalFloat(L, "monsterBonusHealth", 0);
	
	floating[RATE_HEALTH_REGEN] = getGlobalFloat(L, "rateHealthRegen", 1.0);
	floating[RATE_HEALTH_REGEN_SPEED] = getGlobalFloat(L, "rateHealthRegenSpeed", 1.0);
	floating[RATE_MANA_REGEN] = getGlobalFloat(L, "rateManaRegen", 1.0);
	floating[RATE_MANA_REGEN_SPEED] = getGlobalFloat(L, "rateManaRegenSpeed", 1.0);
	floating[RATE_SOUL_REGEN] = getGlobalFloat(L, "rateSoulRegen", 1.0);
	floating[RATE_SOUL_REGEN_SPEED] = getGlobalFloat(L, "rateSoulRegenSpeed", 1.0);
	floating[RATE_ATTACK_SPEED] = getGlobalFloat(L, "rateAttackSpeed", 1.0);
	
	floating[RATE_SPELL_COOLDOWN] = getGlobalFloat(L, "rateSpellCooldown", 1.0);
		
	expStages = loadXMLStages();
	if (expStages.empty()) {
		expStages = loadLuaStages(L);
	} else {
		std::cout << "[Warning - ConfigManager::load] XML stages are deprecated, consider moving to config.lua." << std::endl;
	}
	expStages.shrink_to_fit();

	loaded = true;
	lua_close(L);

	return true;
}

bool ConfigManager::reload()
{
	bool result = load();
	if (transformToSHA1(getString(ConfigManager::MOTD)) != g_game.getMotdHash()) {
		g_game.incrementMotdNum();
	}
	return result;
}

static std::string dummyStr;

const std::string& ConfigManager::getString(string_config_t what) const
{
	if (what >= LAST_STRING_CONFIG) {
		std::cout << "[Warning - ConfigManager::getString] Accessing invalid index: " << what << std::endl;
		return dummyStr;
	}
	return string[what];
}

int32_t ConfigManager::getNumber(integer_config_t what) const
{
	if (what >= LAST_INTEGER_CONFIG) {
		std::cout << "[Warning - ConfigManager::getNumber] Accessing invalid index: " << what << std::endl;
		return 0;
	}
	return integer[what];
}

bool ConfigManager::getBoolean(boolean_config_t what) const
{
	if (what >= LAST_BOOLEAN_CONFIG) {
		std::cout << "[Warning - ConfigManager::getBoolean] Accessing invalid index: " << what << std::endl;
		return false;
	}
	return boolean[what];
}

float ConfigManager::getFloat(floating_config_t what) const
{
	if (what >= LAST_FLOATING_CONFIG) {
		std::cout << "[Warning - ConfigManager::getFloat] Accessing invalid index: " << what << std::endl;
		return 0.0f;
	}
	return floating[what];
}


float ConfigManager::getExperienceStage(uint32_t level) const
{
	auto it = std::find_if(expStages.begin(), expStages.end(), [level](auto&& stage) {
		auto&& [minLevel, maxLevel, _] = stage;
		return level >= minLevel && level <= maxLevel;
	});

	if (it == expStages.end()) {
		return getNumber(ConfigManager::RATE_EXPERIENCE);
	}

	return std::get<2>(*it);
}

bool ConfigManager::setString(string_config_t what, const std::string& value)
{
	if (what >= LAST_STRING_CONFIG) {
		std::cout << "[Warning - ConfigManager::setString] Accessing invalid index: " << what << std::endl;
		return false;
	}

	string[what] = value;
	return true;
}

bool ConfigManager::setNumber(integer_config_t what, int32_t value)
{
	if (what >= LAST_INTEGER_CONFIG) {
		std::cout << "[Warning - ConfigManager::setNumber] Accessing invalid index: " << what << std::endl;
		return false;
	}

	integer[what] = value;
	return true;
}

bool ConfigManager::setBoolean(boolean_config_t what, bool value)
{
	if (what >= LAST_BOOLEAN_CONFIG) {
		std::cout << "[Warning - ConfigManager::setBoolean] Accessing invalid index: " << what << std::endl;
		return false;
	}

	boolean[what] = value;
	return true;
}
