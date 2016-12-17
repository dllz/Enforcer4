local function get_mods_id(chat_id)
	local res = api.getChatAdministrators(chat_id)
	if not res then return false end
	local ids = {}
	for i,admin in pairs(res.result) do
		local uname = admin.user.username
		--print(admin.user.first_name, uname)
		if uname ~= nil then
			--print(admin.user.first_name, uname)
			--print("110101010")
			if not uname:find('bot', -3) then
				--print("y49")
				table.insert(ids, admin.user.id)
			end
		else
			print(admin.user.first_name, uname)
			table.insert(ids, admin.user.id)
		end
	end
	--print("Collected number"..#ids)
	return ids
end

local function is_report_blocked(msg)
	--print('0')
	local hash = 'chat:'..msg.chat.id..':reportblocked'
	--print("01111")
	return db:sismember(hash, msg.from.id)
end

local function send_to_admin(mods, chat, msg_id, reporter, is_by_reply, chat_title, msg, reportid, username, message)
	counter = 0
	result = {}
	adminID = {}
	--print("Sending mods"..#mods)
	local count403 = 0
	local admin = "your admins "
	for i=1,#mods do
		--print('1001'..i)
		api.forwardMessage(mods[i], chat, msg_id)
		--print('101'..i)
		local temp
		--print("MOD ID:"..mods[i])
		if username ~= nil then
			if message.reply then
				temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: #r'..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Ban', callback_data = 'banflag:'..message.chat.id..':'..msg.reply.from.id},{text = 'Kick', callback_data = 'kickflag:'..message.chat.id..':'..msg.reply.from.id}},{{text = 'Warn', callback_data = 'warnflag:'..message.chat.id..':'..msg.reply.from.id},{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}},{{text = 'Go to message', url = 'http://telegram.me/'..username..'/'..reportid}}}})
				--temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: '..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}}}})
			else
				temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: #r'..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}},{{text = 'Go to message', url = 'http://telegram.me/'..username..'/'..reportid}}}})
				--temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: '..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}}}})
			end
		else
			if message.reply then
				temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: #r'..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Ban', callback_data = 'banflag:'..message.chat.id..':'..msg.reply.from.id},{text = 'Kick', callback_data = 'kickflag:'..message.chat.id..':'..msg.reply.from.id}},{{text = 'Warn', callback_data = 'warnflag:'..message.chat.id..':'..msg.reply.from.id},{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}}}})
				--temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: '..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}}}})
			else
				temp, code = api.sendKeyboard(mods[i], reporter..'\n\n'..chat_title..'\nReport ID: #r'..reportid..'\n#Unsolved', {inline_keyboard = {{{text = 'Mark Solved', callback_data = 'solveflag:'..message.chat.id..':'..reportid}}}})
			end
		end
		--print("CODE: ", code)
		--print("DATADUMP:", dump(temp))
		if temp ~= false and code == nil then
			result[i] = temp.result.message_id
			counter = counter + 1
			adminID[i] = temp.result.chat.id
			--print("Admin ID", adminID[i])
			--print("Entry count ", result[i])
		elseif code == 403 then
			count403 = count403 + 1
			local temp = db:hget("bot:ids", mods[i])
			if temp ~= nil then
				admin = admin..db:hget("bot:ids",mods[i]).." "
				-- print(admin)
			end

		end
	end
	if count403 >= 1 then
		api.sendReply(msg, "Please tell "..admin.." to start @werewolfbutlerbot so that they can receive reports")
		api.sendLog("403: Bot could not send a flagged message to admins\nNotified "..admin.." in "..chat_title.." "..chat)
	end

	--print(result[1], result[2], result[3], result[4])
	hash10 = 'flagged:'..msg.chat.id..':'..msg.message_id
	--print("check 2")
	--api.sendReply(msg,'MessageID: '..msg.message_id..' '..os.date('!%c (UCT)'))
	local timer = os.date('!%c (UCT)')
	alreadyReported = db:hget(hash10, 'Solved')
	--print("Reprorteorijt", alreadyReported)
	if alreadyReported == nil then
		--print("sigh ", counter)
		for o=1, counter, 1 do
			local sentMsgID = result[o]
			local id = adminID[o]
			--print("Count ", o)
			--print('Database Setting Reached')
			--print(sentMsgID)
			--print(id)
			if id ~= nil then
				--print(id)
				if sentMsgID ~= nil then
					--print(sentMsgID)
					db:hset(hash10, 'Message'..o, sentMsgID)
					db:hset(hash10, 'adminID'..o, id)
				end
			end
		end
		db:hset(hash10, 'Solved', 0)
		db:hset(hash10, 'Created', timer)
		db:hset(hash10, '#Admin', counter)
		db:hset(hash10, 'Reporter', reporter)
		db:hset(hash10, 'repID', reportid)
	end
end

local action = function(msg, blocks, ln)

	local hash = 'chat:'..msg.chat.id..':reportblocked'
	if blocks[1] == 'admin' then
		--return
		--if 'report' is locked, if is a mod or if the user is blocked from using @admin
		if is_locked(msg, 'Report') or is_mod(msg) or is_report_blocked(msg) then
			return
		end
		if not blocks[2] and not msg.reply then
			api.sendReply(msg, lang[ln].flag.no_input)
		else
			if is_report_blocked(msg) then
				return
            end
            if msg.reply then
                local alreadyFlagged = db:hsetnx('flagged:'..msg.chat.id..':'..msg.message_id, 'repliedTo', msg.reply.message_id)
				print(alreadyFlagged)
                if alreadyFlagged == '0' then
                    print("Message already reported")
                   return
                end
            end
            print("Unique report")
			if is_moduser(msg) then return end
			if msg.reply and ((tonumber(msg.reply.from.id) == tonumber(bot.id)) --[[or is_mod(msg.reply)]]) then
				return
			end
			local mods = get_mods_id(msg.chat.id)
			if not mods then
				api.sendReply(msg, lang[ln].bonus.adminlist_admin_required, true)
			end
			local msg_id = msg.message_id
			local repID = msg.message_id
			local is_by_reply = false
			if msg.reply then
				is_by_reply = true
				msg_id = msg.reply.message_id
			end
			local reporter = msg.from.first_name
			if msg.from.username then reporter = reporter..' (@'..msg.from.username..')' end
			local username = msg.chat.username
			send_to_admin(mods, msg.chat.id, msg_id, reporter, is_by_reply, msg.chat.title, msg, repID, username, msg)
			api.sendReply(msg, lang[ln].flag.reported..'\n#Report ID: #r'..repID)
		end
	elseif blocks[1] == 'report' then
		if is_mod(msg) then
			if not msg.reply then
				api.sendReply(msg, lang[ln].flag.no_reply)
			else
				if blocks[2] == 'off' then
					local result = db:sadd(hash, msg.reply.from.id)
					if result == 1 then
						api.sendReply(msg, lang[ln].flag.blocked)
					elseif result == 0 then
						api.sendReply(msg, lang[ln].flag.already_blocked)
					end
				elseif blocks[2] == 'on' then
					local result = db:srem(hash, msg.reply.from.id)
					if result == 1 then
						api.sendReply(msg, lang[ln].flag.unblocked)
					elseif result == 0 then
						api.sendReply(msg, lang[ln].flag.already_unblocked)
					end
				end
			end
		end
	elseif blocks[1] == 'warnflag' then
		local chat_id = blocks[2]
		local user_id = blocks[3]
		if is_mod2(chat_id, user_id) then
			api.answerCallbackQuery(msg.cb_id, lang[ln].kick_errors[2], true)
			return
		end
		local hash = 'chat:'..chat_id..':warns'
		local num = db:hincrby(hash,user_id, 1) --add one warn
		local nmax = (db:hget('chat:'..chat_id..':warnsettings', 'max')) or 3 --get the max num of warnings
		local text, res, motivation

		if tonumber(num) >= tonumber(nmax) then
			local type = (db:hget('chat:'..chat_id..':warnsettings', 'type')) or 'kick'
			--try to kick/ban
			if type == 'ban' then
				text = make_text(lang[ln].warn.warned_max_ban, user_id)..' ('..num..'/'..nmax..')'
				local is_normal_group = false
				res, motivation = api.banUser(chat_id, user_id, is_normal_group, ln)
			else --kick
			text = make_text(lang[ln].warn.warned_max_kick, user_id)..' ('..num..'/'..nmax..')'
			res, motivation = api.kickUser(chat_id, user_id, ln)
			end
			--if kick/ban fails, send the motivation
			if not res then
				if not motivation then
					motivation = lang[ln].banhammer.general_motivation
				end
				text = motivation
			else
				cross.saveBan(user_id, 'warn') --add ban
				if type == 'ban' then --add to the banlist
				local why = lang[ln].warn.ban_motivation
				cross.addBanList(chat_id, user_id, '', why)
				end
				db:hdel('chat:'..chat_id..':warns', user_id) --if kick/ban works, remove the warns
				db:hdel('chat:'..chat_id..':mediawarn', user_id)
				api.sendMessage(chat_id, user_id.." has been banned by "..msg.chat.id)
			end
			api.answerCallbackQuery(msg.cb_id, text, true) --if the user reached the max num of warns, kick and send message
		else
			local diff = tonumber(nmax)-tonumber(num)
			text = make_text(lang[ln].warn.warned, user_id, num, nmax)
			api.answerCallbackQuery(msg.cb_id, text..'\nID: '..user_id, true) --if the user is under the max num of warnings, send the inline keyboard
			api.sendMessage(chat_id, text.."\nby "..msg.chat.id..'\nID: '..user_id, true)
		end
	elseif blocks[1] == 'banflag' then
		local chat_id = blocks[2]
		local user_id = blocks[3]
		local is_normal_group = false
		local res, motivation = api.banUser(chat_id, user_id, is_normal_group, ln)
		if not res then
			if not motivation then
				motivation = lang[ln].banhammer.general_motivation
			end
			api.answerCallbackQuery(msg.cb_id, motivation, true)
		else
			local is_already_tempbanned = db:sismember('chat:'..chat_id..':tempbanned', user_id)
			if is_already_tempbanned then
				print('Is already tempbanned')
				local all = db:hgetall('tempbanned')
				if next(all) then
					for unban_time,info in pairs(all) do
						--print(chat_id..':'..user_id..' '..info)
						if string.match(chat_id..':'..user_id, info) then
							db:hdel('tempbanned', unban_time)
							--print('TimeRemoved '..unban_time)
						end
					end
				end
				db:srem('chat:'..chat_id..':tempbanned', user_id) --hash needed to check if an user is already tempbanned or not
				--print('Removed from db '..'chat:'..chat_id..':tempbanned '..user_id)
			end
			--save the ban
			cross.saveBan(user_id, 'ban')
			--add to banlist
			local why
			why = msg.text:gsub('^!ban @[%w_]+%s?', 'Banned in PM')
			--id = getId(msg)
			cross.addBanList(msg.chat.id, user_id, user_id, why)
			db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
			api.answerCallbackQuery(msg.cb_id, 'User Banned')
			api.sendMessage(chat_id, user_id.." has been banned by "..msg.chat.id)
		end
	elseif blocks[1] == 'kickflag' then
		local chat_id = blocks[2]
		local user_id = blocks[3]
		local res, motivation = api.kickUser(chat_id, user_id, ln)
		if not res then
			if not motivation then
				motivation = lang[ln].banhammer.general_motivation
				api.answerCallbackQuery(msg.cb_id, motivation, true)
			else
				api.answerCallbackQuery(msg.cb_id, 'Kick Failed, please manually unban', true)
			end
		else
			api.sendMessage(chat_id, user_id.." has been kicked by "..msg.chat.id)
			api.answerCallbackQuery(msg.cb_id, 'User kicked')
		end
	elseif blocks[1] == 'solveflag' then
		print('Solved callback')
		local msg_id = blocks[3]
		local chat = blocks[2]
		print("Mesesage ID:", msg_id)
		local hash12 = 'flagged:'..chat..':'..msg_id
		local isSolved1 = db:hget(hash12, 'Solved')
		--print("12213213")
		local hash13 = 'flagged:'..chat..':'..msg_id+1
		local isSolved2 = db:hget(hash13, 'Solved')
		if isSolved1 then
			hash14 = 'flagged:'..chat..':'..msg_id
		elseif isSolved2 then
			hash14 = 'flagged:'..chat..':'..msg_id+1
		end

		local alreadyReported = db:hget(hash14, 'Solved')
		--print("Reprorteorijt", alreadyReported)
		if alreadyReported == '0' then
			local solvedBy = msg.from.first_name
			if msg.from.username then solvedBy = solvedBy..' (@'..msg.from.username..')' end
			local solvedAt = os.date('!%c (UCT)')

			db:hset(hash14, 'SolvedAt', solvedAt)
			db:hset(hash14, 'solvedBy', solvedBy)
			db:hset(hash14, 'Solved', 1)
			local counter = db:hget(hash14, '#Admin')
			local reporter = db:hget(hash14, 'Reporter')
			local repID = db:hget(hash14, 'repID')
			--print("counter", counter)
			local group = api.getChat(chat)
			local text = 'This has been solved by: '..solvedBy..'\n'..solvedAt..'\n('..group.result.title..')\nIt was reported by: '..reporter
			for i=1, counter, 1 do
				local id = db:hget(hash14, 'adminID'..i)
				--print("id", id)
				local msgID = db:hget(hash14, 'Message'..i)
				--print("msgid", msgID)
				if id ~= nil then
					--print("id", id)
					if msgID ~= nil then
						--print("msgid", msgID)
						api.editMessageText(id, msgID, text..'\nReport ID: '..repID, false, false)
					end
				end
			end
			api.sendMessage(chat, "#Report ID: #r"..msg_id.." solved by "..msg.chat.id)
			api.answerCallbackQuery(msg.cb_id, "Marked as Solved")
		elseif alreadyReported == '1' then
			local solvedTime = db:hget(hash14, 'SolvedAt')
			local solvedBy = db:hget(hash14, 'solvedBy')
			api.answerCallbackQuery(msg.cb_id, 'This message was solved at '..solvedTime..' by '..solvedBy, true)
		end
	elseif blocks[1] == 'solved' then
		--print("Second block"..blocks[2])
		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			if msg.reply then
				local msg_id = msg.reply.message_id
				print("Mesesage ID:", msg_id)
				hash12 = 'flagged:'..msg.chat.id..':'..msg_id
				isSolved1 = db:hget(hash12, 'Solved')
				--print("12213213")
				hash13 = 'flagged:'..msg.chat.id..':'..msg_id+1
				isSolved2 = db:hget(hash13, 'Solved')
				if isSolved1 then
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id
				elseif isSolved2 then
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id+1
				else
					api.sendReply(msg, 'Report not found')
					print("1, ", isSolved1)
					print("2, ", isSolved2)
					return
				end

				alreadyReported = db:hget(hash14, 'Solved')
				--print("Reprorteorijt", alreadyReported)
				if alreadyReported == '0' then
					local solvedBy = msg.from.first_name
					if msg.from.username then solvedBy = solvedBy..' (@'..msg.from.username..')' end
					local solvedAt = os.date('!%c (UCT)')

					db:hset(hash14, 'SolvedAt', solvedAt)
					db:hset(hash14, 'solvedBy', solvedBy)
					db:hset(hash14, 'Solved', 1)
					counter = db:hget(hash14, '#Admin')
					reporter = db:hget(hash14, 'Reporter')
					repID = db:hget(hash14, 'repID')
					local text
					--print("counter", counter)
					if reporter ~= nil then
						text = 'This has been solved by: '..solvedBy..'\n'..solvedAt..'\n('..msg.chat.title..')\nIt was reported by: '..reporter
					else
						text = 'This has been solved by: '..solvedBy..'\n'..solvedAt..'\n('..msg.chat.title..')'
					end


					for i=1, counter, 1 do
						local id = db:hget(hash14, 'adminID'..i)
						--print("id", id)
						local msgID = db:hget(hash14, 'Message'..i)
						--print("msgid", msgID)
						if id ~= nil then
							--print("id", id)
							if msgID ~= nil then
								--print("msgid", msgID)
								api.editMessageText(id, msgID, text..'\nReport ID: '..repID, false, false)
							end
						end

					end
					api.sendReply(msg, 'Marked as solved')
				elseif alreadyReported == '1' then
					local solvedTime = db:hget(hash14, 'SolvedAt')
					local solvedBy = db:hget(hash14, 'solvedBy')
					api.sendReply(msg, 'This message was solved at '..solvedTime..' by '..solvedBy)
				else
					api.sendReply(msg, 'Please reply to a flagged message (contains @admin).')
				end
			elseif blocks[2] then
				--print("in block")
				local msg_id = blocks[2]
				print("Mesesage ID:", msg_id)
				hash12 = 'flagged:'..msg.chat.id..':'..msg_id
				isSolved1 = db:hget(hash12, 'Solved')
				--print("12213213")
				hash13 = 'flagged:'..msg.chat.id..':'..msg_id+1
				isSolved2 = db:hget(hash13, 'Solved')
				if isSolved1 then
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id
				elseif isSolved2 then
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id+1
				else
					api.sendReply(msg, 'Report not found')
					print("1, ", isSolved1)
					print("2, ", isSolved2)
					return
				end

				alreadyReported = db:hget(hash14, 'Solved')
				--print("Reprorteorijt", alreadyReported)
				if alreadyReported == '0' then
					local solvedBy = msg.from.first_name
					if msg.from.username then solvedBy = solvedBy..' (@'..msg.from.username..')' end
					local solvedAt = os.date('!%c (UCT)')

					db:hset(hash14, 'SolvedAt', solvedAt)
					db:hset(hash14, 'solvedBy', solvedBy)
					db:hset(hash14, 'Solved', 1)
					counter = db:hget(hash14, '#Admin')
					reporter = db:hget(hash14, 'Reporter')
					repID = db:hget(hash14, 'repID')
					--print("counter", counter)
					local text = 'This has been solved by: '..solvedBy..'\n'..solvedAt..'\n('..msg.chat.title..')\nIt was reported by: '..reporter..'\n#Solved'
					for i=1, counter, 1 do
						local id = db:hget(hash14, 'adminID'..i)
						--print("id", id)
						local msgID = db:hget(hash14, 'Message'..i)
						--print("msgid", msgID)
						if id ~= nil then
							--print("id", id)
							if msgID ~= nil then
								--print("msgid", msgID)
								api.editMessageText(id, msgID, text..'\nReport ID: '..repID, false, false)
							end
						end

					end
					api.sendReply(msg, 'Marked as solved')
				elseif alreadyReported == '1' then
					local solvedTime = db:hget(hash14, 'SolvedAt')
					local solvedBy = db:hget(hash14, 'solvedBy')
					api.sendReply(msg, 'This message was solved at '..solvedTime..' by '..solvedBy)
				else
					api.sendReply(msg, 'Please send a valid Report ID')
				end
			else
				api.sendReply(msg, 'Please reply to a flagged message (contains @admin).')
			end
		else
			api.sendReply(msg, lang[ln].not_mod)
		end
	elseif blocks[1] == 'msgid' then
		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			if msg.reply then
				api.sendReply(msg,'MessageID: '..msg.reply.message_id..' '..os.date('!%c (UCT)'))
			end
		end
	end
end

return {
	action = action,
	triggers = {
		'^@(admin)$',
		'^@(admin) (.*)$',
		'^/(report) (on)$',
		'^/(report) (off)$',
		'^/(solved) (%d+)$',
		'^/(solved) #r(%d+)$',
		'^/(solved)',
		'^/(msgid)',

		'^###cb:(banflag):(-%d+):(%d+)',
		'^###cb:(kickflag):(-%d+):(%d+)',
		'^###cb:(warnflag):(-%d+):(%d+)',
		'^###cb:(solveflag):(-%d+):(%d+)',
	}
}