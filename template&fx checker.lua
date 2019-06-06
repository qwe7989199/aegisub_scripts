local tr = aegisub.gettext
script_name = tr"Check Tags"
script_description = tr"Check tags inside template line or fx line"
script_author = "domo"
script_version = "0.99"
script_created = "2019/06/03"
script_last_updated = "2019/06/05"

local position_tags = {"move","pos","mover","moves3","moves4"}
local work_with_t = {"bord","xbord","ybord","shad","xshad","yshad","be","blur","fs","fscx","fscy",
					"fsp","frx","fry","frz","fr","fax","fay","c","1c","2c","3c","4c","alpha","1a","2a","3a","4a","clip","iclip",
					"fsc","fsvp","frs","z","distort","jitter","rnd","rndz","rndx","rndy",
					"1vc","2vc","3vc","4vc","1va","2va","3va","4va","1img","2img","3img","4img"}
local other_tags = {"i","b","u","s","an","k","kf","K","ko","q","fn","r","movevc","fad","fade","org","fe","t"}

local function split(str, split_char)	
	local sub_str_tab = {}
	while true do
		local pos = string.find(str, split_char)
		if not pos then
			table.insert(sub_str_tab,str)
		break
		end
		local sub_str = string.sub(str, 1, pos - 1)
		table.insert(sub_str_tab,sub_str)
		str = string.sub(str, pos + 1, string.len(str))
	end
	return sub_str_tab 
end

local function tag_counter(tbl)
	entry_num = {}
	table.sort(tbl)
	--aegisub.debug.out(Y.table.tostring(tbl))
	for k,v in pairs(tbl) do
		if entry_num[tbl[k]] == nil then
			entry_num[tbl[k]] = 1
		else
			entry_num[tbl[k]] = entry_num[tbl[k]] + 1
		end
	end
	return entry_num
end

function is_include(value, tbl)
    for k,v in _G.ipairs(tbl) do
      if v == value then
          return true
      end
    end
    return false
end

function delete_empty(tbl)
	for i=#tbl,1,-1 do
		if tbl[i] == "" or tbl[i]==nil then
			table.remove(tbl, i)
		end
	end
	return tbl
end

local function checktwo(tag1, tag2)
	local p1_s, _, p1_tag = string.find(str, tag1.."%(")
	local p2_s, _, p2_tag = string.find(str, tag2.."%(")
	if (p1_s and p2_s) and (p1_s~=p2_s) then 
		aegisub.debug.out("Conflict between ["..tag1.."] and ["..tag2.."].\n")
	end
end

local function checknott(tags)
	--in case of fn
	tags = string.gsub(tags,"\\fn[^\\]*\\","\\fn\\")
	tags = string.gsub(tags,"\\t","")
	split_tags = split(tags,"\\")
	for i=1,#split_tags do
		split_tags[i] = string.match(split_tags[i],"([%d]?%l+)")
	end
	split_tags = delete_empty(split_tags)
	for i=1,#position_tags do
		if is_include(position_tags[i],split_tags) then
			aegisub.debug.out("["..position_tags[i].."] is not supported by t.\n")
		end
	end
	for i=1,#other_tags do
		if is_include(other_tags[i],split_tags) then
			aegisub.debug.out("["..other_tags[i].."] is not supported by t.\n")
		end
	end
end

local function checksame(tags,in_t)
	--in case of fn[string] tag
	tags = string.gsub(tags,"\\fn[^\\]*\\","\\fn\\") --need to be fixed
	split_tags = split(tags,"\\")
	for i=1,#split_tags do
		split_tags[i] = string.match(split_tags[i],"([%d]?%l+[%d]?)")
	end
	split_tags = delete_empty(split_tags)
	entry_num = tag_counter(split_tags)

	for i=1,#work_with_t do
		if entry_num[work_with_t[i]] and entry_num[work_with_t[i]]>=2 then
			if in_t then
				aegisub.debug.out("["..work_with_t[i].."] appears "..entry_num[work_with_t[i]].." times inside one t tag.\n")
			else 
				aegisub.debug.out("["..work_with_t[i].."] appears "..entry_num[work_with_t[i]].." times in one line.\n")
			end
		end
	end
	
	for i=1,#position_tags do
		if entry_num[position_tags[i]] and entry_num[position_tags[i]]>=2 then
			aegisub.debug.out("["..position_tags[i].."] appears "..entry_num[position_tags[i]].." times in one line.\n")
		end
	end
	
	for i=1,#other_tags do
		if entry_num[other_tags[i]] and entry_num[other_tags[i]]>=2 then
			aegisub.debug.out("["..other_tags[i].."] appears "..entry_num[other_tags[i]].." times in one line.\n")
		end
	end
end

local function checkclip(tag,in_t)
	if string.find(tag,"m ")~=nil and in_t then
		aegisub.debug.out("[(i)clip]'s assdrawing format is not supported by t.\n")
		-- Ignore inline variables
	elseif string.find(tag,"$")~=nil then
	else
		local x1,y1,x2,y2 = string.match(tag,"(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
		if tonumber(x1) > tonumber(x2) or tonumber(y1) > tonumber(y2) then
			aegisub.debug.out("LT coordinate should not be greater than RB in [(i)clip].\n")
		else
		end
	end
end

local function checkt(tags,case)
	--check is there any tag not supported by t
	checknott(tags)
	--check duplicate inside t
	checksame(tags,true)
	--check clip tag inside t
	if case == 2 then
		for clip_tag in string.gmatch(tags,"\\[i]?clip%([^%(%)]*%)") do
			checkclip(clip_tag,true)
		end
	end
end

function check(subtitles, selected_lines)
	for i=1,#subtitles do
		if subtitles[i].class == "dialogue" then
			dialogue_start=i
			break
		end
	end
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		index = i
		if string.find(l.effect,"code")~=nil or string.find(l.effect,"karaoke")~=nil then
			aegisub.debug.out("[Line #"..tostring(index-dialogue_start+1).."]: Ignored.\n")
		else
			aegisub.debug.out("[Line #"..tostring(index-dialogue_start+1).."]: \n")
			str = string.gsub(l.text,"%![^%!]*%!","")
			checktwo("fade","fad")
			--check pos move mover moves3/4
			for i = 1,#position_tags do
				for j = 1,#position_tags do
					if i==j then break else
						checktwo(position_tags[i],position_tags[j])
					end
				end
			end
			--case 1 simple
			for t_tag in string.gmatch(str,"\\t%([^%(%)]*%)") do
				str = string.gsub(str,"\\t%([^%(%)]*%)","",1)
				checkt(t_tag,1)
			end
			--case 2 nested
			for t_tag in string.gmatch(str,"\\t%([^%)]*%)[^%)]*%)") do
				str = string.gsub(str,"\\t%([^%)]*%)[^%)]*%)","",1)
				checkt(t_tag,2)
			end
			--check other tags left
			checksame(str)
			--check clip parameters
			for clip_tag in string.gmatch(str,"\\clip%([^%(%)]*%)") do
				checkclip(clip_tag)
			end
		end
	end
end

aegisub.register_macro(script_name, script_description, check)
