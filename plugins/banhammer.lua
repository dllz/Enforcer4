local function cron()
	local all = db:hgetall('tempbanned')
	if next(all) then
		for unban_time,info in pairs(all) do
			if os.time() > tonumber(unban_time) then
				local chat_id, user_id = info:match('(-%d+):(%d+)')
				api.unbanUser(chat_id, user_id, true)
				api.unbanUser(chat_id, user_id, false)
				db:hdel('tempbanned', unban_time)
				db:srem('chat:'..chat_id..':tempbanned', user_id) --hash needed to check if an user is already tempbanned or not
			end
		end
	end
end

function split(message)
        if sep == nil then
                sep = "%n"
        end
        local t={}
		local i=1
		local count=1
		local text = ''
        for str in string.gmatch(message, "([^"..sep.."]+)") do	
			--print(str)
			
			text = text..str..'\n' 
			if  i % 50 == 0 then 
				--print(text)
				t[count] = text 
				count = count + 1
				text = ''
			end 
			i = i + 1
        end
		--table.setn(t, i)
        return t
end

local function get_user_id(msg, blocks)
	if msg.cb then
		return blocks[2]
	elseif msg.reply then
		return msg.reply.from.id
	elseif blocks[2] then
		return res_user_group(blocks[2], msg.chat.id)
	end
end

local function get_nick(msg, blocks, sender)
	if sender then
		return getname_id(msg)
	elseif msg.reply then
		return getname_id(msg.reply)
	elseif blocks[2] then
		return blocks[2]
	end
end

local function getBanList(chat_id, ln)
    local text = lang[ln].banhammer.banlist_header
    local hash = 'chat:'..chat_id..':bannedlist'
    local banned_users, mot = rdb.get(hash)
    if not banned_users or not next(banned_users) then
        return lang[ln].banhammer.banlist_empty, true
    else
        local i = 1
        for banned_id,info in pairs(banned_users) do
			if info.nick == nil then
				if banned_id ~= nil then
					info.nick = tostring(banned_id)
				else
					info.nick = "anon"
				end
			end
            text = text..'*'..i..'* - '..info.nick:mEscape()
            if info.why then text = text..'\n*⌦* '..info.why:mEscape() end
            text = text..'\n'
            i = i + 1
        end
		print(i)
        return text
    end
end

local function check_valid_time(temp)
	temp = tonumber(temp)
	if temp == 0 then
		return false, 1
	elseif temp > 10080 then --1 week
		return false, 2
	else
		return temp
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function get_time_reply(minutes)
	local time_string = ''
	local time_table = {}
	time_table.days = math.floor(minutes/(60*24))
	minutes = minutes - (time_table.days*60*24)
	time_table.hours = math.floor(minutes/60)
	time_table.minutes = minutes % 60
	if not(time_table.days == 0) then
		time_string = time_table.days..'d'
	end
	if not(time_table.hours == 0) then
		time_string = time_string..' '..time_table.hours..'h'
	end
	time_string = time_string..' '..time_table.minutes..'m'
	return time_string, time_table
end

local action = function(msg, blocks, ln)
	if msg.chat.type ~= 'private' then
		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			--commands that don't need a target user
			if blocks[1] == 'kickme' then
				api.sendReply(msg, lang[ln].kick_errors[2], true)
				return
			end
			if blocks[1] == 'banlist' and not blocks[2] then
   				local banlist, is_empty = getBanList(msg.chat.id, ln)
   				if is_empty then
					api.sendReply(msg, banlist, true)
   				else
					local res, code = api.sendKeyboard(msg.chat.id, banlist, {inline_keyboard={{{text = 'Clean', callback_data = 'banlist-'}}}}, true)
					if code == 118 then 
						text = {}
						text = split(banlist)
						local size = tablelength(text)
						--print(size)
						for iteration = 1, size, 1 do
							--print(iteration)
							--print(msg.chat.id)
							--print(text[iteration])
							if text[iteration] ~= nil then
								local reses, codes = api.sendKeyboard(msg.chat.id, text[iteration], {inline_keyboard={{{text = 'Clean', callback_data = 'banlist-'}}}}, true)
								print(code)
							end 
						end 
					end
   				end
   				return 
   			end
		    if blocks[1] == 'banlist' and blocks[2] and blocks[2] == '-' then
		    	local res, error = rdb.rem('chat:'..msg.chat.id..':bannedlist')
		    	if res then
		    		if msg.cb then --if cleaned via the inline button
		    			api.editMessageText(msg.chat.id, msg.message_id, lang[ln].banhammer.banlist_cleaned..'\n`(Admin: '..msg.from.first_name:mEscape()..')`', false, true)
		    		else --if cleaned via message
		    			api.sendReply(msg, lang[ln].banhammer.banlist_cleaned, true)
		    		end
	    		else
	    			local text
	    			--get thetext
		    		if error:match('hash does not exists') then
		    			text = lang[ln].banhammer.banlist_empty
		    		else
		    			text = lang[ln].banhammer.banlist_error
		    		end
		    		--reply or edit
		    		if msg.cb then
		    			api.editMessageText(msg.chat.id, msg.message_id, text, false, true)
		    		else
		    			api.sendReply(msg, text, true)
		    		end
    			end
    			return
	    	end
			
			if blocks[1] == 'kickid' then
				local res, motivation = api.kickUser(msg.chat.id, blocks[2], ln)
		    	if not res then
		    		if not motivation then
		    			motivation = lang[ln].banhammer.general_motivation
						api.sendReply(msg, motivation, true)
		    		else
						api.sendReply(msg, 'Kick Failed, please manually unban')
					end
		    	else
					db:hdel('chat:'..msg.chat.id..':userJoin', blocks[2])
		    		cross.saveBan(blocks[2], 'kick')
		    		api.sendMessage(msg.chat.id, 'User Kicked', true)
		    	end
			end
		  
		  if blocks[1] == 'banid' then
		    local is_normal_group = (msg.chat.type == 'group')
		    local chat_id = msg.chat.id
		    local user_id = tonumber(blocks[2])
		    
		    --after this line, I kinda copied from ban x"D
		    local res, motivation = api.banUser(chat_id, user_id, is_normal_group, ln)
          if not res then
            if not motivation then
              motivation = lang[ln].banhammer.general_motivation
            end
            api.sendReply(msg, motivation, true)
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
            --local nick = blocks[2] --banned user
            local why = msg.text:gsub('^/ban %d+%s?', '')
          --id = getId(msg)
            cross.addBanList(msg.chat.id, user_id, user_id, why)
            db:hdel('chat:'..msg.chat.id..':userJoin', user_id)
            api.sendKeyboard(msg.chat.id, lang[ln].banhammer.banned:build_text(get_nick(msg, false, true):mEscape(), user_id:mEscape()), {inline_keyboard = {{{text = 'Unban', callback_data = 'unban:'..user_id}}}}, true)
          end
		  end
		  
		    --commands that need a target user
		    
		    if not msg.reply_to_message and not blocks[2] and not msg.cb then
		        api.sendReply(msg, lang[ln].banhammer.reply)
		        return
		    end
		    if msg.reply and msg.reply.from.id == bot.id then return end
		 	
		 	local res
		 	local chat_id = msg.chat.id
		 	--get the user id, send message and break if not found
		 	local user_id = get_user_id(msg, blocks)
		 	if not user_id then
		 		api.sendReply(msg, lang[ln].bonus.no_user, true)
		 		return
		 	end
		 	if blocks[1] == 'tempban' then
				if not msg.reply then
					api.sendReply(msg, lang[ln].banhammer.reply)
					return
				end
				local user_id = msg.reply.from.id
				local temp, code = check_valid_time(blocks[2])
				if not temp then
					if code == 1 then
						api.sendReply(msg, lang[ln].banhammer.tempban_zero)
					else
						api.sendReply(msg, lang[ln].banhammer.tempban_week)
					end
					return
				end
				local val = msg.chat.id..':'..user_id
				local unban_time = os.time() + (temp * 60)
				
				--try to kick
				local res, motivation = api.banUser(chat_id, user_id, is_normal_group, ln)
		    	if not res then	
		    		if not motivation then
		    			motivation = lang[ln].banhammer.general_motivation
		    		end
		    		api.sendReply(msg, motivation, true)
		    	else
		    		cross.saveBan(user_id, 'tempban') --save the ban
					db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
		    		db:hset('tempbanned', unban_time, val) --set the hash
					local time_reply = get_time_reply(temp)
					local banned_name = getname(msg.reply)
					local is_already_tempbanned = db:sismember('chat:'..chat_id..':tempbanned', user_id) --hash needed to check if an user is already tempbanned or not
					if is_already_tempbanned then
						api.sendMessage(chat_id, make_text(lang[ln].banhammer.tempban_updated..time_reply, banned_name))
					else
						api.sendMessage(chat_id, make_text(lang[ln].banhammer.tempban_banned..time_reply, banned_name)..'ID: '..user_id)
						db:sadd('chat:'..chat_id..':tempbanned', user_id) --hash needed to check if an user is already tempbanned or not
					end
				end
			end
		 	
		 	
		 	
		 	if blocks[1] == 'kick' then
		    	local res, motivation = api.kickUser(chat_id, user_id, ln)
		    	if not res then
		    		if not motivation then
		    			motivation = lang[ln].banhammer.general_motivation
						api.sendReply(msg, motivation, true)
		    		else
						api.sendReply(msg, 'Kick Failed, please manually unban '..get_nick(msg, blocks, false):mEscape())
					end
		    	else
					db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
		    		cross.saveBan(user_id, 'kick')
		    		api.sendMessage(msg.chat.id, lang[ln].banhammer.kicked:build_text(get_nick(msg, false, true):mEscape(), get_nick(msg, blocks):mEscape()), true)
		    	end
	    	end
	   		
	   		local is_normal_group = false
	   		if msg.chat.type == 'group' then is_normal_group = true end
	   		
	   		if blocks[1] == 'ban' then
	   			local res, motivation = api.banUser(chat_id, user_id, is_normal_group, ln)
		    	if not res then
		    		if not motivation then
		    			motivation = lang[ln].banhammer.general_motivation
		    		end
		    		api.sendReply(msg, motivation, true)
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
		    		local nick = get_nick(msg, blocks) --banned user
		    		local why
		    		if msg.reply then
		    			why = msg.text:input()
						
		    		else
		    			why = msg.text:gsub('^/ban @[%w_]+%s?', '')
		    		end
					--id = getId(msg)
		    		cross.addBanList(msg.chat.id, user_id, nick, why)
					db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
		    		api.sendKeyboard(msg.chat.id, lang[ln].banhammer.banned:build_text(get_nick(msg, false, true):mEscape(), nick:mEscape()), {inline_keyboard = {{{text = 'Unban', callback_data = 'unban:'..user_id}}}}, true)
					if msg.reply then
						api.forwardMessage(msg.from.id, msg.chat.id, msg.reply.id)
					end
		    	end
    		end
   			if blocks[1] == 'unban' then
   				local status = cross.getUserStatus(chat_id, user_id)
				if not config.admin.GlobalBanList[user_id] then
					local res = api.unbanUser(chat_id, user_id, is_normal_group)
					--if not(status == 'kicked') and not(msg.chat.type == 'group') then
						--api.sendReply(msg, lang[ln].banhammer.not_banned, true)
						--return
					--end
					
					local text
					if not res and msg.chat.type == 'group' then
						--api.sendReply(msg, lang[ln].banhammer.not_banned, true)
						text = lang[ln].banhammer.not_banned
					else
						cross.remBanList(msg.chat.id, user_id)
						text = lang[ln].banhammer.unbanned
						--api.sendReply(msg, lang[ln].banhammer.unbanned, true)
					end
					if not msg.cb then
						api.sendReply(msg, text, true)
					else
						api.editMessageText(msg.chat.id, msg.message_id, text..'\n`['..user_id..']\n(Admin: '..msg.from.first_name:mEscape()..')`', false, true)
					end
				end
			end
		else
			if blocks[1] == 'kickme' then
				api.kickUser(msg.chat.id, msg.from.id, ln)
				db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
			end
			if msg.cb then --if the user tap on 'unban', show the pop-up
				api.answerCallbackQuery(msg.cb_id, lang[ln].not_mod:mEscape_hard())
			end
		end
		if blocks[1] == 'getrekt' then
			if config.admin.superAdmins[msg.from.id] then
				 
				local mot = table.concat({table.unpack(blocks, 2, blocks.length)}, ' ')
				if msg.reply.forward_from ~= nil then 
					local forward = msg.reply.forward_from.id 
					local hash = 'globalBan:'..forward
					print(forward..mot)
					db:hset(hash, 'banned', 1)
					db:hset(hash, 'motivation', mot)
					db:hset(hash, 'time', os.date('On %A, %d %B %Y\nAt %X'))
					api.sendReply(msg, forward..' is rekted', true)
				else
					local user = msg.reply.from.id
					local hash = 'globalBan:'..user
					-- It still rekts it, just the user..'is rekted' msg was fucked before
					print(mot)
					db:hset(hash, 'banned', 1)
					db:hset(hash, 'motivation', mot)
					db:hset(hash, 'time', os.date('%d %B %Y, %X'))
					api.sendReply(msg, user..' is rekted', true)
				end
			end
		end
		-- temporary!
		if blocks[1] == 'unrekt' then
			if config.admin.admins[msg.from.id] then
				 
				if msg.reply.forward_from ~= nil then 
					local forward = msg.reply.forward_from.id 
					local hash = 'globalBan:'..forward
					local mot = blocks[2]
					print(forward..mot)
					db:hset(hash, 'banned', 0)
					db:hset(hash, 'motivation', mot)
					db:hset(hash, 'time', os.date('On %A, %d %B %Y\nAt %X'))
					api.sendReply(msg, forward..' is unrekted', true)
				else
					local user = msg.reply.from.id
					local hash = 'globalBan:'..user
					local mot = blocks[2]
					print(mot)
					db:hset(hash, 'banned', 0)
					db:hset(hash, 'motivation', mot)
					db:hset(hash, 'time', os.date('%d %B %Y, %X'))
					api.sendReply(msg, user..' is unrekted', true)
				end
			end
		end
		
	end
end

return {
	action = action,
	cron = cron,
	triggers = {
		'^/(kickme)%s?',
		'^/(kickid) (%d+)',
		'^/(kick) (@[%w_]+)',
		'^/(kick)',
		'^/(kickid) (%d+)',
		'^/(banid) (%d+)',
		'^/(banlist)$',
		'^/(banlist) (-)$',
		'^/(ban) (@[%w_]+)',
		'^/(ban)$',
		'^/(ban) '
		'^/(tempban) (%d+)',
		'^/(unban) (@[%w_]+)',
		'^/(unban)',
		'^###cb:(unban):(%d+)$',
		'^###cb:(banlist)(-)$',
		'^/(getrekt) ([%w]+)',
		'^/(unrekt) ([%w]+)'
	}
}
