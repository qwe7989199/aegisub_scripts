--[[	Script for encoding / trimming / hardsubbing

	Options:
	- encode
		- the video
		- a clip
		- Aegisub's dummy video
		
	- encode using 
		- AMD GPU (Video Encoder Engine VCEEncC64.exe)
		- Intel GPU (Quick Sync Video QSVEncC64.exe)
		- NVIDIA GPU (Nvidia Video Encoding NVEncC64.exe)
		- or VSPipe.exe+x264.exe (CPU)
		- ffmpeg (only for mov file)

	- hardsub 0 or 1 or 2 subtitle file(s) using
		- vsfilter
		- vsfiltermod
	
	- trim audio refer to clip
		- LC-AAC
		- NeroAAC (HE-AAC)
		
	- encode to
		- mp4
		- mkv (original audio will be preserved if not trim)
		- mov (with alpha channel)

	- parameters of encoder
		- VCEEnc
			- preset
			- bitrate
		- QSVEnc
			- preset
			- mode
				- vbr
					- bitrate
				- icq
					- icq
			- other
		- NVEnc
			- preset
			- bitrate
		- x264
			- preset
			- crf
		- ffmpeg
			- qtrle (fast, small, lossless, not supported after Adobe Premiere CC2018)
			- png (slow, big, good compatibility)

	Requirements:
	- NegativeEncoder's directory structure (https://github.com/zyzsdy/NegativeEncoder)
	- one of [VSPipe.exe and x264.exe] | [NVEncC64.exe] | [QSVEncC64.exe] | [VCEEncC64.exe] (isn't contained in NegativeEncoder's Lib, need to be set manually)
	- ffmpeg.exe (for audio mux and mov file)
	- neroAacEnc.exe
	- [vsfilter.dll] (https://github.com/HomeOfVapourSynthEvolution/VSFilter/releases) 
	- and/or [vsfiltermod.dll] (https://github.com/sorayuki/VSFilterMod/releases) for hardsubbing
--]]

script_name="Encode - Hardsub - VapourSynth"
script_description="Encode a clip w/o hardsubs"
script_author="domo"
script_version="1.2"

local dummy_duration=600  --maximum dummy video duration threshold (second)
local neroquality=0.5
include("utils.lua")

function encode_vs(subs,sel)
	P=""
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ADO=aegisub.dialog.open
	ADOT=aegisub.debug.out
	ak=aegisub.cancel
	csripath=ADP("?data").."\\csri\\"
	enconfig=ADP("?user").."\\encode_hardsub_vs.conf"
	scriptpath=ADP("?script").."\\"
	scriptname=aegisub.file_name()
	vpath=ADP("?video").."\\"
	apath=ADP("?audio").."\\"
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	sframe=999999
	eframe=0
	videoname=nil
	file=io.open(enconfig)
	if file~=nil then
		konf=file:read("*all")
		io.close(file)
		NegaEncpath=konf:match("NegaEncpath:(.-)\n")
		xpath=konf:match("xpath:(.-)\n")
		VSPipepath=konf:match("VSPipepath:(.-)\n")
		nvencpath=konf:match("nvencpath:(.-)\n")
		qsvencpath=konf:match("qsvencpath:(.-)\n")
		vceencpath=konf:match("vceencpath:(.-)\n")
		GPUs=konf:match("GPUs:(.-)\n")
		sett=konf:match("enc_sets:(.-)\n")
		vsfpath=konf:match("vsfpath:(.-)\n")
		vsfmpath=konf:match("vsfmpath:(.-)\n")
		ffmpegpath=konf:match("ffmpegpath:(.-)\n") or ""
		vtype=konf:match("vtype:(.-)\n")
		vsf1=konf:match("filter1:(.-)\n")
		vsf2=konf:match("filter2:(.-)\n")
		targ=konf:match("targ:(.-)\n")
		target=konf:match("target:(.-)\n")
	else
		NegaEncpath=""
		xpath=""
		VSPipepath=""
		nvencpath=""
		qsvencpath=""
		vceencpath=""
		GPUs=""
		vsfpath=""
		vsfmpath=""
		ffmpegpath=""
		vtype=".mkv"
		vsf1="vsfilter"
		vsf2="vsfilter"
		settlist=""
		targ="Same as source"
		target=""
	end
	if NegaEncpath~="" then
		NegaEncLib=string.match(NegaEncpath,"(.*\\).*.exe").."Libs"
	end
	for i=1,#subs do
		if subs[i].class=="info" then
			if subs[i].key=="Audio File" then audioname=subs[i].value end
			if subs[i].key=="Video File" then videoname=subs[i].value break end
		end
		if subs[i].class~="info" then break end
	end
	if audioname==nil then audioname=aegisub.project_properties().audio_file:gsub("^.*\\","") end
	if videoname==nil then videoname=aegisub.project_properties().video_file:gsub("^.*\\","") end
	if videoname==nil or videoname=="" or aegisub.frame_from_ms(10)==nil then t_error("No video detected.",1) end
	if string.find(videoname,"?dummy") then --dummy video
		dummy_video=true
		dummy,frame_rate,length,x_res,y_res,r,g,b,checkerboard = string.match(videoname,
		"([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
	end
	vid2=videoname:gsub("%.[^%.]+","") :gsub("_?premux","") :gsub("_?workraw","")
	vid2=vid2:gsub("[?:]","").."_hardsub"
	for z,i in ipairs(sel) do
		line=subs[i]
		start=line.start_time
		endt=line.end_time
		sfr=ms2fr(start)
		efr=ms2fr(endt)
	if sfr<sframe then sframe=sfr end
	if efr>eframe then eframe=efr end
	end
	
	require("enc_gui")
	GUI=GUI_Config.vs
	
	repeat
	
	if P=="NegaEnc" then
		NegaEnc_path=ADO("NegaEnc","",scriptpath,"*.exe",false,true)
		gui("NegaEncpath",NegaEnc_path)
	end
	if NegaEnc_path~="" and NegaEnc_path~=nil then NegaEncLib=string.match(NegaEnc_path,"(.*\\).*.exe").."Libs" end
	if P=="x264" then
		x264_path=ADO("x264","",scriptpath,"*.exe",false,true)
		gui("xpath",x264_path)
	end
	if P=="VSPipe" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\VSPipe.exe") else err="" end
		if err==nil then
			gui("VSPipepath",NegaEncLib.."\\VSPipe.exe")
		else
			VSPipe_path=ADO("VSPipe","",scriptpath,"*.exe",false,true)
			gui("VSPipepath",VSPipe_path)
		end
	end
	if P=="NVEncC64" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\NVEncC64.exe") else err="" end
		if err==nil then
			gui("nvencpath",NegaEncLib.."\\NVEncC64.exe")
		else
			NVEncC64_path=ADO("NVEncC64","",scriptpath,"*.exe",false,true)
			gui("nvencpath",NVEncC64_path)
		end
	end
	if P=="QSVEncC64" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\QSVEncC64.exe") else err="" end
		if err==nil then
			gui("qsvencpath",NegaEncLib.."\\QSVEncC64.exe")
		else
			QSVEncC64_path=ADO("QSVEncC64","",scriptpath,"*.exe",false,true)
			gui("qsvencpath",QSVEncC64_path)
		end
	end
	if P=="VCEEncC64" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\VCEEncC64.exe") else err="" end
		if err==nil then
			gui("vceencpath",NegaEncLib.."\\VCEEncC64.exe")
		else
			VCEEncC64_path=ADO("VCEEncC64","",scriptpath,"*.exe",false,true)
			gui("vceencpath",VCEEncC64_path)
		end
	end
	if P=="vsfilter" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\vapoursynth64\\plugins\\vsfilter.dll") else err="" end
		if err==nil then
			gui("vsf",NegaEncLib.."\\vapoursynth64\\plugins\\vsfilter.dll")
		else
			vsf_path=ADO("vsfilter","",scriptpath,"*.dll",false,true)
			gui("vsf",vsf_path)
		end
	end
	if P=="vsfiltermod" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\vapoursynth64\\plugins\\VSFilterMod.dll") else err="" end
		if err==nil then
			gui("vsfm",NegaEncLib.."\\vapoursynth64\\plugins\\VSFilterMod.dll")
		else
			vsf_path=ADO("vsfiltermod","",scriptpath,"*.dll",false,true)
			gui("vsfm",vsfm_path)
		end
	end
	if P=="ffmpeg" then
		if NegaEncLib~=nil and NegaEncLib~="" then _,err=io.open(NegaEncLib.."\\ffmpeg.exe") else err="" end
		if err==nil then
			gui("ffmpeg",NegaEncLib.."\\ffmpeg.exe")
		else
			ffmpegpath=ADO("ffmpeg","",scriptpath,"*.exe",false,true)
			gui("ffmpeg",ffmpegpath)
		end
	end
	if P=="Target" then
		tgt_path=ADO("Target folder for encodes (Select any file in it)",".",scriptpath,"",false,false)
	if tgt_path then tgt_path=tgt_path:gsub("(.*\\).-$","%1") end
		gui("target",tgt_path)
	end
	if P=="Secondary" then
		sec_path=ADO("Secondary subs","",scriptpath,"*.ass",false,true)
		gui("second",sec_path)
	end

	if P=="Save" then
		konf="NegaEncpath:"..res.NegaEncpath.."\nxpath:"..res.xpath.."\nVSPipepath:"..res.VSPipepath.."\nnvencpath:"..res.nvencpath.."\nqsvencpath:"..res.qsvencpath.."\nvceencpath:"..res.vceencpath.."\nvsfpath:"..res.vsf.."\nvsfmpath:"..res.vsfm.."\nffmpegpath:"..res.ffmpeg.."\nvtype:"..res.vtype.."\nfilter1:"..res.filter1.."\nfilter2:"..res.filter2.."\ntarg:"..res.targ.."\ntarget:"..res.target.."\nGPUs:"..res.GPUs.."\n"

		file=io.open(enconfig,"w")
		file:write(konf)
		file:close()
		for k,v in ipairs(GUI) do v.value=res[v.name] end
		ADD({{class="label",label="enc_sets saved to:\n"..enconfig}},{"OK"},{close='OK'})
	end
	P,res=ADD(GUI,
		{"Encode","NegaEnc","x264","VSPipe","NVEncC64","QSVEncC64","VCEEncC64","vsfilter","vsfiltermod","ffmpeg","Target","Secondary","Save","Cancel"},{ok='Encode',close='Cancel',save="Save"})
	until P=="Encode" or P=="Cancel"
	if P=="Cancel" then ak() end
	----------------------------------------------------------------------------------------------------------------------------------------
	
	videoname=res.vid
	encname=res.vid2
	ffmpegpath=res.ffmpeg
	if not dummy_video then
		target=vpath
	else
		target=scriptpath
	end
	vfull=vpath..videoname
	afull=apath..audioname
	vsm=0
	if res.targ=="Custom:" then target=res.target end
	if res.filter1=="none" then res.sec=false encname=encname:gsub("_hardsub","_encode") end
	if res.trim then encname=encname.."_"..res.sf.."-"..res.ef encname=encname:gsub("_encode","") end
	
	
	if not dummy_video then
		file=io.open(vfull)
		if file==nil then 
			t_error(vfull.."\nERROR: File does not exist (video source).",true)
		else 
			file:close()
		end 
	else 
		dummy_info={frame_rate,length,x_res,y_res,r,g,b,checkerboard}
	end
	time_stamp=os.date("%y%m%d%H%M%S", os.time())
	-- vapoursynth
	if res.filter1~="none" and res.first:match("%?script\\") then t_error("ERROR: It appears your subtitles are not saved.",true) end
	if res.filter1=="vsfiltermod" or (res.vtype==".mov(+alpha)" and res.GPUs=="ffmpeg(mov with alpha)") then 
		org_sub_name1=res.first
		root_path1=string.match(org_sub_name1,"[^\\]+")
		os.execute('mkdir '..root_path1.."\\aeg_encode_tmp")
		temp_sub_name1=root_path1.."\\aeg_encode_tmp\\sub1_"..time_stamp..".ass"
		os.rename(org_sub_name1,temp_sub_name1)
		text1="clip=core.vsfm.TextSubMod(clip,r"..quo(temp_sub_name1)..")\n"	vsm=2
	elseif res.filter1=="vsfilter" then --create temp subtitle file in case the original file name contains character vsfiltermod doesn't support.
		text1="clip=core.vsf.TextSub(clip,r"..quo(res.first)..")\n"	vsm=1
	else
		text1=""
	end
	if res.filter2=="vsfilter" then 
		filth2=res.vsf 
		ts2="clip=core.vsf.TextSub"
		temp_sub_name2=res.second
	else
		if res.sec then 
		filth2=res.vsfm
		org_sub_name2=res.second
		root_path2=string.match(org_sub_name2,"[^\\]+")
		if res.filter1=="vsfilter" then
			os.execute('mkdir '..root_path2.."\\aeg_encode_tmp")
		end
		temp_sub_name2=root_path2.."\\aeg_encode_tmp\\sub2_"..time_stamp..".ass"
		os.rename(org_sub_name2,temp_sub_name2)
		ts2="clip=core.vsfm.TextSubMod" 
		end
	end
	if res.sec then 
		text2=ts2.."(clip,r"..quo(temp_sub_name2)..")\n" 
	else 
		text2="" 
	end
	if res.trim then trim="clip=core.std.Trim(clip,"..res.sf..", "..res.ef-1 ..")" else trim="" end
	if dummy_video then comment="#"
		if length/frame_rate>dummy_duration and not res.trim and (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then 
			t_error("\nDummy video is too long, please set trim.",true) 
		else 
			dummy_vs_code=dummy_vs(dummy_info)
			color_change='clip=core.resize.Lanczos(clip,format=vs.YUV420P8, matrix_s="709")\n'
		end
	else comment="" dummy_vs_code="" color_change=""
	end
	vs="import vapoursynth as vs\ncore=vs.get_core()\n"..dummy_vs_code..comment.."clip=core.ffms2.Source(r"..quo(vfull)..")\n"..text1..text2..color_change..trim.."\nclip.set_output()"
	if scriptpath=="?script\\" then scriptpath=vpath end
	local vsfile=io.open(scriptpath.."hardsub.vpy","w")
	vsfile:write(vs)
	vsfile:close()
	source=quo(scriptpath.."hardsub.vpy")
	
	-- vsfilter checks
	if vsm==1 or vsm==3 then
	  file=io.open(res.vsf) if file==nil then t_error(res.vsf.."\nERROR: File does not exist (vsfilter).",true) else file:close() end
	end
	if vsm>1 then
	  file=io.open(res.vsfm) if file==nil then t_error(res.vsfm.."\nERROR: File does not exist (vsfiltermod).",true) else file:close() end
	end
	
	--avisynth for ffmpeg to generate mov
	if res.vtype==".mov(+alpha)" and res.GPUs=="ffmpeg(mov with alpha)" then  --only use avs for encoding transparent mov (ProRes)
		if res.audio then t_error("Audio will not be processed in this mod.",false) end
		if res.ffmpegpath=="" then t_error("Please check your ffmpeg.",true) end
		local xres, yres, ar, artype = aegisub.video_size()
		if dummy_video then
			framerate=frame_rate
		else
			framerate_gui={{x=0,y=0,class="label",label="Frame Rate"},
						   {x=0,y=1,class="dropdown",name="fps",value=30.0,items={"24000/1001",24.0,25.0,"30000/1001",30.0,50.0,"60000/1001",60.0}},
						   {x=1,y=1,class="label",label="24000/1001 = 23.976"},
						   {x=1,y=2,class="label",label="30000/1001 = 29.97"},
						   {x=1,y=3,class="label",label="60000/1001 = 59.94"}}
			fps_btn,fps_res=ADD(framerate_gui,{"OK","Cancel"})
			if fps_btn=="Cancel" then 
			    os.rename(temp_sub_name1,org_sub_name1)
				ak()
			end
			loadstring("framerate="..fps_res.fps)()
			if type(framerate)~="number" then
				t_error("Invalid value for frame rate.",true)
			end
			framerate=string.format("%0.3f",framerate)
		end
		encname=encname.."_"..framerate.."fps"
		if not res.trim then
			key_fr=aegisub.keyframes()
			if #key_fr>1 then
				GOP=key_fr[#key_fr]/(#key_fr-1)
				approx_len=GOP*(1+#key_fr)
			else
				approx_len=1000
			end
			framen_gui={{x=0,y=0,class="label",label="Frame Number to Encode"},
						   {x=0,y=1,class="intedit",name="framen",value=approx_len}}
			frn_btn,frn_res=ADD(framen_gui,{"OK","Cancel"})
			if frn_btn=="Cancel" then 
				os.rename(temp_sub_name1,org_sub_name1)
				ak()
			end
			enc_frame_n=frn_res.framen
			encname=encname.."_0-"..frn_res.framen
		else
			enc_frame_n=res.ef
		end
		if res.filter1=="vsfilter" then
			avs="LoadPlugin("..quo(res.vsf)..")\n"
			avs=avs.."MaskSub("..quo(temp_sub_name1)..string.format(",%d,%d,%.3f,%d",xres,yres,framerate,enc_frame_n)..").FlipVertical()\n" 			
		elseif res.filter1=="vsfiltermod" then
			avs="LoadPlugin("..quo(res.vsfm)..")\n"
			avs=avs.."MaskSubMod("..quo(temp_sub_name1)..string.format(",%d,%d,%.3f,%d",xres,yres,framerate,enc_frame_n)..").FlipVertical()\n"
		else
			avs=""
		end
		if res.sec then 
			t_error("Only the first subtitle will be encoded.\nPlease encode the second one manually.",false)
		end
		if res.trim then
			avs=avs..string.format("Trim(%d,0)\n",res.sf)
		end
		avsfile=io.open(root_path1.."\\aeg_encode_tmp\\sub_alpha.avs","w")
		avsfile:write(avs.."assumefps("..framerate..")\n")
		avsfile:close()
		rle_or_png={{x=0,y=0,width=2,class="label",label="Use qtrle encoder or png encoder"},
					{x=0,y=1,class="dropdown",name="mov_encoder",value="png",items={"qtrle","png"}},
					{x=0,y=3,width=2,height=2,class="label",label="qtrle - fast, lossless, small size. \nSupported by Premiere Pro before CC2018."},
					{x=0,y=5,width=2,height=2,class="label",label="png - slow, lossless, big size. \nGood compatibility."}}
		mov_btn,mov_enc_res=ADD(rle_or_png,{"OK","Cancel"})
		if mov_btn=="Cancel" then 
		    os.rename(temp_sub_name1,org_sub_name1)
			ak()
		end
		if mov_enc_res.mov_encoder=="qtrle" then
			bat_code=quo(ffmpegpath).." -i "..quo(root_path1.."\\aeg_encode_tmp\\sub_alpha.avs").." -an -c:v qtrle -r "..framerate.." -vsync cfr "..quo(encname)..".mov"
		else
			bat_code=quo(ffmpegpath).." -i "..quo(root_path1.."\\aeg_encode_tmp\\sub_alpha.avs").." -an -c:v png -r "..framerate.." -vsync cfr "..quo(encname)..".mov"
		end
		if res.delavs then bat_code=bat_code.."\ndel "..quo(root_path1.."\\aeg_encode_tmp\\sub_alpha.avs") end
	end

	--NeroAAC
	neroaac=res.neroaac
	nero_cmd=" -acodec aac "
	if neroaac then
		neropath=NegaEncLib.."\\neroAacEnc.exe"
		file=io.open(neropath)
		if not file then 
			t_error("Cannot locate neroAacEnc.exe, change to LC-AAC automatically.",false)
		else
			file:close()
			nero_cmd="-f wav - | "..quo(neropath).." -ignorelength -q "..neroquality.." -he -if - -of "
		end
	end
	
	-- ffmpeg mux
	if res.audio and audioname~="" then
		file=io.open(ffmpegpath)
		if not file then 
			t_error("Cannot locate ffmpeg.exe.",true)
		else
			file:close()
		end
		if res.trim then
			if res.sf>=res.ef then
				t_error("Cannot trim, please check.",true)
			end
			vstart=math.max(0,fr2ms(res.sf))
			vend=math.max(0,fr2ms(res.ef))
			timec1=time2string(vstart)
			timec2=time2string(vend)
			dur_time=(vend-vstart)/1000
			--mp4/mkv use m4a/mka
			if res.vtype==".mp4" then
				audiofile=target..encname..".m4a"
				audiosplit=quo(ffmpegpath).." -ss "..timec1.." -t "..dur_time.." -i "..quo(afull).." -vn "..nero_cmd..quo(audiofile)
				merge=audiosplit.."\n"..quo(ffmpegpath).." -i "..quo(target..encname..res.vtype).." -i "..quo(audiofile).." -c copy -map_chapters -1 "..quo(target..encname.."_muxed.mp4")
			else
				audiofile=target..encname..".m4a"
				audiosplit=quo(ffmpegpath).." -ss "..timec1.." -t "..dur_time.." -i "..quo(afull).." -vn "..nero_cmd..quo(audiofile)
				merge=audiosplit.."\n"..quo(ffmpegpath).." -i "..quo(target..encname..res.vtype).." -i "..quo(audiofile).." -c copy -map_chapters -1 "..quo(target..encname.."_muxed.mkv")
			end
		else
			if res.vtype==".mp4" then
				audiofile=target..encname..".m4a"
				audiosplit=quo(ffmpegpath).." -i "..quo(afull).." -vn "..nero_cmd..quo(audiofile)
				merge=audiosplit.."\n"..quo(ffmpegpath).." -i "..quo(target..encname..res.vtype).." -i "..quo(audiofile).." -c copy -map_chapters -1 "..quo(target..encname.."_muxed.mp4")
			else
				merge=quo(ffmpegpath).." -i "..quo(vfull).." -i "..quo(afull).." -c copy -map_chapters -1 "..quo(target..encname.."_muxed.mkv")
			end
		end
	else
		merge="\n"
	end
	
	if (res.GPUs=="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") or (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype==".mov(+alpha)") then
		t_error("ffmpeg works for mov.",true)
	end
	
	exe=res.GPUs
	enc_bat_set=ADP("?user").."\\enc_set_"..exe..".conf"
	file=io.open(enc_bat_set)
	if not file then first_time=true else file:close() end
	if (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then bat_code=encode_bat(exe,first_time) end
	if res.audio and (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then bat_code=bat_code.."\n"..merge end
	batch=scriptpath.."encode.bat"
	if not dummy_video and res.del and (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then
	bat_code=bat_code.."\ndel "..quo(target..videoname..".ffindex")
	end
	if res.audio and audioname~="" and res.delAV and (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then bat_code=bat_code.."\ndel "..quo(target..encname..res.vtype)
	if audiofile and audioname~="" then bat_code=bat_code.."\ndel "..quo(audiofile) audiofile=nil end
	end
	if res.delvs and (res.GPUs~="ffmpeg(mov with alpha)" and res.vtype~=".mov(+alpha)") then bat_code=bat_code.."\ndel "..quo(scriptpath.."hardsub.vpy") end
	if res.pause then bat_code=bat_code.."\npause" end
	if res.delbat then bat_code=bat_code.."\ndel "..quo(batch) end
	
	
	local xfile=io.open(batch,"w")
	xfile:write("chcp 65001\n"..bat_code)
	xfile:close()
	
	-- encode
	if res.trim then tr=res.sf..","..res.ef else tr="None" end
	info="Encode name: "..encname..res.vtype.."\nUse "..exe.." Encoder".."\nTrim: "..tr.."\n\nBatch file: "..batch.."\n\nYou can encode now or run this batch file later.\nIf encoding from Aegisub doesn't work,\njust run the batch file.\n\nEncode now?"
	P=ADD({{class="label",label=info}},{"Yes","No"},{ok='Yes',close='No'})
	if P=="Yes" then
	    aegisub.progress.title("Encoding...")
	    batch=batch:gsub("%=","^=")
	    os.execute(quo(batch))
	end
	if res.filter1=="vsfiltermod" or (res.vtype==".mov(+alpha)" and res.GPUs=="ffmpeg(mov with alpha)") then
		os.rename(temp_sub_name1,org_sub_name1)
		if not res.sec then
			os.execute("rd "..root_path1.."\\aeg_encode_tmp")
		end
	end
	if (res.filter2=="vsfiltermod" and res.sec) then
		os.rename(temp_sub_name2,org_sub_name2)
		os.execute("rd "..root_path2.."\\aeg_encode_tmp")
	end	
end

function encode_bat(exe,first_time,from_setting)

	if not exe then
		aegisub.cancel()
	end
	
	enc_bat_set=aegisub.decode_path("?user").."\\enc_set_"..exe..".conf"
	file=io.open(enc_bat_set)
	
	if file then
		enc_set=file:read("*all")
		file:close()
		x264crf=enc_set:match("crf:(.-)\n")
		x264preset=enc_set:match("x264preset:(.-)\n")
		x264_other_para=enc_set:match("x264_other_para:(.-)\n")
		NVpreset=enc_set:match("NVpreset:(.-)\n")
		NVbitrate=enc_set:match("NVbitrate:(.-)\n")
		NV_other_para=enc_set:match("NV_other_para:(.-)\n")
		QSVpreset=enc_set:match("QSVpreset:(.-)\n")
		QSVmode=enc_set:match("QSVmode:(.-)\n")
		QSVbitrate=enc_set:match("QSVbitrate:(.-)\n")
		QSVICQ=enc_set:match("QSVICQ:(.-)\n")
		QSV_other_para=enc_set:match("QSV_other_para:(.-)\n")
		VCEpreset=enc_set:match("VCEpreset:(.-)\n")
		VCEbitrate=enc_set:match("VCEbitrate:(.-)\n")
		VCE_other_para=enc_set:match("VCE_other_para:(.-)\n")
	else
		x264crf=23
		x264preset="medium"
		x264_other_para=" "
		NVpreset="default"
		NVbitrate=5000
		NV_other_para=" "
		QSVpreset="balanced"
		QSVmode="VBR"
		QSVbitrate=5000
		QSVICQ=26.0
		QSV_other_para=" "
		VCEpreset="balanced"
		VCEbitrate=5000
		VCE_other_para=" "
	end
	
	x264preset_tbl={"ultrafast","superfast","veryfast","faster","fast", "medium", "slow","slower","veryslow","placebo"}
	dia_x264={
	{x=0,y=0,class="label",label="x264 enc_set:"},
	{x=0,y=1,class="label",label="preset:"},
	{x=1,y=1,class="dropdown",name="x264preset",label="preset:",value=x264preset,items=x264preset_tbl},
	{x=0,y=2,class="label",label="crf:"},
	{x=1,y=2,class="floatedit",name="crf",value=x264crf or 23.0,min=1.0,max=51.0},
	{x=0,y=3,class="label",label="Custom parameters:"},
	{x=0,y=4,class="textbox",name="x264_other_para",text=x264_other_para or " ",height=5,width=5}
	}
	
	NVpreset_tbl={"performance","default", "quality"}
	dia_NV={
	{x=0,y=0,class="label",label="NVEnc enc_set:"},
	{x=0,y=1,class="label",label="preset:"},
	{x=1,y=1,class="dropdown",name="NVpreset",label="preset:",value=NVpreset,items=NVpreset_tbl},
	{x=0,y=2,class="label",label="bitrate(Kbps):"},
	{x=1,y=2,class="intedit",name="NVbitrate",value=NVbitrate or 5000,min=500,max=20000},
	{x=0,y=3,class="label",label="Custom parameters:"},
	{x=0,y=4,class="textbox",name="NV_other_para",text=NV_other_para or " ",height=5,width=5}
	}
	
	QSVpreset_tbl={"best", "higher", "high", "balanced","fast", "faster", "fastest"}
	dia_QSV={
	{x=0,y=0,class="label",label="QSVEnc enc_set:"},
	{x=0,y=1,class="label",label="preset:"},
	{x=1,y=1,class="dropdown",name="QSVpreset",label="preset:",value=QSVpreset,items=QSVpreset_tbl},
	{x=0,y=2,class="label",label="mode:"},
	{x=1,y=2,class="dropdown",name="QSVmode",label="preset:",value=QSVmode,items={"ICQ","VBR"}},
	{x=0,y=3,class="label",label="bitrate(Kbps):"},
	{x=1,y=3,class="intedit",name="QSVbitrate",value=QSVbitrate or 5000,min=500,max=20000},
	{x=0,y=4,class="label",label="ICQ:"},
	{x=1,y=4,class="intedit",name="QSVICQ",value=QSVICQ or 26,min=1,max=51},
	{x=0,y=5,class="label",label="Custom parameters:"},
	{x=0,y=6,class="textbox",name="QSV_other_para",text=QSV_other_para or " ",height=5,width=5}
	}
	
	VCEpreset_tbl={"fast","balanced","slow"}
	dia_VCE={
	{x=0,y=0,class="label",label="VCEEnc enc_set:"},
	{x=0,y=1,class="label",label="preset:"},
	{x=1,y=1,class="dropdown",name="VCEpreset",label="preset:",value=VCEpreset,items=VCEpreset_tbl},
	{x=0,y=2,class="label",label="bitrate(Kbps):"},
	{x=1,y=2,class="intedit",name="VCEbitrate",value=VCEbitrate or 5000,min=500,max=20000},
	{x=0,y=3,class="label",label="Custom parameters:"},
	{x=0,y=4,class="textbox",name="VCE_other_para",text=VCE_other_para or " ",height=5,width=5}
	}
	
	if exe=="VSPipe+x264" and first_time then
		button,result=aegisub.dialog.display(dia_x264,{"OK","Save","Cancel"})
		if (button=="Save" or button=="OK") then 
			text="crf:"..result.crf.."\nx264preset:"..result.x264preset.."\nx264_other_para:"..result.x264_other_para.."\n"
			file=io.open(enc_bat_set,"w")
			file:write(text)
			file:close()
			aegisub.dialog.display({{class="label",label="x264 setting was saved to:\n"..enc_bat_set}},{"OK"},{close='OK'})
			if not from_setting then
			if res.VSPipepath=="" or res.xpath=="" then t_error("Please check your VSPipe and x264.",true) end
			bat_code=quo(VSPipepath).." "..quo(scriptpath.."hardsub.vpy").." - --y4m | "..quo(xpath).." --crf "..result.crf.." --preset "..result.x264preset.." "..result.x264_other_para.." --demuxer y4m -o "..quo(target..encname..res.vtype).." -"
			end
		else
			aegisub.cancel()
		end
	elseif exe=="VSPipe+x264" and not first_time then
		if res.VSPipepath=="" or res.xpath=="" then t_error("Please check your VSPipe and x264.",true) end
		bat_code=quo(VSPipepath).." "..quo(scriptpath.."hardsub.vpy").." - --y4m | "..quo(xpath).." --crf "..x264crf.." --preset "..x264preset.." "..x264_other_para.." --demuxer y4m -o "..quo(target..encname..res.vtype).." -"
	end
	
	if exe=="NVEnc" and first_time then
		button,result=aegisub.dialog.display(dia_NV,{"OK","Save","Cancel"})
		if (button=="Save" or  button=="OK") then 
			text="NVpreset:"..result.NVpreset.."\nNVbitrate:"..result.NVbitrate.."\nNV_other_para:"..result.NV_other_para.."\n"
			file=io.open(enc_bat_set,"w")
			file:write(text)
			file:close()
			aegisub.dialog.display({{class="label",label="NVEnc setting was saved to:\n"..enc_bat_set}},{"OK"},{close='OK'})
			if not from_setting then
			if res.nvencpath=="" then t_error("Please check your NVEnc.",true) end
			bat_code=quo(res.nvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbrhq "..result.NVbitrate.." --preset "..result.NVpreset.." "..result.NV_other_para.." -o "..quo(target..encname..res.vtype)
			end
		else
			aegisub.cancel()
		end
	elseif exe=="NVEnc" and not first_time then
		if nvencpath=="" then t_error("Please check your NVEnc.",true) end
		bat_code=quo(nvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbrhq "..NVbitrate.." --preset "..NVpreset.." "..result.NV_other_para.." -o "..quo(target..encname..res.vtype)
	end
		
	if exe=="QSVEnc" and first_time then
		button,result=aegisub.dialog.display(dia_QSV,{"OK","Save","Cancel"})
		if (button=="Save" or  button=="OK") then 
			text="QSVpreset:"..result.QSVpreset.."\nQSVbitrate:"..result.QSVbitrate.."\nQSVmode:"..result.QSVmode.."\nQSVICQ:"..result.QSVICQ.."\nQSV_other_para:"..result.QSV_other_para.."\n"
			file=io.open(enc_bat_set,"w")
			file:write(text)
			file:close()
			aegisub.dialog.display({{class="label",label="QSVEnc setting was saved to:\n"..enc_bat_set}},{"OK"},{close='OK'})
			if not from_setting then
			if res.qsvencpath=="" then t_error("Please check your QSVEnc.",true) end
			if result.QSVmode=="VBR" then
				bat_code=quo(res.qsvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbr "..result.QSVbitrate.." --quality "..result.QSVpreset.." "..result.QSV_other_para.." -o "..quo(target..encname..res.vtype)
			elseif result.QSVmode=="ICQ" then
				bat_code=quo(res.qsvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --icq "..result.QSVICQ.." --quality "..result.QSVpreset.." "..result.QSV_other_para.." -o "..quo(target..encname..res.vtype)
			end
			end
		else
			aegisub.cancel()
		end
	elseif exe=="QSVEnc" and not first_time then
		if qsvencpath=="" then t_error("Please check your QSVEnc.",true) end
		if QSVmode=="VBR" then
			bat_code=quo(qsvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbr "..QSVbitrate.." --quality "..QSVpreset.." "..result.QSV_other_para.." -o "..quo(target..encname..res.vtype)
		elseif QSVmode=="ICQ" then
			bat_code=quo(qsvencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --icq "..QSVICQ.." --quality "..QSVpreset.." "..result.QSV_other_para.." -o "..quo(target..encname..res.vtype)
		else 
			aegisub.cancel()
		end
	end
	
	if exe=="VCEEnc" and first_time then
		button,result=aegisub.dialog.display(dia_VCE,{"OK","Save","Cancel"})
		if (button=="Save" or  button=="OK") then 
			text="VCEpreset:"..result.VCEpreset.."\nVCEbitrate:"..result.VCEbitrate.."\nVCE_other_para:"..result.VCE_other_para.."\n"
			file=io.open(enc_bat_set,"w")
			file:write(text)
			file:close()
			aegisub.dialog.display({{class="label",label="VCEEnc setting was saved to:\n"..enc_bat_set}},{"OK"},{close='OK'})
			if not from_setting then
			if vceencpath=="" then t_error("Please check your VCEEnc.",true) end
			bat_code=quo(vceencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbr "..result.VCEbitrate.." --quality "..result.VCEpreset.." "..result.VCE_other_para.." -o "..quo(target..encname..res.vtype)
			end
		else
			aegisub.cancel()
		end
	elseif exe=="VCEEnc" and not first_time then
		if vceencpath=="" then t_error("Please check your VCEEnc.",true) end
		bat_code=quo(vceencpath).." -i "..quo(scriptpath.."hardsub.vpy").." --vpy --vbr "..VCEbitrate.." --quality "..VCEpreset.." "..result.VCE_other_para.." -o "..quo(target..encname..res.vtype)
	end
	return bat_code
end

function time2string(num)
	sec=num/1000
    hours=string.format("%02.f", math.floor(sec/3600))
    mins=string.format("%02.f", math.floor(sec/60-(hours*60)))
    secs=string.format("%02.f", math.floor(sec-hours*3600-mins*60))
	ms=string.format("%02.f", math.floor(num-hours*3600000-mins*60000-secs*1000))
    return hours..":"..mins..":"..secs.."."..ms
end


function choose_exe()
	btn, result = aegisub.dialog.display({{class="label", label="Choose one to configure", x=1, y=0,height=2,width=2}},{"QSVEnc", "NVEnc","VCEEnc","x264"})
	if btn=="x264" then
		encode_bat("VSPipe+x264",true,true)
	else
		encode_bat(btn,true,true)
	end
end

function gui(a,b)
  for k,v in ipairs(GUI) do
	if b==nil then b="" end
	if v.name==a then v.value=b else v.value=res[v.name] end
  end
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function quo(x)  x="\""..x.."\"" return x end

function t_error(message,cancel)
ADD({{class="label",label=message}},{"OK"},{close='OK'})
if cancel then ak() end
end

local function RGB2HSL(R, G, B)
	local r, g, b = R/255, G/255, B/255
	local h, s, l
	local minrgb, maxrgb = math.min(r, math.min(g, b)), math.max(r, math.max(g, b))
	l = (minrgb + maxrgb) / 2
	if minrgb == maxrgb then
		h, s = 0, 0
	else
		if l < 0.5 then
			s = (maxrgb - minrgb) / (maxrgb + minrgb)
		else
			s = (maxrgb - minrgb) / (2 - maxrgb - minrgb)
		end
		if r == maxrgb then
			h = (g - b) / (maxrgb - minrgb) + 0
		elseif g == maxrgb then
			h = (b - r) / (maxrgb - minrgb) + 2
		else
			h = (r - g) / (maxrgb - minrgb) + 4
		end
	end
	if h < 0 then h = h + 6 end
	if h >= 6 then h = h - 6 end
	return h*255/6, s*255, l*255
end

function dummy_vs(info_tbl)
	checkerboard=info_tbl[#info_tbl]
	r,g,b=info_tbl[5],info_tbl[6],info_tbl[7]
	if checkerboard=="c" then
		vs_code=clip_vs(info_tbl)
	else
		vs_code=string.format('clip=core.std.BlankClip(length=%d,width=%d,height=%d,format=vs.RGB24,fpsnum=%d,fpsden=10**6, color=[%d,%d,%d])\n',info_tbl[2],info_tbl[3],info_tbl[4],info_tbl[1]*10^6,r,g,b)
	end
	return vs_code
end

function clip_vs(info_tbl)
	r,g,b=info_tbl[5],info_tbl[6],info_tbl[7]
	color_str=string.format('%02x',r)..string.format('%02x',g)..string.format('%02x',b)
	h,s,l=RGB2HSL(r, g, b)
	if l<=231 then
		l1=l+24
	else
		l1=l-24
	end
	r1,g1,b1=HSL_to_RGB(h/255*360,s/255,l1/255)
	vs_code="import math\n"
	vs_code=vs_code..string.format('a=core.std.BlankClip(format=vs.RGB24,width=8,height=8,fpsnum=%d,fpsden=10**6,length=1,color=[%d,%d,%d])\n',info_tbl[1]*10^6,r,g,b)
	vs_code=vs_code..string.format('b=core.std.BlankClip(format=vs.RGB24,width=8,height=8,fpsnum=%d,fpsden=10**6,length=1,color=[%d,%d,%d])\n',info_tbl[1]*10^6,r1,g1,b1)
	vs_code=vs_code.."clip=core.std.StackVertical([core.std.StackHorizontal([a,b]),core.std.StackHorizontal([b,a])])\n"
	vs_code=vs_code..string.format("for i in range(math.ceil(math.log(%d/16,2))):\n clip=core.std.StackHorizontal([clip,clip])\nfor j in range(math.ceil(math.log(%d/16,2))):\n clip=core.std.StackVertical([clip,clip]) \nclip=core.std.CropAbs(clip,%d,%d,0, 0)\nclip=core.std.Loop(clip,%d)\n",info_tbl[3],info_tbl[4],info_tbl[3],info_tbl[4],info_tbl[2])
	return vs_code
end

aegisub.register_macro(script_name.."/Encode",script_description,encode_vs)
aegisub.register_macro(script_name.."/Setting",script_description,choose_exe)
