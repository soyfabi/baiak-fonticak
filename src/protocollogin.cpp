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

#include "protocollogin.h"

#include "outputmessage.h"
#include "tasks.h"

#include "configmanager.h"
#include "iologindata.h"
#include "ban.h"
#include <iomanip>
#include "game.h"
#include "tools.h"

#include <fmt/format.h>

extern ConfigManager g_config;
extern Game g_game;

void ProtocolLogin::disconnectClient(const std::string& message)
{
	auto output = OutputMessagePool::getOutputMessage();
	output->addByte(0x0A);
	output->addString(message);
	send(output);
	disconnect();
}

void ProtocolLogin::getCharacterList(const std::string& accountName, const std::string& password)
{
	Account account;
	if (!IOLoginData::loginserverAuthentication(accountName, password, account)) {
		disconnectClient("Account name or password is not correct.");
		return;
	}

	auto output = OutputMessagePool::getOutputMessage();

	const std::string& motd = g_config.getString(ConfigManager::MOTD);
	if (!motd.empty()) {
		//Add MOTD
		output->addByte(0x14);
		output->addString(fmt::format("{:d}\n{:s}", g_game.getMotdNum(), motd));
	}

	//Add char list
	output->addByte(0x64);

	uint8_t size = std::min<size_t>(std::numeric_limits<uint8_t>::max(), account.characters.size());
	output->addByte(size);
	for (uint8_t i = 0; i < size; i++) {
		output->addString(account.characters[i]);
		output->addString(g_config.getString(ConfigManager::SERVER_NAME));
		output->add<uint32_t>(g_config.getNumber(ConfigManager::IP));
		output->add<uint16_t>(g_config.getNumber(ConfigManager::GAME_PORT));
	}

	//Add premium days
	if (g_config.getBoolean(ConfigManager::FREE_PREMIUM)) {
		output->add<uint16_t>(0xFFFF); //client displays free premium
	} else {
		output->add<uint16_t>(std::max<time_t>(0, account.premiumEndsAt - time(nullptr)) / 86400);
	}

	send(output);

	disconnect();
}

void ProtocolLogin::getCastList(const std::string& password)
{
	const auto& casts = IOLoginData::getCastList(password);
	if (casts.empty()) {
		disconnectClient("There are no casts available at this time.");
		return;
	}

	auto output = OutputMessagePool::getOutputMessage();

	//Add MOTD
	output->addByte(0x14);
	output->addString(fmt::format("{:d}\n{:s}", normal_random(1, 255), "                    !-Welcome to Cast System-!\n\nIt will show all active casts even with password.\n\nTo enter a cast with password you just have to\nput the password in the empty space.\n\nRemember that when you open cast without\npassword you will get 10% of Exp.\n\nAlso remember that to open cast, just say !cast on."));

	//Add char list
	output->addByte(0x64);

	uint8_t limit = std::numeric_limits<uint8_t>::max();
	output->addByte(std::min<uint8_t>(limit, casts.size()));

	for (const auto& it : casts) {
		if (limit == 0) {
			break;
		}

		output->addString(it.first);
		output->addString(it.second);
		output->add<uint32_t>(g_config.getNumber(ConfigManager::IP));
		output->add<uint16_t>(g_config.getNumber(ConfigManager::GAME_PORT));
	}

	//Add premium days
	output->add<uint16_t>(0xFFFF);

	send(output);

	disconnect();
}

void ProtocolLogin::onRecvFirstMessage(NetworkMessage& msg)
{
	if (g_game.getGameState() == GAME_STATE_SHUTDOWN) {
		disconnect();
		return;
	}

	msg.skipBytes(2); // client OS

	uint16_t version = msg.get<uint16_t>();
	msg.skipBytes(12);
	/*
	 * Skipped bytes:
	 * 4 bytes: protocolVersion
	 * 12 bytes: dat, spr, pic signatures (4 bytes each)
	 * 1 byte: 0
	 */

	if (version <= 760) {
		disconnectClient(fmt::format("Only clients with protocol {:s} allowed!", CLIENT_VERSION_STR));
		return;
	}
	
	// OTCv8 version detection
	//Allow access only from OTCV8
	
	/*uint16_t otclientV8 = 0;
	uint16_t otcV8StringLength = msg.get<uint16_t>();
	if(otcV8StringLength == 5 && msg.getString(5) == "OTCv8") {
		otclientV8 = msg.get<uint16_t>(); // 253, 260, 261, ...
	}*/
	
	if (!Protocol::RSA_decrypt(msg)) {
		disconnect();
		return;
	}

	xtea::key key;
	key[0] = msg.get<uint32_t>();
	key[1] = msg.get<uint32_t>();
	key[2] = msg.get<uint32_t>();
	key[3] = msg.get<uint32_t>();
	enableXTEAEncryption();
	setXTEAKey(std::move(key));

	if (version < CLIENT_VERSION_MIN || version > CLIENT_VERSION_MAX) {
		disconnectClient(fmt::format("Only clients with protocol {:s} allowed!", CLIENT_VERSION_STR));
		return;
	}

	if (g_game.getGameState() == GAME_STATE_STARTUP) {
		disconnectClient("Gameworld is starting up. Please wait.");
		return;
	}

	if (g_game.getGameState() == GAME_STATE_MAINTAIN) {
		disconnectClient("Gameworld is under maintenance.\nPlease re-connect in a while.");
		return;
	}
	
	if (g_config.getBoolean(ConfigManager::BLOCK_LOGIN)) {
		const std::string customMessage = g_config.getString(ConfigManager::BLOCK_LOGIN_TEXT);
		disconnectClient(customMessage);
		return;
	}

	BanInfo banInfo;
	auto connection = getConnection();
	if (!connection) {
		return;
	}

	if (IOBan::isIpBanned(connection->getIP(), banInfo)) {
		if (banInfo.reason.empty()) {
			banInfo.reason = "(none)";
		}

		disconnectClient(fmt::format("Your IP has been banned until {:s} by {:s}.\n\nReason specified:\n{:s}", formatDateShort(banInfo.expiresAt), banInfo.bannedBy, banInfo.reason));
		return;
	}
	
	std::string accountName = msg.getString();
	std::string password = msg.getString();

	auto thisPtr = std::static_pointer_cast<ProtocolLogin>(shared_from_this());
	if (accountName.empty()) {
		g_dispatcher.addTask(createTask(std::bind(&ProtocolLogin::getCastList, thisPtr, password)));
	} else {
		g_dispatcher.addTask(createTask(std::bind(&ProtocolLogin::getCharacterList, thisPtr, accountName, password)));
	}
}
