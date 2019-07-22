local tr = aegisub.gettext
script_name = tr"Text Stats"
script_description = tr"Statistics for selected lines"
script_author = "domo"
script_version = "1.0"

include("unicode.lua")
k_threshold=1

function text_stat(subtitles, selected_lines, active_line)
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			dialogue_start=i
			break
		end
	end
	TotalLineNum=#selected_lines
	TotalKNum=0      
	EngWordsNum=0	   
	NonEngCharsNum=0   
	SpaceNum=0		   
	MaxLineDuration=0
	MaxDurationIndex=0
	MinLineDuration=99999
	MinDurationIndex=0
	MaxLineLength=0
	MaxLengthIndex=0
	MinLineLength=99999
	MinLengthIndex=0
	fullWidthSpaceNum=0
	LineLength={}
	LineDuration={}
	min_k={dur=99999,line_index=0}
	max_k={dur=0,line_index=0}
	BoundaryKDurOfLine={[0]={max=0,min=99999}}
	for z, i in ipairs(selected_lines) do
		l = subtitles[i]
		--Deal with karaoke first
		if string.find(l.text,"\\[kK][fo]?%d+")~=nil then
			karaoke=true
			BoundaryKDurOfLine=k_stat(l.text,i)
			TotalKNum=TotalKNum+BoundaryKDurOfLine[i].kNum
		end
		--Strip tags
		text_stripped=string.gsub(l.text,"%{.-%}","")
		if text_stripped=="" and TotalLineNum==1 then
			aegisub.debug.out("Only empty line selected.")
			aegisub.cancel()
		end
		--Space number half-width
		for space in string.gmatch(text_stripped," ") do
			SpaceNum=SpaceNum+1
		end
		--Space number full-width
		for space in string.gmatch(text_stripped,"　") do
			SpaceNum=SpaceNum+1
			fullWidthSpaceNum=fullWidthSpaceNum+1
		end
		--English words number
		for word in string.gmatch(text_stripped,"(%w+)") do
			EngWordsNum=EngWordsNum+1
		end
		--Non English words number
		for utf8char in string.gmatch(text_stripped,"[%z\194-\244][\128-\191]*") do
			NonEngCharsNum=NonEngCharsNum+1
		end
		--Line length
		LineLength[i]=unicode.len(text_stripped)
		--Line duration
		LineDuration[i]=(l.end_time-l.start_time)/1000
	end
	TotalWordsNum=EngWordsNum+NonEngCharsNum-fullWidthSpaceNum
	NonEngCharsNum=NonEngCharsNum-fullWidthSpaceNum
	for i,v in pairs(BoundaryKDurOfLine) do
		if v.min<min_k.dur then
			min_k.dur=v.min
			min_k.line_index=i-dialogue_start+1
		end
		if v.max>max_k.dur then
			max_k.dur=v.max
			max_k.line_index=i-dialogue_start+1
		end
	end
	max_k.dur=math.floor(max_k.dur*10+0.5)
	min_k.dur=math.floor(min_k.dur*10+0.5)

	for i,v in pairs(LineDuration) do
		if v>=MaxLineDuration then
			MaxLineDuration=v
			MaxDurationIndex=i-dialogue_start+1
		end
		if v<=MinLineDuration and v>0 then
			MinLineDuration=v
			MinDurationIndex=i-dialogue_start+1
		end
	end
	for i,v in pairs(LineLength) do
		if v>=MaxLineLength then
			MaxLineLength=v
			MaxLengthIndex=i-dialogue_start+1
		end
		if v<=MinLineLength and v>0 then
			MinLineLength=v
			MinLengthIndex=i-dialogue_start+1
		end
	end
	show_result()
end

function show_result()
	if not karaoke or min_k.dur==0 or min_k.dur==0 then 
		max_k.dur='Not Valid'
		min_k.dur='Not Valid'
		max_k.line_index='Not Valid'
		min_k.line_index='Not Valid'
	elseif TotalLineNum==1 then 
		max_k.line_index='Not Valid'
		min_k.line_index='Not Valid'
	end

	config = {
    {x=0, y=0, class="label", label="Results: "},
	{x=0, y=1, class="label", label="   Selected Line Num: "..TotalLineNum},
	{x=0, y=2, class="label", label="   Total Syl Num: "..TotalKNum},
	{x=0, y=3, class="label", label="   Total Words(Space counted): "..TotalWordsNum},
	{x=0, y=4, class="label", label="   English Words Num: "..EngWordsNum},
	{x=0, y=5, class="label", label="   Non-English Char Num: "..NonEngCharsNum},
	{x=0, y=6, class="label", label="   Half-Width Space Num: "..SpaceNum-fullWidthSpaceNum},
	{x=0, y=7, class="label", label="   Full-Width Space Num: "..fullWidthSpaceNum},

	{x=6, y=1, class="label", label="   Max Line Length: "..MaxLineLength.."         | Index: "..MaxLengthIndex},
	{x=6, y=2, class="label", label="   Min Line Length: "..MinLineLength.."         | Index: "..MinLengthIndex},
	{x=6, y=3, class="label", label="   Max Line Duration: "..MaxLineDuration.." (s) | Index: "..MaxDurationIndex},
	{x=6, y=4, class="label", label="   Min Line Duration: "..MinLineDuration.." (s) | Index: "..MinDurationIndex},
	{x=6, y=5, class="label", label="   Max Syl Duration: "..max_k.dur.." (ms)       | Index: "..max_k.line_index},
	{x=6, y=6, class="label", label="   Min Syl Duration: "..min_k.dur.." (ms)       | Index: "..min_k.line_index},
	}
	btn, result = aegisub.dialog.display(config,{"OK","Save"})
	if btn=="Save" then
		scriptname=string.sub(aegisub.file_name(),1,-5)
		file_name=aegisub.dialog.save("Save to",aegisub.decode_path("?script").."\\", scriptname.."_stats", "*.txt")
		if not file_name then aegisub.cancel() end
		file=io.open(file_name,"w")
		file:write("Results: \n"
		.."　　Selected Line Num: "..TotalLineNum.."\n"
		.."　　Total Syl Num: "..TotalKNum.."\n"
		.."　　Total Words(Space counted): "..TotalWordsNum.."\n"
		.."　　English Words Num: "..EngWordsNum.."\n"
		.."　　Non-English Char Num: "..NonEngCharsNum.."\n"
		.."　　Half-Width Space Num: "..SpaceNum-fullWidthSpaceNum.."\n"
		.."　　Full-Width Space Num: "..fullWidthSpaceNum.."\n"
		.."　　Max Line Length: "..MaxLineLength.."          | Index: "..MaxLengthIndex.."\n"
		.."　　Min Line Length: "..MinLineLength.."          | Index: "..MinLengthIndex.."\n"
		.."　　Max Line Duration: "..MaxLineDuration.." (s)  | Index: "..MaxDurationIndex.."\n"
		.."　　Min Line Duration: "..MinLineDuration.." (s)  | Index: "..MinDurationIndex.."\n"
		.."　　Max Syl Duration: "..max_k.dur.." (ms)        | Index: "..max_k.line_index.."\n"
		.."　　Min Syl Duration: "..min_k.dur.." (ms)        | Index: "..min_k.line_index.."\n"
		)
		file:close()
	end
end

function k_stat(text,i)
	k_dur_t={}
	kNum=0
	for kdur in string.gmatch(text,"\\[kK][fo]?(%d+)") do
		kNum=kNum+1
		if tonumber(kdur)>k_threshold then
			k_dur_t[#k_dur_t+1]=kdur
		end
	end
	BoundaryKDurOfLine[i]={max=math.max(unpack(k_dur_t)),min=math.min(unpack(k_dur_t)),kNum=kNum}
	return BoundaryKDurOfLine
end

aegisub.register_macro(script_name, script_description,text_stat)