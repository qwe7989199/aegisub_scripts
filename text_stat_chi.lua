local tr = aegisub.gettext
script_name = tr"文本统计"
script_description = tr"对所选行进行文本统计"
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
	MinLineDuration=36000000
	MinDurationIndex=0
	MaxLineLength=0
	MaxLengthIndex=0
	MinLineLength=36000000
	MinLengthIndex=0
	fullWidthSpaceNum=0
	TotalDuration=0
	LineLength={}
	LineDuration={}
	min_k={dur=36000000,line_index=0}
	max_k={dur=0,line_index=0}
	BoundaryKDurOfLine={[0]={max=0,min=36000000}}
	for z, i in ipairs(selected_lines) do
		l = subtitles[i]
		if l.comment==true or string.find(l.effect,"template") or string.find(l.effect,"code") then
			aegisub.debug.out("Line #"..i-dialogue_start.." ignored.\n")
		else
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
			--Max Line length
			LineLength[i]=unicode.len(text_stripped)
			--Max Line duration
			LineDuration[i]=(l.end_time-l.start_time)/1000
			TotalDuration=TotalDuration+LineDuration[i]
		end
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
	if not karaoke or min_k.dur==3600000 or max_k.dur==0 then 		
		max_k.dur='不可用'
		min_k.dur='不可用'
		max_k.line_index='不可用'
		min_k.line_index='不可用'
	elseif TotalLineNum==1 then 
		max_k.line_index='不可用'
		min_k.line_index='不可用'
	end

	config = {
    {x=0, y=0, class="label", label="统计结果: "},
	{x=0, y=1, class="label", label="　　已选择的行数: "..TotalLineNum},
	{x=0, y=2, class="label", label="　　总持续时间: "..TotalDuration},
	{x=0, y=3, class="label", label="　　总音节数: "..TotalKNum},
	{x=0, y=4, class="label", label="　　总字数(含空格): "..TotalWordsNum},
	{x=0, y=5, class="label", label="　　英文字数: "..EngWordsNum},
	{x=0, y=6, class="label", label="　　非英文字数: "..NonEngCharsNum},
	{x=0, y=7, class="label", label="　　半角空格数: "..SpaceNum-fullWidthSpaceNum},
	{x=0, y=8, class="label", label="　　全角空格数: "..fullWidthSpaceNum},

	{x=1, y=1, width=15, class="label", label="　　字符最多的行: "..MaxLineLength.."        | 行号: "..MaxLengthIndex},
	{x=1, y=2, width=15, class="label", label="　　字符少的行: "..MinLineLength.."          | 行号: "..MinLengthIndex},
	{x=1, y=3, width=15, class="label", label="　　时间最长的行: "..MaxLineDuration.." (秒) | 行号: "..MaxDurationIndex},
	{x=1, y=4, width=15, class="label", label="　　时间最短的行: "..MinLineDuration.." (秒) | 行号: "..MinDurationIndex},
	{x=1, y=5, width=15, class="label", label="　　时间最长的音节: "..max_k.dur.." (毫秒)   | 行号: "..max_k.line_index},
	{x=1, y=6, width=15, class="label", label="　　时间最短的音节: "..min_k.dur.." (毫秒)   | 行号: "..min_k.line_index},
	} 
	btn, result = aegisub.dialog.display(config,{"OK","Save"})
	if btn=="Save" then
		scriptname=string.sub(aegisub.file_name(),1,-5)
		file_name=aegisub.dialog.save("保存文件到",aegisub.decode_path("?script").."\\", scriptname.."_stats", "*.csv")
		if not file_name then aegisub.cancel() end
		file=io.open(file_name,"w")
		file:write("\239\187\191"
		.."已选择的行数,"..TotalLineNum.."\n"
		.."总持续时间,"..TotalDuration.."\n"
		.."总音节数,"..TotalKNum.."\n"
		.."总字数(含空格),"..TotalWordsNum.."\n"
		.."英文字数,"..EngWordsNum.."\n"
		.."非英文字数,"..NonEngCharsNum.."\n"
		.."半角空格数,"..SpaceNum-fullWidthSpaceNum.."\n"
		.."全角空格数,"..fullWidthSpaceNum.."\n"
		.."字符最多的行,"..MaxLineLength..",行号,"..MaxLengthIndex.."\n"
		.."字符少的行,"..MinLineLength..",行号,"..MinLengthIndex.."\n"
		.."时间最长的行,"..MaxLineDuration..",行号,"..MaxDurationIndex.."\n"
		.."时间最短的行,"..MinLineDuration..",行号,"..MinDurationIndex.."\n"
		.."时间最长的音节,"..max_k.dur..",行号,"..max_k.line_index.."\n"
		.."时间最短的音节,"..min_k.dur..",行号,"..min_k.line_index.."\n"
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
