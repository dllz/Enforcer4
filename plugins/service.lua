local function gsub_custom_welcome(msg, custom)
	local name = msg.added.first_name:mEscape()
	local name = name:gsub('%%', '')
	local id = msg.added.id
	local username
	local title = msg.chat.title:mEscape()
	if msg.added.username then
		username = '@'..msg.added.username:mEscape()
	else
		username = '(no username)'
	end
	custom = custom:gsub('$name', name):gsub('$username', username):gsub('$id', id):gsub('$title', title)
	return custom
end

local function get_welcome(msg, ln)
    if is_locked(msg, 'Welcome') then
        return false
    end
    local type = db:hget('chat:'..msg.chat.id..':welcome', 'type')
    local content = db:hget('chat:'..msg.chat.id..':welcome', 'content')
    if type == 'media' then
        local file_id = content
        api.sendDocumentId(msg.chat.id, file_id)
        return false
    elseif type == 'custom' then
        local hasMedia = db:hget('chat:'..msg.chat.id..':welcome', 'hasmedia')
        if hasMedia == 'true' then
            local file = db:hget('chat:'..msg.chat.id..':welcome', 'media')
            local text = gsub_custom_welcome(msg, content)
            api.sendDocumentWithCapId(msg.chat.id, file, text)
            return false
        else
            return gsub_custom_welcome(msg, content)
        end
    elseif type == 'composed' then
        if not(content == 'no') then
            local abt = cross.getAbout(msg.chat.id, ln)
            local rls = cross.getRules(msg.chat.id, ln)
            local creator, admins = cross.getModlist(msg.chat.id, ln)
            print(admins)
            local mods
            if not creator then
                mods = '\n'
            else
                mods = make_text(lang[ln].service.welcome_modlist, creator:mEscape(), admins:gsub('*', ''):mEscape())
            end
            local text = make_text(lang[ln].service.welcome, msg.added.first_name:mEscape_hard(), msg.chat.title:mEscape_hard())
            if content == 'a' then
                text = text..'\n\n'..abt
            elseif content == 'r' then
                text = text..'\n\n'..rls
            elseif content == 'm' then
                text = text..mods
            elseif content == 'ra' then
                text = text..'\n\n'..abt..'\n\n'..rls
            elseif content == 'am' then
                text = text..'\n\n'..abt..mods
            elseif content == 'rm' then
                text = text..'\n\n'..rls..mods
            elseif content == 'ram' then
                text = text..'\n\n'..abt..'\n\n'..rls..mods
            end
            return text
        else
            return make_text(lang[ln].service.welcome, msg.added.first_name:mEscape_hard(), msg.chat.title:mEscape_hard())
        end
    end
end

local action = function(msg, blocks, ln)
	
	--avoid trolls
	if not msg.service then return end
	
	--if the bot join the chat
	if blocks[1] == 'botadded' then
		
		if db:hget('bot:general', 'adminmode') == 'on' and not is_bot_owner(msg) then
			api.sendMessage(msg.chat.id, 'Admin mode is on: only the admin can add me to a new group')
			api.leaveChat(msg.chat.id)
			return
		end
		if is_blocked_global(msg.adder.id) then
			api.sendMessage(msg.chat.id, '_You ('..msg.adder.first_name:mEscape()..', '..msg.adder.id..') are in the blocked list_', true)
			api.leaveChat(msg.chat.id)
			return
		end
		
		cross.initGroup(msg.chat.id)
	end
	
	--if someone join the chat
	if blocks[1] == 'added' then

		if msg.chat.type == 'group' and is_banned(msg.chat.id, msg.added.id) then
			api.kickChatMember(msg.chat.id, msg.added.id)
			return
		end

		--Log user joining to the group
		db:hset('chat:'..msg.chat.id..':userJoin', msg.from.id, os.date('%d %B %Y, %X'))

		--[[if msg.chat.type == 'supergroup' and db:sismember('chat:'..msg.chat.id..':prevban') then
			if msg.adder and is_mod(msg) then --if the user is added by a moderator, remove the added user from the prevbans
				db:srem('chat:'..msg.chat.id..':prevban', msg.added.id)
			else --if added by a not-mod, ban the user
				local res = api.banUser(msg.chat.id, msg.added.id, false, ln)
				if res then
					api.sendMessage(msg.chat.id, make_text(lang[ln].banhammer.was_banned, msg.added.first_name))
				end
			end
		end]]
		
		cross.remBanList(msg.chat.id, msg.added.id) --remove him from the banlist
		
		if msg.added.username then
			local username = msg.added.username:lower()
			if username:find('bot', -3) then return end
		end
		
		if msg.added.id == 95890871 then
				api.sendMessage(msg.chat.id, 'All hail KickLord. You can lynch him later')
				return
		end
		if msg.added.id == 125311351 then
			api.sendMessage(msg.chat.id, 'My mechanic is here!')
			api.sendAdmin("The group information is: "..msg.chat.title.."\n"..msg.chat.id.."\n"..msg.chat.type)
			return
		end
		if msg.added.id == 129046388 then
			api.sendMessage(msg.chat.id, 'Hello papa. *hugs Para949*')
			return
		end
		if msg.added.id == 23776848 then
			api.sendMessage(msg.chat.id, 'Banhammer is ready for use, milady. Feel free to strike them down.')
			return
		end
		if msg.added.id == 114566255 then
			api.sendMessage(msg.chat.id, 'NuteNuteNutella! I am hungry.. Feed me, bella! (and feel free to call for me. You know the way, right.. kick and bans <3)')
			return
		end
		if msg.added.id == 218056872 then
			api.sendMessage(msg.chat.id, "Welcome, Godfather. Here's your Fedora, Tommy Gun, and ban offers nobody can refuse.")
			return
		end
		if msg.added.id == 213947461 then
			api.sendMessage(msg.chat.id, "Welcome, Godmother. *plays piano* Speak softly, miss, and carry this: your banpistol")
			return
		end
		if msg.added.id == 159289055 then
			api.sendMessage(msg.chat.id, "Shit, I really don't know...")
			return
        end
        if msg.added.id == 81772130 then
            api.sendMessage(msg.chat.id, "Your a bad admin. Be a good admin - Budi")
            return
        end
        if msg.added.id == 263451571 then
            api.sendMessage(msg.chat.id, 'The Node Queen is here! This Vixen is ready to slay.')
            return
        end
        if msg.added.id == 221962247 then
            api.sendMessage(msg.chat.id, "Uhm, who are you again? I may not remember for sure, but feel free to spread terror with your kagune here.")
            return
        end
		if msg.added.id == 252424970 then
			api.sendMessage(msg.chat.id, "Sheryl is here... I swear I will get her a kick immunity.")
			return
		end
		if msg.added.id == 36702373 then
			api.sendMessage(msg.chat.id, "Someone has a firestone? Cos Ponyta should evolve")
			return
		end
		if msg.added.id == 106665913 then
			api.sendMessage(msg.chat.id, "This is a known bug. No need to report.")
			return
		end
		if msg.added.id == 96487504 then
			api.sendMessage(msg.chat.id, "IT'S DIPPY!!!! Oh wait no...:((")
			return
		end
		if msg.added.id == 33517996 then
			api.sendMessage(msg.chat.id, "Hey Grunkle, where are Dippy and Mabel?")
			return
		end
		if msg.added.id == 9375804 then
			api.sendMessage(msg.chat.id, "Welcome the First global mommy of werewolfs!")
			return
		end
		if config.admin.wwGlobalAdmins[msg.added.id] then 
			api.sendMessage(msg.chat.id, 'Welcome, Werewolf senior admin.')
			return
		end
		
		
		local text = get_welcome(msg, ln)
		if text then
			api.sendMessage(msg.chat.id, text, true)
		end
		--if not text: welcome is locked
	end
	
	--if the bot is removed from the chat
	if blocks[1] == 'botremoved' then
		
		--remove the group settings
		cross.remGroup(msg.chat.id, true)
		
		--save stats
        db:hincrby('bot:general', 'groups', -1)
	end
	
	if blocks[1] == 'removed' then
		if msg.remover and msg.removed then
			--First commandment of Daniel: 
			--Thou shalt not add custom leave messages
			--if msg.removed.id == 81772130 then
			--	api.sendMessage(msg.chat.id, "Yayy he is gone, although tbh I will miss him. RIP @benthecat");
			--end
			
			if msg.remover.id ~= msg.removed.id and msg.remover.id ~= bot.id then
				local action
				if msg.chat.type == 'supergroup' then
					action = 'ban'
				elseif msg.chat.type == 'group' then
					action = 'kick'
				end
				cross.saveBan(msg.removed.id, action)
			end
		end
		db:hdel('chat:'..msg.chat.id..':userJoin', msg.from.id)
	end
end

return {
	action = action,
	triggers = {
		'^###(botadded)',
		'^###(added)',
		'^###(botremoved)',
		'^###(removed)'
	}
}