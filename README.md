# aegisub_scripts  

[English](./README.en.md) 

## autoload  
### enc-hsub-VS.lua
使用 vapoursynth+x264/NVEnc/QSVEnc/VCEEnc 中的一种进行视频压制(硬字幕)。  
或者将字幕压制为透明通道的mov文件(或双mp4文件),依赖于ffmpeg和Avisynth(测试于Avisynth+ r2772,64bit为必须)。

## Add k Tags.lua  
按以下方式中的一种生成K :  
1.Average     --平均K  
2.k1          --固定K1，你可以把1替换成任何固定值  
3.Percentage  --百分比K  

## Combine Overlaps.lua  
将时间重叠的行合并，无视特效标签。  

## Space K Checker.lua
检查行内的K标签，并指明出错位置，判定规则如下:  
1.根据karaskel的算法，如果一个音节的文本中包含全角空格，那么这个全角空格会影响位置计算。这种情况下，全角空格应该被单独赋予K标签。  
2.正常情况下，行末尾的音节不应该是空格。  

## Time Scaler.lua  
针对同一首歌曲，仅BPM变化的情况，进行时间轴的缩放。  

## delete_fx.lua  
利用范围删除函数快速删除掉fx行(针对行数多时卡拉OK模板执行器的删法过于缓慢问题)，建议先按特效排序后再使用本脚本。   
  
## template&fx checker.lua  
一些简单的检查函数，检查并输出模板行和fx行中的一些显著错误/标签冲突。  
忽略了code block和大多数的参数检查。  

## text to qrcode.lua    
依赖：github.com/speedata/luaqrcode/blob/master/qrencode.lua  
将行内文字转化成二维码(QRCode).  
支持定义二维码大小，颜色和透明度。  

## MediaInfo.lua    
依赖:https://github.com/kawaCat/MediaInfo-For-LuaJIT 和 mediainfo.dll(32bit) [二进制文件](https://mediaarea.net/download/binary/libmediainfo0/20.03/MediaInfo_DLL_20.03_Windows_i386_WithoutInstaller.7z).   
在Aegisub中查看媒体文件的信息.   
利用C函数解决了Unicode文件名的支持问题(Windows Only)  
注意这只是一个例子.   

## bcc_importer.lua   
依赖:https://github.com/rxi/json.lua  
把Bilibili的CC字幕格式转换成ASS字幕格式.  

## 文本工具   
### CNSpellChecker.lua   
依赖:https://github.com/rxi/json.lua 和 https://github.com/LPGhatguy/luajit-request    
利用百度的NLP相关API，对中文进行错误检查。 

### Text_Stat(\_chi).lua    
获取文本统计信息，例如单词数量，行持续时间等。  
可以把统计结果输出为单独文件。  
你可以把它当作是一个学习 _lua pattern_, _unicode(UTF-8)_, _Aegisub 对话框 API_, 和 _文件操作_ 的范例。  
 _chi_ 后缀是中文版本。  
 
### caiyun_trans.lua    
彩云小译插件。  
无视行内标签，翻译文本(中英日支持)  



