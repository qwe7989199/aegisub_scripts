local tr = aegisub.gettext
script_name = tr"Import bcc"
script_description = tr"Import bcc(bilibili closed captioning) subtitle to Aegisub"
script_author = "domo"
script_version = "1.0"

function bcc2ass(subtitles)
	local json = require('json')
	local filename = aegisub.dialog.open('Select bcc file', '', '', 'bcc file(*.bcc)|*.bcc', false, true)
	if not filename then
	  aegisub.cancel()
	end
	local bccfile = io.open(filename,"rb")
	if not bccfile then
	  aegisub.debug.out("Failed to load bcc file")
	  aegisub.cancel()
	end
	local json_str = bccfile:read("*all")
	bccfile:close()
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			l = subtitles[i]
			dialogue_start = i - 1
			break
		end
	end
	lyric_tbl = json.decode(json_str)['body']
	for i=1,#lyric_tbl do
		l.start_time = lyric_tbl[i]['from']*1000
		l.end_time = lyric_tbl[i]['to']*1000
		l.text = lyric_tbl[i]['content']
		subtitles.append(l)
	end
end

aegisub.register_macro(script_name, script_description, bcc2ass)