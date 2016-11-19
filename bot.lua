HTTP = require('socket.http')
HTTPS = require('ssl.https')
URL = require('socket.url')
JSON = require('dkjson')
redis = require('redis')
package.path = package.path..';~/torch/extra/threads/'
local threads = require('threads')
clr = require 'term.colors'
db = Redis.connect('127.0.0.1', 6379)
--db:select(0)
serpent = require('serpent')

local nthread = 250

local pool = threads.Threads(
    nthread,
    function(threadid)
        print('starting a new thread/state number ' .. threadid)
    end
)

local result -- DO NOT put this in get
local success -- DO NOT put this in get
local function handleMessage(msg, blocks)
    if pool:acceptsjob() then
        pool:addjob(
            function()
                return plugin.action(msg, blocks, msg.lang)
            end
        )
    end
end


bot_init = function(on_reload) -- The function run when the bot is started or reloaded.
	
	print(clr.blue..'Loading config.lua...')
	config = dofile('config.lua') -- Load configuration file.
	if config.bot_api_key == '' then
		print(clr.red..'API KEY MISSING!')
		return
	end
	print('Loading utilities.lua...')
	cross, rdb = dofile('utilities.lua') -- Load miscellaneous and cross-plugin functions.
	print('Loading languages.lua...')
	lang = dofile(config.languages) -- All the languages available
	print('Loading API functions table...')
	api = require('methods')
	
	current_m = 0
	last_m = 0
	
	bot = nil
	while not bot do -- Get bot info and retry if unable to connect.
		bot = api.getMe()
	end
	bot = bot.result

	plugins = {} -- Load plugins.
	print('Loading plugins...')
	for i,v in ipairs(config.plugins) do
		local p = dofile('plugins/'..v)
		table.insert(plugins, p)
	end
	print(clr.red..'Plugins loaded:', #plugins)

	print('\n'..clr.blue..'BOT RUNNING:'..clr.reset, clr.red..'[@'..bot.username .. '] [' .. bot.first_name ..'] ['..bot.id..']'..clr.reset..'\n')
	if not on_reload then
		db:hincrby('bot:general', 'starts', 1)
		api.sendAdmin('*Bot started!*\n_'..os.date('On %A, %d %B %Y\nAt %X')..'_\n'..#plugins..' plugins loaded', true)
	end
	
	-- Generate a random seed and "pop" the first random number. :)
	math.randomseed(os.time())
	math.random()

	last_update = last_update or db:get('bot:last_update') -- Set loop variables: Update offset,
	last_cron = last_cron or os.time() -- the time of the last cron job,
	is_started = true -- whether the bot should be running or not.

end

local function get_from(msg)
	local user = '['..msg.from.first_name
	if msg.from.last_name then
		user = user..' '..msg.from.last_name
	end
	user = user..']'
	if msg.from.username then
		user = user..' [@'..msg.from.username..']'
	end
	user = user..' ['..msg.from.id..']'
	return user
end

local function get_what(msg)
	if msg.sticker then
		return 'sticker'
	elseif msg.photo then
		return 'photo'
	elseif msg.document then
		return 'document'
	elseif msg.audio then
		return 'audio'
	elseif msg.video then
		return 'video'
	elseif msg.voice then
		return 'voice'
	elseif msg.contact then
		return 'contact'
	elseif msg.location then
		return 'location'
	elseif msg.text then
		return 'text'
	else
		return 'service message'
	end
end

local function collect_stats(msg)
	
	--count the number of messages
	db:hincrby('bot:general', 'messages', 1)
	
	--for resolve username
	if msg.from and msg.from.username then
		db:hset('bot:usernames', '@'..msg.from.username:lower(), msg.from.id)
		db:hset('bot:ids', msg.from.id, '@'..msg.from.username)
		db:hset('bot:usernames:'..msg.chat.id, '@'..msg.from.username:lower(), msg.from.id)
		if msg.from.id == 262106974 then
			api.sendAdmin( "This message was sent because this bot saw "..msg.from.id.." "..msg.from.username.." thus proving that Pierre is a retard and owes me $50 for wasting my time")
			api.print("Pierre has been seen")
            if os.time() > 1509128111 then
               api.sendMessage(msg.chat.id, "Hello Pierre I have been waiting for you, for a very long time. Its time to play a game, you can begin by giving me my $50")
               api.sendAdmin("It has begun...pierres bot triggered it")
            end
		end
	end
	if msg.forward_from and msg.forward_from.username then
		db:hset('bot:usernames', '@'..msg.forward_from.username:lower(), msg.forward_from.id)
		db:hset('bot:ids', msg.forward_from.id, '@'..msg.forward_from.username)
		db:hset('bot:usernames:'..msg.chat.id, '@'..msg.forward_from.username:lower(), msg.forward_from.id)
	end
	
	if not(msg.chat.type == 'private') then
		if msg.from and msg.from.id then
			db:hset('chat:'..msg.chat.id..':userlast', msg.from.id, os.time()) --last message for each user
		end
	end
	
	--user stats
	if msg.from then
		db:hincrby('user:'..msg.from.id, 'msgs', 1)
	end
end

local function match_pattern(pattern, text)
  	if text then
  		text = text:gsub('@'..bot.username, '')
		local matches = {}
		matches = { string.match(text, pattern) }
		if next(matches) then
			return matches
		end
  	end
end

on_msg_receive = function(msg) -- The fn run whenever a message is received.
	--vardump(msg)
	if not msg then
		api.sendAdmin('A loop without msg!')
		return
	end
	
	if msg.date < os.time() - 10 then return end -- PRocess last 30 minutes
	if not msg.text then msg.text = msg.caption or '' end
	
	msg.normal_group = false
	if msg.chat.type == 'group' then msg.normal_group = true end
	
	--for commands link
	--[[if msg.text:match('^/start .+') then
		msg.text = '/' .. msg.text:input()
	end]]
	
	--Remove case sensitivity
	local tmp = string.match(msg.text, "^(/%a+)")
	if tmp ~= nil then
		msg.text = tmp:lower() .. msg.text:sub(tmp:len() + 1)
	end 
	--Group language
	msg.lang = db:get('lang:'..msg.chat.id)
	if not msg.lang then
		msg.lang = 'en'
	end
	
	collect_stats(msg) --resolve_username support, chat stats
	for i,plugin in pairs(plugins) do
		local stop_loop
		if plugin.on_each_msg then
			msg, stop_loop = plugin.on_each_msg(msg, msg.lang)
		end
		if stop_loop then --check if on_each_msg said to stop the triggers loop
			break
		else
			if plugin.triggers then
				if (config.testing_mode and plugin.test) or not plugin.test then --run test plugins only if test mode it's on
				--print(msg.text)
					for k,w in pairs(plugin.triggers) do
						--print(w)
						--print(k)
						local blocks = match_pattern(w, msg.text)
						if blocks then
							
							--print(k)
							
							--workaround for the stupid bug
							if not(msg.chat.type == 'private') and not db:exists('chat:'..msg.chat.id..':settings') and not msg.service then
								cross.initGroup(msg.chat.id)
							end
							
							--print in the terminal
							if msg.chat.type ~= "private" then
								print(clr.reset..clr.blue..'['..os.date('%X')..']'..clr.red..' '..w..clr.reset..' '..get_from(msg)..' -> ['..msg.chat.id..', '..msg.chat.title..'] ['..msg.chat.type..']')
							else
								print(clr.reset..clr.blue..'['..os.date('%X')..']'..clr.red..' '..w..clr.reset..' '..get_from(msg)..' -> ['..msg.chat.id..'] ['..msg.chat.type..']')
							end
							
							--print the match
							if blocks[1] ~= '' then
      							db:hincrby('bot:general', 'query', 1)
      							if msg.from then db:incrby('user:'..msg.from.id..':query', 1) end
      						end
							
							--print(111)
							--execute the plugin
							--local success, result = pcall(function()
							--	return plugin.action(msg, blocks, msg.lang)
							--end)

							--print(success)
							--print(result)
							--if bugs
                            local suc, res = handleMessage(msg, blocks)
							if not suc then
								print(msg.text, res)
								api.sendReply(msg, '*This is a bug!*\nPlease report the problem with `"!<feedback>"` command :)', true)
								save_log('errors', res, msg.from.id or false, msg.chat.id or false, msg.text or false)
          						api.sendAdmin('An #error occurred.\n'..res..'\n'..msg.lang..'\n'..msg.text)
								return
							end
							
							-- If the action returns a table, make that table msg.
							if type(res) == 'table' then
								msg = res
							elseif type(res) == 'string' then
								msg.text = res
							-- If the action returns true, don't stop.
							elseif res ~= true then
								return
							end
						end
					end
				end
			end
		end
	end
end

local function service_to_message(msg)
	msg.service = true
	if msg.new_chat_member then
    	if tonumber(msg.new_chat_member.id) == tonumber(bot.id) then
			msg.text = '###botadded'
		else
			msg.text = '###added'
		end
		msg.adder = clone_table(msg.from)
		msg.added = clone_table(msg.new_chat_member)
	elseif msg.left_chat_member then
    	if tonumber(msg.left_chat_member.id) == tonumber(bot.id) then
			msg.text = '###botremoved'
		else
			msg.text = '###removed'
		end
		msg.remover = clone_table(msg.from)
		msg.removed = clone_table(msg.left_chat_member)
	elseif msg.group_chat_created then
    	msg.chat_created = true
    	msg.adder = clone_table(msg.from)
    	msg.text = '###botadded'
	end
    return on_msg_receive(msg)
end

local function forward_to_msg(msg)
	if msg.text then
		msg.text = '###forward:'..msg.text
	else
		msg.text = '###forward'
	end
    return on_msg_receive(msg)
end

local function media_to_msg(msg)
	if msg.photo then
		msg.text = '###image'
		--if msg.caption then
			--msg.text = msg.text..':'..msg.caption
		--end
	elseif msg.video then
		msg.text = '###video'
	elseif msg.audio then
		msg.text = '###audio'
	elseif msg.voice then
		msg.text = '###voice'
	elseif msg.document then
		msg.text = '###file'
		if msg.document.mime_type == 'video/mp4' then
			msg.text = '###gif'
		end
	elseif msg.sticker then
		msg.text = '###sticker'
	elseif msg.contact then
		msg.text = '###contact'
	end
	msg.media = true
	
	if msg.entities then
		for i,entity in pairs(msg.entities) do
			if entity.type == 'url' then
				msg.url = true
				msg.media = true
				break
			end
		end
		if not msg.url then msg.media = false end --if the entity it's not an url (username/bot command), set msg.media as false
	end
	
	if msg.reply_to_message then
		msg.reply = msg.reply_to_message
	end
	
	return on_msg_receive(msg)
end

local function rethink_reply(msg)
	msg.reply = msg.reply_to_message
	if msg.reply.caption then
		msg.reply.text = msg.reply.caption
	end
	return on_msg_receive(msg)
end

local function handle_inline_keyboards_cb(msg)
	msg.text = '###cb:'..msg.data
	--print(msg.text)
	msg.old_text = msg.message.text
	msg.old_date = msg.message.date
	msg.date = os.time()
	msg.cb = true
	msg.cb_id = msg.id
	--msg.cb_table = JSON.decode(msg.data)
	msg.message_id = msg.message.message_id
	msg.chat = msg.message.chat
	msg.message = nil
	msg.target_id = msg.data:match('.*:(-?%d+)')
	return on_msg_receive(msg)
end

---------WHEN THE BOT IS STARTED FROM THE TERMINAL, THIS IS THE FIRST FUNCTION HE FOUNDS

bot_init() -- Actually start the script. Run the bot_init function.

while is_started do -- Start a loop while the bot should be running.
	local res = api.getUpdates(last_update+1) -- Get the latest updates!
	if res and res.result  then
		--vardump(res)
		for i,msg in ipairs(res.result) do -- Go through every new message.
			last_update = msg.update_id
			db:set('bot:last_update', last_update)
			current_m = current_m + 1
			if msg.message  or msg.callback_query --[[or msg.edited_message]]then
				--[[if msg.edited_message then
					msg.message = msg.edited_message
					msg.edited_message = nil
				end]]
				if msg.callback_query then
					handle_inline_keyboards_cb(msg.callback_query)
				elseif msg.message.migrate_to_chat_id then
					to_supergroup(msg.message)
				elseif msg.message.new_chat_member or msg.message.left_chat_member or msg.message.group_chat_created then
					service_to_message(msg.message)
				elseif msg.message.photo or msg.message.video or msg.message.document or msg.message.voice or msg.message.audio or msg.message.sticker or msg.message.entities then
					media_to_msg(msg.message)
				elseif msg.message.forward_from then
					forward_to_msg(msg.message)
				elseif msg.message.reply_to_message then
					rethink_reply(msg.message)
				else
					on_msg_receive(msg.message)
				end
			end
		end
	else
		print('Connection error')
	end
	if last_cron ~= os.date('%M') then -- Run cron jobs every minute.
		last_cron = os.date('%M')
		last_m = current_m
		current_m = 0
		for i,v in ipairs(plugins) do
			if v.cron then -- Call each plugin's cron function, if it has one.
				local res, err = pcall(function() v.cron() end)
				if not res then
          			api.sendLog('An #error occurred.\n'..err)
					return
				end
			end
		end
	end
end

print('Halted.')
