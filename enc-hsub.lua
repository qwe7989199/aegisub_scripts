--[[	Script for encoding / hardsubbing

	Options:
	
	- encode whole video / a clip
	- hardsub 1 or 2 subtitle files or only encode
	- use vsfilter or vsfiltermod for each subtitle track
	- encode to mp4 or mkv
	- mux with audio
	
	
	Requirements:
	
	- x264.exe
	- vsfilter.dll / vsfiltermod.dll for hardsubbing
	- avisynth (not required when encoding for mocha)
	
	
	'Encode clip for mocha' does automatically the following (meaning you don't have to do those manually):
	
	- disables 10bit
	- enables trimming
	- disables subtitles
	- sets target to .mp4
	- disables avisynth use
--]]

script_name="Encode - Hardsub"
script_description="Encode a clip with or without hardsubs"
script_author="unanimated"
script_version="1.2"
script_namespace="ua.EncodeHardsub"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="1.2.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

function encode(subs,sel)
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ADO=aegisub.dialog.open
	ak=aegisub.cancel
	enconfig=ADP("?user").."\\encode_hardsub.conf"
	defsett="--crf 23 --ref 10 --bframes 10 --merange 32 --me umh --subme 10 --trellis 2 --direct auto --b-adapt 2 --partitions all"
	defmsett="--profile baseline --level 1.0 --crf 16 --fps 24000/1001"
	scriptpath=ADP("?script").."\\"
	scriptname=aegisub.file_name()
	vpath=ADP("?video").."\\"
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	sframe=999999
	eframe=0
	videoname=nil

    file=io.open(enconfig)
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	modpath=konf:match("modpath:(.-)\n")
	xpath=konf:match("xpath:(.-)\n")
	ffmspath=konf:match("ffmspath:(.-)\n")
	sett=konf:match("settings:(.-)\n")
	vsfpath=konf:match("vsfpath:(.-)\n")
	vsfmpath=konf:match("vsfmpath:(.-)\n")
	mmgpath=konf:match("mmgpath:(.-)\n") or ""
	vtype=konf:match("vtype:(.-)\n")
	vsf1=konf:match("filter1:(.-)\n")
	vsf2=konf:match("filter2:(.-)\n")
	targ=konf:match("targ:(.-)\n")
	target=konf:match("target:(.-)\n")
	msett=konf:match("mocha:(.-)\n")
	settlist=konf:match("(settings1:.*\n)$") or ""
    else
	xpath=""
	ffmspath=""
	vsfpath=""
	vsfmpath=""
	mmgpath=""
	vtype=".mkv"
	vsf1="vsfilter"
	vsf2="vsfilter"
	sett=defsett
	msett=defmsett
	settlist=""
	targ="Same as source"
	target=""
    end

    for i=1,#subs do
	if subs[i].class=="info" then
	  if subs[i].key=="Video File" then videoname=subs[i].value break end
	end
	if subs[i].class~="info" then break end
    end
    if videoname==nil then videoname=aegisub.project_properties().video_file:gsub("^.*\\","") end
    if videoname==nil or videoname=="" or aegisub.frame_from_ms(10)==nil then t_error("No video detected.",1) end
    vid2=videoname:gsub("%.[^%.]+","") :gsub("_?premux","") :gsub("_?workraw","")
    vid2=vid2.."_hardsub"
    
    for z,i in ipairs(sel) do
	line=subs[i]
        start=line.start_time
	endt=line.end_time
	sfr=ms2fr(start)
	efr=ms2fr(endt)
	if sfr<sframe then sframe=sfr end
	if efr>eframe then eframe=efr end
    end
    
    GUI={
	{x=0,y=0,class="label",label="avs4x26x.exe:"},
	{x=1,y=0,width=6,class="edit",name="modpath",value=modpath or ""},
	{x=0,y=1,class="label",label="x264.exe:"},
	{x=1,y=1,width=6,class="edit",name="xpath",value=xpath or ""},
	{x=7,y=1,class="label",label=" ffms2:"},
	{x=8,y=1,width=2,class="edit",name="ffmspath",value=ffmspath or ""},
	
	{x=0,y=2,class="label",label="vsfilter.dll:"},
	{x=1,y=2,width=6,class="edit",name="vsf",value=vsfpath or ""},
	{x=7,y=2,class="label",label=" vsfiltermod.dll:"},
	{x=8,y=2,width=2,class="edit",name="vsfm",value=vsfmpath or "",hint="only needed if you're using it"},
	
	{x=0,y=3,class="label",label="Source video:"},
	{x=1,y=3,width=6,class="edit",name="vid",value=videoname},
	
	{x=7,y=3,class="label",label=" mkvmerge.exe:"},
	{x=8,y=3,width=2,class="edit",name="mmg",value=mmgpath or "",hint="only needed if you're muxing audio"},
	
	{x=0,y=4,class="label",label="Target folder:"},
	{x=1,y=4,width=2,class="dropdown",name="targ",value=targ,items={"Same as source","Custom:"}},
	{x=3,y=4,width=7,class="edit",name="target",value=target},
	
	{x=0,y=5,class="label",label="Encode name:"},
	{x=1,y=5,width=2,class="dropdown",name="vtype",value=vtype,items={".mkv",".mp4"}},
	{x=3,y=5,width=7,class="edit",name="vid2",value=vid2},
	
	{x=0,y=6,class="label",label="Primary subs:"},
	{x=1,y=6,width=2,class="dropdown",name="filter1",value=vsf1,items={"none","vsfilter","vsfiltermod"}},
	{x=3,y=6,width=7,class="edit",name="first",value=scriptpath..scriptname},
	
	{x=0,y=7,class="checkbox",name="sec",label="Secondary:"},
	{x=1,y=7,width=2,class="dropdown",name="filter2",value=vsf2,items={"vsfilter","vsfiltermod"}},
	{x=3,y=7,width=7,class="edit",name="second",value=secondary or ""},
	
	{x=0,y=8,class="label",label="Encoder settings:"},
	{x=1,y=8,width=9,class="edit",name="encset",value=sett},
	
	{x=0,y=9,class="label",label="Settings 4 mocha:"},
	{x=1,y=9,width=9,class="edit",name="encmocha",value=msett or defmsett},
	
	{x=0,y=10,class="checkbox",name="trim",label="Trim from:",hint="Encodes only current selection"},
	{x=1,y=10,width=3,class="intedit",name="sf",value=sframe},
	{x=4,y=10,class="label",label="to: "},
	{x=5,y=10,width=2,class="intedit",name="ef",value=eframe},
	{x=7,y=10,width=2,class="label",label=" If checked, frames are added to Encode name  "},
	{x=9,y=10,width=1,class="checkbox",name="audio",label="Mux with audio",hint="whether you're trimming or not"},
	
	{x=0,y=11,width=2,class="checkbox",name="mocha",label="Encode clip for mocha    "},
	{x=5,y=11,width=1,class="checkbox",name="delbat",label="Delete batch file",value=true},
	{x=6,y=11,width=2,class="checkbox",name="delavs",label="Delete avisynth script",value=true},
	{x=8,y=11,width=1,class="checkbox",name="delAV",label="Delete A/V after muxing",value=true,hint="Delete audio/video files only needed for muxing"},
	{x=9,y=11,width=1,class="checkbox",name="pause",label="Keep cmd window open   ",value=true},
    }
    repeat
    if P=="Default enc. settings" then
	gui("encset",defsett)
    end
    if P=="avs4x26x" then
	mod_path=ADO("avs4x26x","",scriptpath,"*.exe",false,true)
	gui("modpath",mod_path)
    end
    if P=="x264" then
	x264_path=ADO("x264","",scriptpath,"*.exe",false,true)
	gui("xpath",x264_path)
    end
    if P=="ffms2" then
	ffms2_path=ADO("ffms2","",scriptpath,"*.dll",false,true)
	gui("ffmspath",ffms2_path)
    end
    if P=="vsfilter" then
	vsf_path=ADO("vsfilter","",scriptpath,"*.dll",false,true)
	gui("vsf",vsf_path)
    end
    if P=="vsfiltermod" then
	vsfm_path=ADO("vsfiltermod","",scriptpath,"*.dll",false,true)
	gui("vsfm",vsfm_path)
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
    if P=="Enc. set." then
	enclist={defsett}
	for set in settlist:gmatch("settings%d:(.-)\n") do
	  table.insert(enclist,set)
	end
	encodings={{class="dropdown",name="enko",items=enclist,value=defsett}}
	press,rez=ADD(encodings,{"OK","Cancel"},{ok='OK',close='Cancel'})
	for k,v in ipairs(GUI) do
	    if v.name=="encset" then v.value=rez.enko else v.value=res[v.name] end
	end
    end
    if P=="Save" then
	konf="modpath:"..res.modpath.."\nxpath:"..res.xpath.."\nffmspath:"..res.ffmspath.."\nvsfpath:"..res.vsf.."\nvsfmpath:"..res.vsfm.."\nmmgpath:"..res.mmg.."\nvtype:"..res.vtype.."\nfilter1:"..res.filter1.."\nfilter2:"..res.filter2.."\ntarg:"..res.targ.."\ntarget:"..res.target.."\nmocha:"..res.encmocha.."\nsettings:"..res.encset.."\n"
	if res.encset~=sett then
	    settlist=settlist:gsub("settings9:.-\n","")
	    set1=esc(sett)
	    if not settlist:match(set1) then
	      for i=8,1,-1 do
		settlist=settlist:gsub("(settings)"..i,"%1"..i+1)
	      end
	      settlist="settings1:"..sett.."\n"..settlist
	    end
	end
	konf=konf..settlist
	file=io.open(enconfig,"w")
	file:write(konf)
	file:close()
	for k,v in ipairs(GUI) do v.value=res[v.name] end
	ADD({{class="label",label="Settings saved to:\n"..enconfig}},{"OK"},{close='OK'})
    end
    P,res=ADD(GUI,
    {"Encode","avs4x26x","x264","ffms2","vsfilter","vsfiltermod","Target","Secondary","Enc. set.","Save","Cancel"},{ok='Encode',close='Cancel'})
    until P=="Encode" or P=="Cancel"
    if P=="Cancel" then ak() end
    ----------------------------------------------------------------------------------------------------------------------------------------
    
    videoname=res.vid
    encname=res.vid2
    mkvmerge=res.mmg
    target=vpath
    vfull=vpath..videoname
    vsm=0
    if res.targ=="Custom:" then target=res.target end
    
    -- mocha
    if res.mocha then
	res.vtype=".mp4"
	res.tenbit=false
	res.trim=true
	res.encset=res.encmocha.." --seek "..res.sf.." --frames "..res.ef-res.sf
	res.delavs=false
	encname=encname:gsub("_hardsub","")
	source=quo(vfull)
    end
    
    if res.filter1=="none" then res.sec=false encname=encname:gsub("_hardsub","_encode") end
    if res.trim then encname=encname.."_"..res.sf.."-"..res.ef encname=encname:gsub("_encode","") end
    if res.tenbit then xpath=res.ffmspath else xpath=res.xpath end
    
    file=io.open(xpath)   if file==nil then t_error(xpath.."\nERROR: File does not exist (x264).",true) else file:close() end
    file=io.open(vfull)   if file==nil then t_error(vfull.."\nERROR: File does not exist (video source).",true) else file:close() end
    
    -- avisynth
    if res.mocha==false then
	if res.filter1~="none" and res.first:match("%?script\\") then t_error("ERROR: It appears your subtitles are not saved.",true) end
	if res.filter1=="vsfilter" then
	    plug1="loadplugin(\""..res.vsf.."\")\n"	    text1="textsub("..quo(res.first)..")\n"	vsm=1
	elseif res.filter1=="vsfiltermod" then
	    plug1="loadplugin(\""..res.vsfm.."\")\n"	    text1="textsubmod("..quo(res.first)..")\n"	vsm=2
	else
	    plug1="" text1=""
	end
	plug0 = 'loadplugin("'..ffmspath..'")\n'
	if res.filter2=="vsfilter" then filth2=res.vsf ts2="textsub" else filth2=res.vsfm ts2="textsubmod" end
	if res.sec and res.filter1~=res.filter2 then plug2="loadplugin(\""..filth2.."\")\n" vsm=3 else plug2="" end
	if res.sec then text2=ts2.."("..quo(res.second)..")\n" else text2="" end
	if res.trim then trim="Trim("..res.sf..", "..res.ef-1 ..")" else trim="" end
	
	avs=plug0..plug1..plug2.."ffvideosource("..quo(vfull)..")\n"..text1..text2..trim
	
	-- vsfilter checks
	if vsm==1 or vsm==3 then
	  file=io.open(res.vsf) if file==nil then t_error(res.vsf.."\nERROR: File does not exist (vsfilter).",true) else file:close() end
	end
	if vsm>1 then
	  file=io.open(res.vsfm) if file==nil then t_error(res.vsfm.."\nERROR: File does not exist (vsfiltermod).",true) else file:close() end
	end
	
	if scriptpath=="?script\\" then scriptpath=vpath end
	local avsfile=io.open(scriptpath.."hardsub.avs","w")
	avsfile:write(avs)
	avsfile:close()
	
	source=quo(scriptpath.."hardsub.avs")
    end
    
    -- mkvmerge audio
    if res.audio then
	if res.trim then
	  vstart=fr2ms(res.sf)
	  vend=fr2ms(res.ef)
	  timec1=time2string(vstart)
	  timec2=time2string(vend)
	  audiofile=target..encname..".mka"
	  audiosplit=quo(mkvmerge).." -o "..quo(audiofile).." -D -S -M --split parts:"..timec1.."-"..timec2.." "..quo(vfull)
	  merge=audiosplit.."\n"..quo(mkvmerge).." -o "..quo(target..encname.."_muxed.mkv").." "..quo(target..encname..res.vtype).." "..quo(audiofile)
	else
	  merge=quo(mkvmerge).." -o "..quo(target..encname.."_muxed.mkv").." "..quo(target..encname..res.vtype).." -D -S -M "..quo(vfull)
	end
    end
    
    -- batch script
    encode=quo(modpath).." --x264-binary "..quo(xpath).." "..res.encset.." -o "..quo(target..encname..res.vtype).." "..source
    if res.audio then encode=encode.."\n"..merge end
    batch=scriptpath.."encode.bat"
    if res.pause then encode=encode.."\npause" end
    encode=encode.."\ndel "..quo(target..videoname..".ffindex")
    if res.audio and res.delAV then encode=encode.."\ndel "..quo(target..encname..res.vtype)
	if audiofile then encode=encode.."\ndel "..quo(audiofile) audiofile=nil end
    end
    if res.delavs then encode=encode.."\ndel "..quo(scriptpath.."hardsub.avs") end
    if res.delbat then encode=encode.."\ndel "..quo(batch) end
    
    local xfile=io.open(batch,"w")
    xfile:write(encode)
    xfile:close()
    
    -- encode
    if res.tenbit then ten="Yes" else ten="No" end
    if res.trim then tr=res.sf..","..res.ef else tr="None" end
    info="Encode name: "..encname..res.vtype.."\n10-bit: "..ten.."\nTrim: "..tr.."\n\nBatch file: "..batch.."\n\nYou can encode now or run this batch file later.\nIf encoding from Aegisub doesn't work,\njust run the batch file.\n\nEncode now?"
    P=ADD({{class="label",label=info}},{"Yes","No"},{ok='Yes',close='No'})
    if P=="Yes" then
	aegisub.progress.title("Encoding...")
	batch=batch:gsub("%=","^=")
	os.execute(quo(batch))
    end
end

function time2string(num)
	timecode=math.floor(num/1000)
	tc0=math.floor(timecode/3600)
	tc1=math.floor(timecode/60)
	tc2=timecode%60
	numstr="00"..num
	tc3=numstr:match("(%d%d)%d$")
	if tc1==60 then tc1=0 tc0=tc0+1 end
	if tc2==60 then tc2=0 tc1=tc1+1 end
	if tc1<10 then tc1="0"..tc1 end
	if tc2<10 then tc2="0"..tc2 end
	tc0=tostring(tc0)
	tc1=tostring(tc1)
	tc2=tostring(tc2)
	timestring=tc0..":"..tc1..":"..tc2.."."..tc3
	return timestring
end


function gui(a,b)
  for k,v in ipairs(GUI) do
    if b==nil then b="" end
    if v.name==a then v.value=b else v.value=res[v.name] end
  end
end

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function logg(m) m=m or "nil" aegisub.log("\n "..m) end
function quo(x) x="\""..x.."\"" return x end

function t_error(message,cancel)
ADD({{class="label",label=message}},{"OK"},{close='OK'})
if cancel then ak() end
end

if haveDepCtrl then depRec:registerMacro(encode) else aegisub.register_macro(script_name,script_description,encode) end