

--====================================================================
local ffi = require("ffi")
--====================================================================

--====================================================================
ffi.cdef [[

// windows
typedef unsigned char       MediaInfo_int8u;
typedef unsigned __int64    MediaInfo_int64u;

/** @brief Kinds of Stream */
typedef enum MediaInfo_stream_t
{
    MediaInfo_Stream_General,
    MediaInfo_Stream_Video,
    MediaInfo_Stream_Audio,
    MediaInfo_Stream_Text,
    MediaInfo_Stream_Other,
    MediaInfo_Stream_Image,
    MediaInfo_Stream_Menu,
    MediaInfo_Stream_Max
} MediaInfo_stream_C;

/** @brief Kinds of Info */
typedef enum MediaInfo_info_t
{
    MediaInfo_Info_Name,
    MediaInfo_Info_Text,
    MediaInfo_Info_Measure,
    MediaInfo_Info_Options,
    MediaInfo_Info_Name_Text,
    MediaInfo_Info_Measure_Text,
    MediaInfo_Info_Info,
    MediaInfo_Info_HowTo,
    MediaInfo_Info_Max
} MediaInfo_info_C;

/** @brief Option if InfoKind = Info_Options */
typedef enum MediaInfo_infooptions_t
{
    MediaInfo_InfoOption_ShowInInform,
    MediaInfo_InfoOption_Reserved,
    MediaInfo_InfoOption_ShowInSupported,
    MediaInfo_InfoOption_TypeOfValue,
    MediaInfo_InfoOption_Max
} MediaInfo_infooptions_C;

/** @brief File opening options */
typedef enum MediaInfo_fileoptions_t
{
    MediaInfo_FileOption_Nothing     = 0x00,
    MediaInfo_FileOption_NoRecursive = 0x01,
    MediaInfo_FileOption_CloseAll    = 0x02,
    MediaInfo_FileOption_Max         = 0x04
} MediaInfo_fileoptions_C;


void*             __stdcall MediaInfo_New (); /*you must ALWAYS call MediaInfo_Delete(Handle) in order to free memory*/
void*             __stdcall MediaInfo_New_Quick (const wchar_t* File, const wchar_t* Options); /*you must ALWAYS call MediaInfo_Delete(Handle) in order to free memory*/
void              __stdcall MediaInfo_Delete (void* Handle);
size_t            __stdcall MediaInfo_Open (void* Handle, const wchar_t* File);
size_t            __stdcall MediaInfo_Open_Buffer (void* Handle, const unsigned char* Begin, size_t Begin_Size, const unsigned char* End, size_t End_Size); /*return Handle*/
size_t            __stdcall MediaInfo_Open_Buffer_Init (void* Handle, MediaInfo_int64u File_Size, MediaInfo_int64u File_Offset);
size_t            __stdcall MediaInfo_Open_Buffer_Continue (void* Handle, MediaInfo_int8u* Buffer, size_t Buffer_Size);
MediaInfo_int64u  __stdcall MediaInfo_Open_Buffer_Continue_GoTo_Get (void* Handle);
size_t            __stdcall MediaInfo_Open_Buffer_Finalize (void* Handle);
size_t            __stdcall MediaInfo_Open_NextPacket (void* Handle);
size_t            __stdcall MediaInfo_Save (void* Handle);
void              __stdcall MediaInfo_Close (void* Handle);
const wchar_t*    __stdcall MediaInfo_Inform (void* Handle, size_t Reserved); /*Default : Reserved=0*/
const wchar_t*    __stdcall MediaInfo_GetI (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, MediaInfo_info_C InfoKind); /*Default : InfoKind=Info_Text*/
const wchar_t*    __stdcall MediaInfo_Get (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber, const wchar_t* Parameter, MediaInfo_info_C InfoKind, MediaInfo_info_C SearchKind); /*Default : InfoKind=Info_Text, SearchKind=Info_Name*/
size_t            __stdcall MediaInfo_SetI (void* Handle, const wchar_t* ToSet, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, const wchar_t* OldParameter);
size_t            __stdcall MediaInfo_Set (void* Handle, const wchar_t* ToSet, MediaInfo_stream_C StreamKind, size_t StreamNumber, const wchar_t* Parameter, const wchar_t* OldParameter);
size_t            __stdcall MediaInfo_Output_Buffer_Get (void* Handle, const wchar_t* Value);
size_t            __stdcall MediaInfo_Output_Buffer_GetI (void* Handle, size_t Pos);
const wchar_t*    __stdcall MediaInfo_Option (void* Handle, const wchar_t* Option, const wchar_t* Value);
size_t            __stdcall MediaInfo_State_Get (void* Handle);
size_t            __stdcall MediaInfo_Count_Get (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber); /*Default : StreamNumber=-1*/


void*             __stdcall MediaInfoA_New (); /*you must ALWAYS call MediaInfo_Delete(Handle) in order to free memory*/
void*             __stdcall MediaInfoA_New_Quick (const char* File, const char* Options); /*you must ALWAYS call MediaInfo_Delete(Handle) in order to free memory*/
void              __stdcall MediaInfoA_Delete (void* Handle);
size_t            __stdcall MediaInfoA_Open (void* Handle, const char* File); /*you must ALWAYS call MediaInfo_Close(Handle) in order to free memory*/
size_t            __stdcall MediaInfoA_Open_Buffer (void* Handle, const unsigned char* Begin, size_t Begin_Size, const unsigned char* End, size_t End_Size); /*return Handle*/
size_t            __stdcall MediaInfoA_Open_Buffer_Init (void* Handle, MediaInfo_int64u File_Size, MediaInfo_int64u File_Offset);
size_t            __stdcall MediaInfoA_Open_Buffer_Continue (void* Handle, MediaInfo_int8u* Buffer, size_t Buffer_Size);
MediaInfo_int64u  __stdcall MediaInfoA_Open_Buffer_Continue_GoTo_Get (void* Handle);
size_t            __stdcall MediaInfoA_Open_Buffer_Finalize (void* Handle);
size_t            __stdcall MediaInfoA_Open_NextPacket (void* Handle);
size_t            __stdcall MediaInfoA_Save (void* Handle);
void              __stdcall MediaInfoA_Close (void* Handle);
const char*       __stdcall MediaInfoA_Inform (void* Handle, size_t Reserved); /*Default : Reserved=MediaInfo_*/
const char*       __stdcall MediaInfoA_GetI (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, MediaInfo_info_C InfoKind); /*Default : InfoKind=Info_Text*/
const char*       __stdcall MediaInfoA_Get (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber, const char* Parameter, MediaInfo_info_C InfoKind, MediaInfo_info_C SearchKind); /*Default : InfoKind=Info_Text, SearchKind=Info_Name*/
size_t            __stdcall MediaInfoA_SetI (void* Handle, const char* ToSet, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, const char* OldParameter);
size_t            __stdcall MediaInfoA_Set (void* Handle, const char* ToSet, MediaInfo_stream_C StreamKind, size_t StreamNumber, const char* Parameter, const char* OldParameter);
size_t            __stdcall MediaInfoA_Output_Buffer_Get (void* Handle, const char* Value);
size_t            __stdcall MediaInfoA_Output_Buffer_GetI (void* Handle, size_t Pos);
const char*       __stdcall MediaInfoA_Option (void* Handle, const char* Option, const char* Value);
size_t            __stdcall MediaInfoA_State_Get (void* Handle);
size_t            __stdcall MediaInfoA_Count_Get (void* Handle, MediaInfo_stream_C StreamKind, size_t StreamNumber); /*Default : StreamNumber=-1*/
// 
// 
void*             __stdcall MediaInfoList_New (); /*you must ALWAYS call MediaInfoList_Delete(Handle) in order to free memory*/
void*             __stdcall MediaInfoList_New_Quick (const wchar_t* Files, const wchar_t* Config); /*you must ALWAYS call MediaInfoList_Delete(Handle) in order to free memory*/
void              __stdcall MediaInfoList_Delete (void* Handle);
size_t            __stdcall MediaInfoList_Open (void* Handle, const wchar_t* Files, const MediaInfo_fileoptions_C Options); /*Default : Options=MediaInfo_FileOption_Nothing*/
size_t            __stdcall MediaInfoList_Open_Buffer (void* Handle, const unsigned char* Begin, size_t Begin_Size, const unsigned char* End, size_t End_Size); /*return Handle*/
size_t            __stdcall MediaInfoList_Save (void* Handle, size_t FilePos);
void              __stdcall MediaInfoList_Close (void* Handle, size_t FilePos);
const wchar_t*    __stdcall MediaInfoList_Inform (void* Handle, size_t FilePos, size_t Reserved); /*Default : Reserved=0*/
const wchar_t*    __stdcall MediaInfoList_GetI (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, MediaInfo_info_C InfoKind); /*Default : InfoKind=Info_Text*/
const wchar_t*    __stdcall MediaInfoList_Get (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, const wchar_t* Parameter, MediaInfo_info_C InfoKind, MediaInfo_info_C SearchKind); /*Default : InfoKind=Info_Text, SearchKind=Info_Name*/
size_t            __stdcall MediaInfoList_SetI (void* Handle, const wchar_t* ToSet, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, const wchar_t* OldParameter);
size_t            __stdcall MediaInfoList_Set (void* Handle, const wchar_t* ToSet, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, const wchar_t* Parameter, const wchar_t* OldParameter);
const wchar_t*    __stdcall MediaInfoList_Option (void* Handle, const wchar_t* Option, const wchar_t* Value);
size_t            __stdcall MediaInfoList_State_Get (void* Handle);
size_t            __stdcall MediaInfoList_Count_Get (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber); /*Default : StreamNumber=-1*/
size_t            __stdcall MediaInfoList_Count_Get_Files (void* Handle);
// 
// /* Warning : Deprecated, use MediaInfo_Option("Info_Version", "**YOUR VERSION COMPATIBLE**") instead */
const char*       __stdcall MediaInfo_Info_Version ();
// 
void*             __stdcall MediaInfoListA_New (); /*you must ALWAYS call MediaInfoList_Delete(Handle) in order to free memory*/
void*             __stdcall MediaInfoListA_New_Quick (const char* Files, const char* Config); /*you must ALWAYS call MediaInfoList_Delete(Handle) in order to free memory*/
void              __stdcall MediaInfoListA_Delete (void* Handle);
size_t            __stdcall MediaInfoListA_Open (void* Handle, const char* Files, const MediaInfo_fileoptions_C Options); /*Default : Options=0*/
size_t            __stdcall MediaInfoListA_Open_Buffer (void* Handle, const unsigned char* Begin, size_t Begin_Size, const unsigned char* End, size_t End_Size); /*return Handle*/
size_t            __stdcall MediaInfoListA_Save (void* Handle, size_t FilePos);
void              __stdcall MediaInfoListA_Close (void* Handle, size_t FilePos);
const char*       __stdcall MediaInfoListA_Inform (void* Handle, size_t FilePos, size_t Reserved); /*Default : Reserved=0*/
const char*       __stdcall MediaInfoListA_GetI (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, MediaInfo_info_C InfoKind); /*Default : InfoKind=Info_Text*/
const char*       __stdcall MediaInfoListA_Get (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, const char* Parameter, MediaInfo_info_C InfoKind, MediaInfo_info_C SearchKind); /*Default : InfoKind=Info_Text, SearchKind=Info_Name*/
size_t            __stdcall MediaInfoListA_SetI (void* Handle, const char* ToSet, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, size_t Parameter, const char* OldParameter);
size_t            __stdcall MediaInfoListA_Set (void* Handles, const char* ToSet, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber, const char* Parameter, const char* OldParameter);
const char*       __stdcall MediaInfoListA_Option (void* Handle, const char* Option, const char* Value);
size_t            __stdcall MediaInfoListA_State_Get (void* Handle);
size_t            __stdcall MediaInfoListA_Count_Get (void* Handle, size_t FilePos, MediaInfo_stream_C StreamKind, size_t StreamNumber); /*Default : StreamNumber=-1*/
size_t            __stdcall MediaInfoListA_Count_Get_Files (void* Handle);
]]
--====================================================================



--====================================================================
-- load
--====================================================================
return ffi.load 'MediaInfo.dll' --32bit
--====================================================================

