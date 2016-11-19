return {
	--bot_api_key = '197411681:AAHS4-oLnyOhCj4FKoLklK8MvzRKS4tQ2vA',
	bot_api_key = '218011713:AAFJ7xwhvJ58DLfNj5Z-h2lDJDF_RZ0Y6q0',
	version = '3.1', -- /aupdate for v3.1
	testing_mode = false,
	admin =
	{
		owner = 125311351,
		admins =
		{	
		      [125311351] = true,--Daniel Blade Zero
		      [129046388] = true,--Para
			  [263451571] = true, -- Michelle
    		},
		superAdmins = {
		      [125311351] = true,--Daniel Blade Zero
		      [114566255] = false,--Bella Nutella Pup
		      [133748469] = false,--Renatone
		      [129046388] = true,--Para
		      [133439848] = false,--Amelia Rat
			[219387852] = true,--Aurora
			[23776848] = true,--Melisa
			[263451571] = true, -- Michelle
		},
		
		wwGlobalAdmins = {
			[95890871] = true,--Pierre CloneMMDDCCVVII
		      [114566255] = true,--Bella Nutella Pup
		      [133748469] = false,--Renatone
		      [133439848] = true,--Amelia Rat
			[219387852] = true,--Aurora
			[23776848] = true,--Melisa
			[218056872] = true,--Ermenegildo
		},
		
		GlobalBanList = {
			[226703696] = true, --Wese: Impersonation / Stalking
			[104427390] = true, --Lixie: Stalking
			[238377175] = true, --Cropa-Senpai: CP
			[194979294] = true, --Rocco Semental: CP
			[115439685] = true, --Cosme Florencia: CP
			[242242011] = true, -- Moon Man, Trolling all the groups
			[115293868] = true, -- Young Trece: Sudo CP
		}
	},
	log_chat = -1001056443835,
	channel = '@werewolfdev',
	help_group = 'https://telegram.me/werewolfsupport', --group link, not username!
	languages = 'languages.lua',
	plugins = {
		'onmessage.lua', --THIS HAVE TO BE THE FIRST: IF AN USER IS SPAMMING/IS BLOCKED, THE BOT WON'T GO THROUGH PLUGINS
		'all.lua',
		'banhammer.lua',
		'users.lua',
		'help.lua',
		'rules.lua',
		'about.lua',
		'flag.lua',
		'service.lua',
		'links.lua',
		'warn.lua',
		'mediasettings.lua',
		'setlang.lua',
		'floodmanager.lua',
		'private.lua',
		'admin.lua',
		'faq.lua',
		'extra.lua',
		--'test.lua'
	},
	available_languages = {
		'en',
		'it',
		'es',
		'br',
		'ru',
		'de',
		'sv',
		'ar',
		'fr'
		--more to come
	},
	media_list = {
		'image',
		'audio',
		'video',
		'sticker',
		'gif',
		'voice',
		'contact',
		'file',
		'link'
	},
	chat_settings = {
		['settings'] = {
			['Rules'] = 'no',
			['About'] = 'no',
			['Modlist'] = 'no',
			['Report'] = 'yes',
			['Welcome'] = 'no',
			['Extra'] = 'no',
			['Flood'] = 'no',
			['Admin_mode'] = 'yes',
		},
		['flood'] = {
			['MaxFlood'] = 5,
			['ActionFlood'] = 'kick'
		},
		['char'] = {
			['Arab'] = 'allowed',
			['Rtl'] = 'allowed'
		},
		['floodexceptions'] = {
			['image'] = 'no',
			['video'] = 'no',
			['sticker'] = 'no',
			['gif'] = 'no'
		},
		['warnsettings'] = {
			['type'] = 'ban',
			['max'] = 3,
			['mediamax'] = 2
		},
		['welcome'] = {
			['type'] = 'composed',
			['content'] = 'no'
		},
		['media'] = {
			['image'] = 'allowed',
			['audio'] = 'allowed',
			['video'] = 'allowed',
			['sticker'] = 'allowed',
			['gif'] = 'allowed',
			['voice'] = 'allowed',
			['contact'] = 'allowed',
			['file'] = 'allowed',
			['link'] = 'allowed'
		},
	},
	chat_custom_texts = {'rules', 'about', 'extra'},
	api_errors = {
		[101] = 'Not enough rights to kick participant', --SUPERGROUP: bot is not admin
		[102] = 'USER_ADMIN_INVALID', --SUPERGROUP: trying to kick an admin
		[103] = 'method is available for supergroup chats only', --NORMAL: trying to unban
		[104] = 'Only creator of the group can kick administrators from the group', --NORMAL: trying to kick an admin
		[105] = 'Bad Request: Need to be inviter of the user to kick it from the group', --NORMAL: bot is not an admin or everyone is an admin
		[106] = 'USER_NOT_PARTICIPANT', --NORMAL: trying to kick an user that is not in the group
		[107] = 'CHAT_ADMIN_REQUIRED', --NORMAL: bot is not an admin or everyone is an admin
		[108] = 'there is no administrators in the private chat', --something asked in a private chat with the api methods 2.1

		[110] = 'PEER_ID_INVALID', --user never started the bot
		[111] = 'message is not modified', --the edit message method hasn't modified the message
		[112] = 'Can\'t parse message text: Can\'t find end of the entity starting at byte offset %d+', --the markdown is wrong and breaks the delivery
		[113] = 'group chat is migrated to a supergroup chat', --group updated to supergroup
		[114] = 'Message can\'t be forwarded', --unknown
		[115] = 'Message text is empty', --empty message
		[116] = 'message not found', --message id invalid, I guess
		[117] = 'chat not found', --I don't know
		[118] = 'Message is too long', --over 4096 char
		[119] = 'User not found', --unknown user_id

		[120] = 'Can\'t parse reply keyboard markup JSON object', --keyboard table invalid
		[121] = 'Field \\\"inline_keyboard\\\" of the InlineKeyboardMarkup should be an Array of Arrays', --inline keyboard is not an array of array
		[122] = 'Can\'t parse inline keyboard button: InlineKeyboardButton should be an Object',
		[123] = 'Bad Request: Object expected as reply markup', --empty inline keyboard table
		[124] = 'QUERY_ID_INVALID', --callback query id invalid
		[125] = 'CHANNEL_PRIVATE', --I don't know
		[126] = 'MESSAGE_TOO_LONG', --text of an inline callback answer is too long
		[127] = 'wrong user_id specified', --invalid user_id
		[128] = 'Too big total timeout [%d%.]+', --something about spam an inline keyboards
		[129] = 'BUTTON_DATA_INVALID', --callback_data string invalid

		[130] = 'Type of file to send mismatch', --trying to send a media with the wrong method
		[131] = 'MESSAGE_ID_INVALID', --I don't know
		[132] = 'Can\'t parse inline keyboard button: Can\'t find field "text"', --the text of a button could be nil
		[133] = 'Can\'t parse inline keyboard button: Field \\\"text\\\" must be of type String',
		[134] = 'USER_ID_INVALID',
		[135] = 'CHAT_INVALID',

		[403] = 'Bot was blocked by the user', --user blocked the bot
		[429] = 'Too many requests: retry later', --the bot is hitting api limits
		[430] = 'Too big total timeout', --too many callback_data requests
	}
}
