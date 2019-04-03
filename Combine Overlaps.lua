local tr = aegisub.gettext

script_name = tr"Combine Overlaps"
script_description = tr"Combine subtitle lines whose times are overlapped regardless of tags"
script_author = "domo"
script_version = "1.0"

separator ="\\N"

function combine(subtitles)
	dialogue = {}
	for i = 1,#subtitles do
		if subtitles[i].class == "dialogue" and not subtitles[i].comment and subtitles[i].text ~= "" then
			table.insert(dialogue,subtitles[i])
			subtitles[i].comment = true
			subtitles[i] = subtitles[i]
		end
	end
	table.sort(dialogue,function (a,b) return a.start_time < b.start_time or (a.end_time < b.end_time and string.len(a.text) < string.len(b.text)) end)
	dialogue[0] = dialogue[1]
	dialogue[0].end_time = 36000000
	overlaps = {}
	normal = {}
	--table for normal lines
	for i = 1,#dialogue-1 do
        if dialogue[i].end_time <= dialogue[i+1].start_time and dialogue[i].start_time >= dialogue[i-1].end_time then
			table.insert(normal,dialogue[i])
		end
	end
	--table for overlapped lines
	end_time = 0
	for i = 1,#dialogue-1 do
        if dialogue[i].end_time <= dialogue[i+1].start_time then
            end_time = dialogue[i].end_time
        else
			dialogue[i+1].text = dialogue[i].text:gsub("{[^}]+}", "")..separator..dialogue[i+1].text:gsub("{[^}]+}", "")
			dialogue[i+1].start_time = dialogue[i].start_time
			dialogue[i+1].end_time = dialogue[i+1].end_time
			i = i + 1
			table.insert(overlaps,dialogue[i])
		end
	end
	--append lines
	for i = 1,#overlaps-1 do
		if string.find(overlaps[i+1].text,overlaps[i].text..separator) == nil then
			subtitles.append(overlaps[i])
		end
	end
	subtitles.append(overlaps[#overlaps])
	for i = 1,#normal do
		subtitles.append(normal[i])
	end
end

aegisub.register_macro(script_name, script_description, combine)