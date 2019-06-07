local tr = aegisub.gettext
script_name = tr("Add k tags")
script_description = tr("Add k tags to selected lines")
script_author = "domo"
script_version = "1.2"

include("unicode.lua")

function add_k1(subtitles, selected_lines, active_line)
	k_type = "k1"
	add_k(k_type,subtitles, selected_lines, active_line)
	return ""
end

function add_k_avg(subtitles, selected_lines, active_line)
	k_type = "avg"
	add_k(k_type,subtitles, selected_lines, active_line)
	return ""
end

function add_k_percent(subtitles, selected_lines, active_line)
	k_type = "percentage"
	dialog_config =	{
	{class="label",x=2,y=0,width=1,height=1,label="Percent(%):"},
	{class="intedit",name="Percent",x=3,y=0,width=1,min=1,max=100,height=1,value="100"},
	}
	cfg_res,config =_G.aegisub.dialog.display(dialog_config)
	percent = config.Percent
	add_k(k_type,subtitles, selected_lines, active_line,percent)
	return
end

function add_k(k_type,subtitles, selected_lines, active_line,percent)
	syl_i = 0
	n = 0
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		syl_n = unicode.len(l.text)
		l.duration = l.end_time-l.start_time
		if k_type == "k1" then 
			k_value = 1
		elseif k_type == "avg" then
			k_value = math.floor(l.duration/10/syl_n+0.5)
		elseif k_type == "percentage" then
			k_value = math.floor(l.duration/10/syl_n*percent/100+0.5)
		else
		end
		if l.class == "dialogue" then
			n = n+1
		end
		text = ""
		if string.find(l.text,"[\\|{|}]") ~= nil then
			aegisub.debug.out("Please delete all existing tags in line "..tostring(n).."\n")
		else
			for uchar in string.gmatch(l.text, "[%z\1-\127\194-\244][\128-\191]*") do
				syl_i = syl_i+1
				text = text..string.format("{\\k%d}",k_value)..uchar
			end
		l.text = text
		subtitles[i] = l
		end
	end
	aegisub.set_undo_point(script_name)
end
aegisub.register_macro(script_name.."/k1", tr"Add {\\k1} for all lines", add_k1)
aegisub.register_macro(script_name.."/Avg k", tr"Add average k tags for all lines", add_k_avg)
aegisub.register_macro(script_name.."/percent k", tr"Add k tags by percent of average time for all lines", add_k_percent)
