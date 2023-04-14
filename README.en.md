# aegisub_scripts

## autoload  
### enc-hsub-VS.lua
Encode use vapoursynth+x264/NVEnc/QSVEnc/VCEEnc.  
Encode subtitle to mov file with alpha channel, ffmpeg and Avisynth(tested on Avisynth+ r2772) required.

## Add k Tags.lua  
Generate K by :  
1.Average  
2.k1     --Actually you can change 1 to any fixed number you want.  
3.Percentage

## Combine Overlaps.lua  
Combine subtitle lines whose times are overlapped regardless of tags.  

## Space K Checker.lua
Check K tags for selected lines, following the rules below:  
1.In karaskel, a syl whose text contains a full-width blank will affect the sizing information calculated.
Under such condition, the full-width blank should be given a separated K tag.  
2.Normally, the last syl of a line should not be blank.  

## Time Scaler.lua  
case 1. Keep ass file usability while converting NTSC 24p to PAL 25p (speed up).  
case 2. You can use this on a song lyric file if only BPM changed.  

## HDRifySub.lua    
Change color based on PQ(ST2084) curve to adapt subtitle which is under SDR, to HDR videos.   

## delete_fx.lua  
A very simple script to remove fx lines after sorting by effect.   
  
## template&fx checker.lua  
A set of basic functions for checking/printing mistakes in template lines and fx lines.  
Code blocks and most parameters of tags are ignored.  


## Text_Stat(\_chi).lua    
Get some statistics from your ass script, like words number and line duration etc.  
And you can save the information to a text file.  
You can also treat this as an example of learning _lua pattern_, _unicode(UTF-8)_, _Aegisub Dialog API_, and of course, _file operation_.  
File with _chi_ suffix is its Chinese version.  

## text to qrcode.lua    
Requirement:https://github.com/speedata/luaqrcode/blob/master/qrencode.lua  
Convert line text to QRCode.  
You can also define the size, transparency and color of the QRCode now.  

## MediaInfo.lua    

Requirement:https://github.com/kawaCat/MediaInfo-For-LuaJIT
and mediainfo.dll(32bit) [binary](https://mediaarea.net/download/binary/libmediainfo0/20.03/MediaInfo_DLL_20.03_Windows_i386_WithoutInstaller.7z).  
Get media information in Aegisub.  
Solve unicode filename support problem by C functions on Windows.  
It's just an example.  

## bcc_importer.lua  
Requirement:https://github.com/rxi/json.lua  
Convert Bilibili's CC subtitle to ASS format.
