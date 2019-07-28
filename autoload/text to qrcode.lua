script_name="Text to QRCode"
script_description="Convert Text to QRCode ASSDrawing"
script_author="domo"
script_version="1.0"


function text_to_qrcode(subtitles, selected_lines, active_line)
	local qrencode = require"qrencode"
	width=4
	code_shape=""
	for z, k in ipairs(selected_lines) do
		l=subtitles[k]
		text_stripped=string.gsub(l.text,"%{.-%}","")
		if string.len(text_stripped)>=900 then
			aegisub.debug.out("Text is too long.")
			aegisub.cancel()
		end
		ok, tab_or_message = qrencode.qrcode(text_stripped)
		for i=1,#tab_or_message do
			for j=1,#tab_or_message do
				if tab_or_message[i][j]>0 then
					code_shape=code_shape..string.format("m %d %d l %d %d l %d %d l %d %d ",(i-1)*width,(j-1)*width,(i)*width,(j-1)*width,(i)*width,(j)*width,(i-1)*width,(j)*width)
				end
			end
		end
		l.text="{\\p1}"..code_shape
		subtitles[0]=l
	end
end
aegisub.register_macro(script_name,script_description,text_to_qrcode)
