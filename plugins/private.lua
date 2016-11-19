local function do_keybaord_credits()
	local keyboard = {}
    keyboard.inline_keyboard = {
    	{
    		{text = 'Channel', url = 'https://telegram.me/'..config.channel:gsub('@', '')},
    		{text = 'GitHub', url = 'https://github.com/BladeZero/GroupButler'},
            {text = 'Get Support', url = 'https://telegram.me/werewolfsupport'},
        },
        {
            { text = "Done", callback_data = "close" }
        }
    }
	return keyboard
end

local action = function(msg, blocks, ln)
    
    if not(msg.chat.type == 'private') then return end
    
	if blocks[1] == 'ping' then
		api.sendMessage(msg.from.id, '*Pong!*', true)
	end
	if blocks[1] == 'strings' then
		if not blocks[2] then
			local file_id = db:get('trfile:EN')
			if not file_id then return end
			api.sendDocumentId(msg.chat.id, file_id, msg.message_id)
		else
			local l_code = blocks[2]
			local exists = is_lang_supported(l_code)
			if exists then
				local file_id = db:get('trfile:'..l_code:upper())
				if not file_id then return end
				api.sendDocumentId(msg.chat.id, file_id, msg.message_id)
			else
				api.sendReply(msg, lang[ln].setlang.error, true)
			end
		end
	end
	if blocks[1] == 'echo' then
		local res, code = api.sendMessage(msg.chat.id, blocks[2], true)
		if not res then
			if code == 118 then
				api.sendMessage(msg.chat.id, lang[ln].bonus.too_long)
			else
				api.sendMessage(msg.chat.id, lang[ln].breaks_markdown, true)
			end
		end
	end
    if blocks[1] == '!' then
    	if msg.chat.type ~= 'private' then
        	return
    	end
        local input = blocks[2]
        local receiver = msg.from.id
        
        --allert if not feedback
        if not input and not msg.reply then
            api.sendMessage(msg.from.id, lang[ln].report.no_input)
            return
        end
        
        if msg.reply then
        	msg = msg.reply
        end
	    
	    api.forwardMessage (config.admin.owner, msg.from.id, msg.message_id)
	    api.sendMessage(receiver, lang[ln].report.sent)
	end
	if blocks[1] == 'info' then
		local keyboard = {}
		keyboard = do_keybaord_credits()
		api.sendKeyboard(msg.chat.id, '`v'..config.version..'`\n'..lang[ln].credits, keyboard, true)
	end
	if blocks[1] == 'resolve' then
		local id = res_user_group(blocks[2], msg.chat.id)
		if not id then
			message = lang[ln].bonus.no_user
		else
			message = '*'..id..'*'
		end
		api.sendMessage(msg.chat.id, message, true)
	end
	
	if blocks[1] == 'usrid' then
		if msg.chat.type ~= 'private' then
        	return
    	end
 		local id = ''
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
 		end
		if user ~= '' then 
			api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`'..'\n@'..user, true)
		elseif id ~= '' then
			api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`', true)
		end 
 	end
	if blocks[1] == 'userid' then
		if msg.chat.type ~= 'private' then
        	return
    	end
 		local id = ''
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
 		end
		if user ~= '' then 
			api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`'..'\n@'..user, true)
		elseif id ~= '' then
			api.sendReply(msg, '`'..id..'`'..'\n`'..name..'`', true)
		end 
 	end
end

return {
	action = action,
	triggers = {
		'^/(userid)$',
		'^/(usrid)$',
		'^/(ping)$',
		'^/(strings)$',
		'^/(strings) (%a%a)$',
		'^/(echo) (.*)$',
		'^/(c)%s?',
		'^(!)$',
		'^(!)(.+)',
		'^/(info)$',
		'^/(resolve) (@[%w_]+)$',
	}
}