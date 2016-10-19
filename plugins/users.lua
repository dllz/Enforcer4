local function do_keybaord_credits()
	local keyboard = {}
    keyboard.inline_keyboard = {
    	{
    		{text = 'Channel', url = 'https://telegram.me/'..config.channel:gsub('@', '')},
    		{text = 'GitHub', url = 'https://github.com/BladeZero/GroupButler'},
    		{text = 'Get Support', url = 'https://telegram.me/werewolfsupport'},
		}
	}
	return keyboard
end

local function get_user_id(msg, blocks)
	if msg.target_id then
		return msg.target_id
	elseif msg.reply then
		return msg.reply.from.id
    elseif msg.entities then --this elseif is a test.
        for i,entity in ipairs(msg.entities) do
            if entity.type == "text_mention" then return entity.user.id end
        end
	elseif blocks[2] then
		if blocks[2]:match('@[%w_]+') then
			local user_id = res_user_group(blocks[2], msg.chat.id)
			if not user_id then
				return false
			else
				return user_id
			end
		elseif blocks[2]:match('%d+') then
			return blocks[2]
		end
	else
		return false
	end
end

local function get_name_getban(msg, blocks, user_id)
	if blocks[2] then
		return blocks[2]..' ('..user_id..')'
	else
		return msg.reply.from.first_name..' ('..user_id..')'
	end
end

local function get_ban_info(user_id, chat_id, title, ln)
	local hash = 'ban:'..user_id
	local ban_info = db:hgetall(hash)
	--if not next(ban_info) then
	--	return lang[ln].getban.nothing
	--else
		local ban_index = {
			['kick'] = lang[ln].getban.kick,
			['ban'] = lang[ln].getban.ban,
			['tempban'] = lang[ln].getban.tempban,
			['flood'] = lang[ln].getban.flood,
			['media'] = lang[ln].getban.media,
			['warn'] = lang[ln].getban.warn,
			['arab'] = lang[ln].getban.arab,
			['rtl'] = lang[ln].getban.rtl,
		}
		local text = ''
		for type,n in pairs(ban_info) do
			text = text..'`'..ban_index[type]..'`'..'*'..n..'*\n'
		end
		--if text == '' then
		--	return lang[ln].getban.nothing
		--else
		if chat_id ~= nil then
			local warns = (db:hget('chat:'..chat_id..':warns', user_id)) or 0
			local media_warns = (db:hget('chat:'..chat_id..':mediawarn', user_id)) or 0
			if title ~= nil then
				text = text..'\n*Info for group '..title..'*:'
			end
			text = text..'\n`Warns`: '..warns..'\n`Media warns`: '..media_warns
		end
		return text
		--end
	--end
end

local function do_keyboard_userinfo(user_id, ln)
	local keyboard = {
		inline_keyboard = {
			{{text = lang[ln].userinfo.remwarns_kb, callback_data = 'userbutton:remwarns:'..user_id}},
			{{text ='?? Ban', callback_data = 'userbutton:banuser:'..user_id}},
		}
	}
	
	return keyboard
end

local function check_reply(msg)
	if not msg.reply then
		return false, 'Reply to the file'
	else
		if not msg.reply.document then
			return false, 'This is not a file'
		else
			if msg.reply.document.file_name ~= 'ban_data.json' then
				return false, 'This is not a valid file'
			else
				return true
			end
		end
	end
end

local function get_userinfo(user_id, chat_id, title, ln)
	return lang[ln].userinfo.header_1..get_ban_info(user_id, chat_id, title, ln)
end

local action = function(msg, blocks, ln)
    if blocks[1] == 's' then
		if msg.chat.type == 'private' then return end
		if msg.reply then
			local messageid = msg.reply.message_id
			local saveTo = msg.from.id
			local chat = msg.chat.id
			local res, code = api.forwardMessage(saveTo, chat, messageid)
			if code == 403 then
				api.sendReply(msg, "Please start @werewolfbutlerbot.")
			else
				api.sendReply(msg, 'Message saved')
			end
		else
			api.sendReply(msg, "Please reply to a message to save it")
		end
	elseif blocks[1] == 'adminlist' then
    	if msg.chat.type == 'private' then return end
    	local no_usernames
    	local send_reply = true
    	if is_locked(msg, 'Modlist') then
    		if is_mod(msg) then
        		no_usernames = true
        	else
        		no_usernames = false
        		send_reply = false
        	end
        else
            no_usernames = true
        end
    	local out
        local creator, adminlist = cross.getModlist(msg.chat.id, no_usernames)
        out = make_text(lang[ln].mod.modlist, creator, adminlist)
        if not send_reply then
        	local res, code = api.sendMessage(msg.from.id, out, true)
			if code == 403 then
				api.sendReply(msg, "Please start @werewolfbutlerbot and try this command again")
			end
        else
            api.sendReply(msg, out, true)
        end
    elseif blocks[1] == 'status' then
    	if msg.chat.type == 'private' then return end
    	if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
    		local user_id
    		if blocks[2]:match('%d+$') then
    			user_id = blocks[2]
    		else
    			user_id = res_user_group(blocks[2], msg.chat.id)
    		end
    		if not user_id then
		 		api.sendReply(msg, lang[ln].bonus.no_user, true)
		 	else
		 		local res = api.getChatMember(msg.chat.id, user_id)
		 		if not res then
		 			api.sendReply(msg, lang[ln].status.unknown)
		 			return
		 		end
		 		local status = res.result.status
				local name = res.result.user.first_name
				if res.result.user.username then name = name..' (@'..res.result.user.username..')' end
				if msg.chat.type == 'group' and is_banned(msg.chat.id, user_id) then
					status = 'kicked'
				end
		 		local text = make_text(lang[ln].status[status], name)
		 		api.sendReply(msg, text)
		 	end
	 	end
 	elseif blocks[1] == 'id' then
 		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			local id
			local user = ''
			if msg.reply then
				if msg.reply.forward_from then 
					id = msg.reply.forward_from.id
					name = msg.reply.forward_from.first_name
					if msg.reply.forward_from.username ~= nil then 
						user = msg.reply.forward_from.username
					end
				else	
					id = msg.reply.from.id
					name = msg.reply.from.first_name
					if msg.reply.from.username ~= nil then 
						user = msg.reply.from.username
					end
				end
			else
				id = msg.chat.id
				name = msg.chat.title
				if msg.chat.username ~= nil then
					user =  msg.chat.username
				end
			end
			if user ~= '' then 
				local res, code = api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`'..'\n@'..user, true)
				if not res then
					api.sendMessage(config.log_chat, user)
					api.sendMessage(config.log_chat, dump(code)..', '..dump(res))
				end 
			else
				local res, code = api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`', true)
				if not res then
					api.sendMessage(config.log_chat, user)
					api.sendMessage(config.log_chat, dump(code)..', '..dump(res))
				end 
			end 
		end
 	elseif blocks[1] == 'settings' then
        
        if msg.chat.type == 'private' then return end
        
        local message = cross.getSettings(msg.chat.id, ln)
        api.sendReply(msg, message, true)
    elseif blocks[1] == 'welcome' then
        
        if msg.chat.type == 'private' or not is_mod(msg) then return end
        
        local input = blocks[2]
    
        --ignore if not input text and not reply
        if not input and not msg.reply then
            api.sendReply(msg, make_text(lang[ln].settings.welcome.no_input), false)
            return
        end
        
        local hash = 'chat:'..msg.chat.id..':welcome'
		db:hset(hash, 'hasmedia', 'false')
        if not input and msg.reply then
            local replied_to = get_media_type(msg.reply)
            if replied_to == 'gif' then
                local file_id-- = msg[replied_to].file_id
				file_id = msg.reply.document.file_id
                db:hset(hash, 'type', 'media')
                db:hset(hash, 'content', file_id)
                api.sendReply(msg, lang[ln].settings.welcome.media_setted..'`'..replied_to..'`', true)
            else
                api.sendReply(msg, lang[ln].settings.welcome.reply_media, true)
            end
            return
        end
        
        if msg.reply and input then 
	    	local replied_to = get_media_type(msg.reply)
            if replied_to == 'sticker' or replied_to == 'gif' then
                local file_id-- = msg[replied_to].file_id
                if replied_to == 'sticker' then
                    file_id = msg.reply.sticker.file_id
                else
                    file_id = msg.reply.document.file_id
                end
                db:hset(hash, 'hasmedia', 'true')
                db:hset(hash, 'media', file_id)
				print("Welcome with gif saved")
            end
		end 
        
        --change welcome settings
        if input == 'a' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'a')
            api.sendReply(msg, lang[ln].settings.welcome.a, true)
        elseif input == 'r' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'r')
            api.sendReply(msg, lang[ln].settings.welcome.r, true)
        elseif input == 'm' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'm')
            api.sendReply(msg, lang[ln].settings.welcome.m, true)
        elseif input == 'ar' or input == 'ra' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'ra')
            api.sendReply(msg, lang[ln].settings.welcome.ra, true)
        elseif input == 'mr' or input == 'rm' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'rm')
            api.sendReply(msg, lang[ln].settings.welcome.rm, true)
        elseif input == 'am' or input == 'ma' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'am')
            api.sendReply(msg, lang[ln].settings.welcome.am, true)
        elseif input == 'ram' or input == 'rma' or input == 'arm' or input == 'amr' or input == 'mra' or input == 'mar' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'ram')
            api.sendReply(msg, lang[ln].settings.welcome.ram, true)
        elseif input == 'no' then
            db:hset(hash, 'type', 'composed')
            db:hset(hash, 'content', 'no')
            api.sendReply(msg, lang[ln].settings.welcome.no, true)
        else
            db:hset(hash, 'type', 'custom')
            db:hset(hash, 'content', input)
            local res, code = api.sendReply(msg, make_text(lang[ln].settings.welcome.custom, input), true)
            if not res then
                db:hset(hash, 'type', 'composed') --if wrong markdown, remove 'custom' again
                db:hset(hash, 'content', 'no')
                if code == 118 then
				    api.sendMessage(msg.chat.id, lang[ln].bonus.too_long)
			    else
				    api.sendMessage(msg.chat.id, lang[ln].breaks_markdown, true)
			    end
            else
                local id = res.result.message_id
                api.editMessageText(msg.chat.id, id, lang[ln].settings.welcome.custom_setted, false, true)
            end
        end
    elseif blocks[1] == 'export' then
    	if msg.chat.type ~= 'private' then return end
    	if blocks[2] == 'ban' then
    		if is_bot_owner(msg) then
    			local users = db:hvals('bot:usernames')
				users = remove_duplicates(users)
				local final_table = {}
				for i,id in pairs(users) do
					local user_info = db:hgetall('ban:'..id)
					if next(user_info) then
						final_table[id] = {}
						for field, count in pairs(user_info) do
							final_table[id][field] = count
						end
					end
				end
				if next(final_table) then
					local path = 'ban_data.json'
					save_data(path, final_table)
					api.sendDocument(msg.chat.id, path)
				else
					api.sendMessage(msg.chat.id, 'Empty table')
				end
			else
				local file_id = db:get('bandata')
				if not file_id then
					api.sendReply(msg, 'Datas not available')
				else
					api.sendDocumentId(msg.chat.id, file_id)
				end
			end
		end
		if blocks[2] == 'save' then
			local is_valid, text = check_reply(msg)
			if is_valid then
				db:set('bandata', msg.reply.document.file_id)
				text = 'File id saved: '..msg.reply.document.file_id
			end
			api.sendReply(msg, text)
		end
	elseif blocks[1] == 'importban' then
		if is_bot_owner(msg, true) then
			local is_valid, text = check_reply(msg)
			if is_valid then
				local file_name = 'ban_data_imported.json'
				local res = api.getFile(msg.reply.document.file_id)
				local download_link = telegram_file_link(res)
				path, code = download_to_file(download_link, file_name)
				local ban_info = load_data(file_name)
				if not ban_info or not next(ban_info) then
					text = 'Something went wrong: no data available'
				else
					local i = 0
					for user_id, info in pairs(ban_info) do
						
						--[[        SUM MODE
						local save_body = {} --user info to be saved in redis
						
						--get the already saved info
						local old_info = db:hgetall('ban:'..user_id)
						if old_info and next(old_info) then
							for field, count in pairs(old_info) do
								save_body[field] = tonumber(count)
							end
						end
						
						--add to the already saved info the new imported info
						for key, n in pairs(info) do
							local old_value = save_body[key] or 0
							save_body[key] = old_value + tonumber(n)
						end
						
						--save on redis
						if next(save_body) then
							for key,val in pairs(save_body) do
								db:hset('ban:'..user_id, key, val)
							end
						end]]
						
						--save on redis
						if next(info) then
							for field,count in pairs(info) do
								db:hset('ban:'..user_id, field, count)
							end
							i = i + 1
						end
					end
					text = 'Imported! New entries: '..i
				end
			end
			api.sendReply(msg, text)
		end
	elseif blocks[1] == 'support' then
		if config.help_group and config.help_group ~= '' then
			if msg.reply then 
			 	msgToReplyTo = msg.reply.message_id
			else 
				msgToReplyTo = msg.message_id
			end
			api.sendMessage(msg.chat.id, '[Click here to get help from the support group]('..config.help_group..')', true, msgToReplyTo)
		end
	elseif blocks[1] == 'user' then
		if msg.chat.type == 'private' then return end
		if not is_mod(msg) then
			if msg.cb then
				api.answerCallbackQuery(msg.cb_id, lang[ln].not_mod:mEscape_hard())
			end
			return
		end
		
		local user_id = get_user_id(msg, blocks)
		
		if is_bot_owner(msg) and msg.reply and not msg.cb then --does this mean only global admins can get user by replying to a forwarded message??
			if msg.reply.forward_from then
				user_id = msg.reply.forward_from.id
			end
		end
		
		if not user_id then
			api.sendReply(msg, lang[ln].bonus.no_user, true)
		 	return
		end
		-----------------------------------------------------------------------------
		
		local keyboard = do_keyboard_userinfo(user_id, ln)
		
		local text = get_userinfo(user_id, msg.chat.id, msg.chat.title, ln)
		
		if msg.cb then
			api.editMessageText(msg.chat.id, msg.message_id, text, keyboard, true)
		else
			api.sendKeyboard(msg.chat.id, text, keyboard, true)
		end
	elseif blocks[1] == 'me' then
		local chat_id = msg.chat.id
		local chat_name = nil
		if msg.chat.type == 'private' then 
			chat_id = nil
		else
			chat_name = msg.chat.title:mEscape()
		end
		local user_id = msg.from.id
		
		local text = get_userinfo(user_id, chat_id, chat_name, ln)
		
		local res, code = api.sendMessage(user_id, text, true)
		if code == 403 then
			api.sendReply(msg, lang[ln].bonus.msg_me, true)
		else
			api.sendReply(msg, lang[ln].bonus.general_pm, true)
		end
		
	elseif blocks[1] == 'banuser' then
		if not is_mod(msg) then
    		api.answerCallbackQuery(msg.cb_id, lang[ln].not_mod:mEscape_hard())
    		return
		end
		
		local user_id = msg.target_id
		
		local res, text = api.banUser(msg.chat.id, user_id, msg.normal_group, ln)
		if res then
			cross.saveBan(user_id, 'ban')
			text = lang[ln].getban.banned..'\n`(Admin: '..msg.from.first_name:mEscape()..')`'
		end
		api.editMessageText(msg.chat.id, msg.message_id, text, false, true)
	elseif blocks[1] == 'remwarns' then
		if not is_mod(msg) then
    		api.answerCallbackQuery(msg.cb_id, lang[ln].not_mod:mEscape_hard())
    		return
		end
		db:hdel('chat:'..msg.chat.id..':warns', msg.target_id)
		db:hdel('chat:'..msg.chat.id..':mediawarn', msg.target_id)
        
        api.editMessageText(msg.chat.id, msg.message_id, lang[ln].warn.nowarn..'\n`(Admin: '..msg.from.first_name:mEscape()..')`', false, true)
    elseif blocks[1] == 'ping' then
		api.sendReply(msg, 'Time to recieve ping message: '..os.date("%M:%S", (os.time() - msg.date))..'\nAverage Messages per second in: '..(last_m/60)..'\nMessages recieved in the last minute: '..last_m)
	end
end

return {
	action = action,
	triggers = {
		'^/(id)$',
		'^/(adminlist)$',
		'^/(status) (@[%w_]+)$',
		'^/(status) (%d+)$',
		'^/(settings)$',
		'^/(export)(ban)$',
		'^/(export)(save)$',
		'^/(importban)$',
		'^/(support)$',
		'^/(welcome) (.*)$',
		'^/(welcome)$',
		'^/(user)$',
        '^/(user) (.+)$', --this is to get also /user + text mention
        '^/(user) (@[%w_]+)$',
		'^/(user) (%d+)$',
		'^/(ping)$',
		'^/(s)$',
		'^/(me)$',
		
		'^###cb:userbutton:(banuser):(%d+)$',
		'^###cb:userbutton:(remwarns):(%d+)$',
	}
}