local tr = aegisub.gettext

script_name = tr"Combine Same Time"
script_description = tr"Combine subtitle text whose times are the same regardless of tags"
script_author = "domo"
script_version = "1.0"

separator ="\\N"

function combine(subtitles)
	start = #subtitles
	for i = start,1,-1 do
		if subtitles[i].class == "dialogue" and not subtitles[i].comment and subtitles[i].text ~= "" then
			ntext = subtitles[i].text:gsub("{[^}]+}", "")
			nline = subtitles[i]
			nline.comment = true
			subtitles[i] = nline
			counter = 0
			for j = i-1,1,-1 do
				if (subtitles[j].start_time == subtitles[i].start_time and subtitles[j].end_time == subtitles[i].end_time) then
					ntext = subtitles[j].text:gsub("{[^}]+}", "")..separator..ntext
					counter = counter + 1
					nline.text = ntext
					start = start-1
				end
			end
			nline.comment = false
			if i-start == counter-1 then
				subtitles.append(nline)
			elseif (subtitles[i].start_time ~= subtitles[i-1].start_time or subtitles[i].end_time ~= subtitles[i-1].end_time) and (i-start == 0) then
				subtitles.append(nline)
			end
		end
	end
end

aegisub.register_macro(script_name, script_description, combine)