script_name="Text to QRCode"
script_description="Convert Text to QRCode ASSDrawing"
script_author="domo"
script_version="1.0"

function text_to_qrcode(subtitles, selected_lines, active_line)
	local qrencode = require"qrencode"
	local min_size=100
	local size,color=setting(min_size)
	local alpha_str,color_str=HTML2ASS(color)
	local width=4
	local code_shape=""
	for z, k in ipairs(selected_lines) do
		code_shape=""
		l=subtitles[k]
		text_stripped=string.gsub(l.text,"%{.-%}","")
		if string.len(text_stripped)>900 then
			aegisub.debug.out("Text is too long.\n")
			aegisub.cancel()
		end
		ok, tab_or_message=qrencode.qrcode(text_stripped)
		if #tab_or_message*width/2>size or min_size>size then
			aegisub.debug.out("Size for text "..string.format("['%s'] is too small, and is adjusted automatically.\n",text_stripped))
		end
		for i=1,#tab_or_message do
			for j=1,#tab_or_message do
				if tab_or_message[i][j]>0 then
					code_shape=code_shape..string.format("m %d %d l %d %d l %d %d l %d %d ",(i-1)*width,(j-1)*width,(i)*width,(j-1)*width,(i)*width,(j)*width,(i-1)*width,(j)*width)
				end
			end
		end
		org_size=#tab_or_message*width
		size=math.max(org_size/2,size)
		size_ratio=math.floor(size/org_size*100)
		l.text=string.format("{\\fscx%d\\fscy%d\\1c%s\\1a%s",size_ratio,size_ratio,color_str,alpha_str).."\\bord0\\shad0\\p1}"..code_shape
		subtitles[0]=l
	end
end

function HTML2ASS(s)
    local ass_s = ""
	--  1 is "#"
	r = string.sub(s,2,3)
	g = string.sub(s,4,5)
	b = string.sub(s,6,7)
	a =  string.sub(s,8,9)
	ass_a = string.format("&H%s&",a)
	ass_c = string.format("&H%s%s%s&",b,g,r)
    return ass_a,ass_c
end

function setting(min_size)
	dialog_config = {
	{x=1,y=0,class="label",label="QRCode Size"},
	{x=1,y=1,class="intedit",name="Size",min=min_size/2,max=800,value=min_size},
	{x=1,y=2,class="label",label="QRCode Color"},
	{x=1,y=3,class="coloralpha",name="Color",value="#00000000"},
	}
	
	button,config =_G.aegisub.dialog.display(dialog_config,{"OK","Cancel"})
	if button=="Cancel" then
		aegisub.cancel()
	end
	size=config.Size
	color=config.Color
	
	return size,color
end

aegisub.register_macro(script_name,script_description,text_to_qrcode)
