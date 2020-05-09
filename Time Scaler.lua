local tr = aegisub.gettext
script_name = tr"Time Scaler"
script_description = tr"You can use this if only BPM changed"
script_author = "domo"
script_version = "1.0"

function time_scaling(subtitles, selected_lines)
	for i=1,#subtitles do
		if subtitles[i].class == "dialogue" then
			dialogue_start=i
			break
		end
	end
	dialog_config=
	{
	{class="label",x=2,y=0,width=1,height=1,label="Original BPM: "},
	{class="floatedit",name="org_bpm",x=3,y=0,width=1,height=1,value="",min=0,max=1E4},
	{class="label",x=2,y=1,width=1,height=1,label="New BPM: "},
	{class="floatedit",name="new_bpm",x=3,y=1,width=1,height=1,value="",min=0,max=1E4},
	}
	cfg_res,config = aegisub.dialog.display(dialog_config)
	ratio = config.org_bpm/config.new_bpm
	if tostring(ratio)=="nan" or tostring(ratio)=="inf" then
		aegisub.debug.out("Valid BPM required.")
		aegisub.cancel()
	end
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		l.comment = true
		subtitles[i] = l
		time_checker(l.end_time-l.start_time, l.text, "before_scale" ,i)
		l.comment = false
		l.start_time = ratio * l.start_time
		l.end_time   = ratio * l.end_time
		l.text       = string.gsub(l.text, "{\\k(%d+)}",function(kdur) return string.format("{\\k%d}",ratio * kdur) end)
		l.text       = error_handler(l.text, l.end_time - l.start_time)
		l.effect     = string.format(l.effect.." %.2f x",ratio)
		subtitles.append(l)
	end
	aegisub.debug.out("Done.")
end

function error_handler(ltext, ldur)
	error_t, dur = time_checker(ldur, ltext)
	--aegisub.debug.out(tostring(error_t))
	for i=1,#dur do
		if dur[i]-error_t>=1 then
			sub_n = i
			break
		end
	end
	ltext = string.gsub(ltext,"{\\k(%d+)}",function(kdur) return string.format("{\\k%d}",kdur-error_t) end,sub_n)
	return ltext
end

function time_checker(ldur, ltext, stage, line_index)
    tot_dur, dur, index = 0 , {}, 0
	for num in string.gmatch(ltext, "{\\k(%d+)}") do
		tot_dur    = tot_dur + num
		index      = index + 1
		dur[index] = tonumber(num)
	end
	if tot_dur>ldur/10 and stage=="before_scale" then
		aegisub.debug.out("Total K time is larger than line duration in line "..(line_index-dialogue_start+1))
		aegisub.cancel()
	end
	return (tot_dur - ldur/10),dur
end

aegisub.register_macro(script_name, script_description, time_scaling)
