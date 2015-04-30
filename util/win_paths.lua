--[[
Copyright 2015 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]
local ffi = require("ffi")
if ffi.os ~= 'Windows' then return end
ffi.cdef [[
]]
if ffi.arch == 'x86' then ffi.cdef[[
  typedef int32_t* INT_PTR;
]]
end
ffi.cdef[[
]]
if ffi.arch == 'x86' then ffi.cdef[[
  typedef uint32_t* UINT_PTR;
]]
end
ffi.cdef[[
]]
if ffi.arch == 'x64' then ffi.cdef[[
  typedef int64_t* INT_PTR;
]]
end
ffi.cdef[[
]]
if ffi.arch == 'x64' then ffi.cdef[[
  typedef uint64_t* UINT_PTR;
]]
end

ffi.cdef[[
  typedef UINT_PTR HANDLE;
  enum { MAX_PATH = 260 };
  enum { ANYSIZE_ARRAY = 1 };
  enum { MAX_PATH_plus_1 = 261 };
  typedef void* HMODULE;
  typedef void VOID;
  typedef VOID *LPVOID; //Pointer
  typedef LPVOID LPCVOID; //Alias
  typedef LPVOID PVOID; //Alias
  typedef LPVOID PCVOID; //Alias
  typedef uint64_t PVOID64; //Integer
  typedef uint8_t BYTE; //Integer
  typedef BYTE *LPBYTE; //Pointer
  typedef LPBYTE PBYTE; //Alias
  typedef LPBYTE LPCBYTE; //Alias
  typedef BYTE byte; //Alias
  typedef uint8_t UCHAR; //Integer
  typedef UCHAR *PUCHAR; //Pointer
  typedef uint8_t UINT8; //Integer
  typedef UINT8 *PUINT8; //Pointer
  typedef int8_t INT8; //Integer
  typedef int16_t INT16; //Integer
  typedef uint16_t UINT16; //Integer
  typedef UINT16 WORD; //Alias
  typedef WORD *PWORD; //Pointer
  typedef WORD* LPWORD; //Alias
  typedef UINT16 USHORT; //Alias
  typedef USHORT *PUSHORT; //Pointer
  typedef USHORT u_short; //Alias
  typedef int16_t SHORT; //Integer
  typedef UINT_PTR *PUINT_PTR; //Pointer
  typedef UINT_PTR ULONG_PTR; //Alias
  typedef ULONG_PTR* PULONG_PTR; //Alias
  typedef ULONG_PTR DWORD_PTR; //Alias
  typedef DWORD_PTR* PDWORD_PTR; //Alias
  typedef INT_PTR LONG_PTR; //Alias
  typedef int32_t BOOL; //Integer
  static const BOOL BOOL_TRUE = 1;
  static const BOOL BOOL_FALSE = 0;
  typedef BOOL *PBOOL; //Pointer
  typedef PBOOL LPBOOL; //Alias
  typedef BOOL Bool; //Alias
  typedef BOOL BOOLAPI; //Alias
  typedef int8_t BOOLEAN; //Integer
  static const BOOLEAN BOOLEAN_TRUE = 1;
  static const BOOLEAN BOOLEAN_FALSE = 0;
  typedef BOOLEAN *PBOOLEAN; //Pointer
  typedef uint32_t UINT32; //Integer
  typedef UINT32 *PUINT32; //Pointer
  typedef UINT32 u_long; //Alias
  typedef UINT32 ULONG; //Alias
  typedef ULONG *PULONG; //Pointer
  typedef UINT32 Ulong; //Alias
  typedef UINT32 UINT; //Alias
  typedef UINT *PUINT; //Pointer
  typedef PUINT LPUINT; //Alias
  typedef ULONG ULONG32; //Alias
  typedef int32_t INT32; //Integer
  typedef long LONG; //Alias
  typedef LONG* PLONG; //Alias
  typedef LONG* LPLONG; //Alias
  typedef int INT; //Alias
  typedef INT *PINT; //Pointer
  typedef PINT LPINT; //Alias
  typedef int64_t INT64; //Integer
  typedef INT64 LONGLONG; //Alias
  typedef LONGLONG *PLONGLONG; //Pointer
  typedef INT64 LONG64; //Alias
  typedef LONG64 *PLONG64; //Pointer
  typedef uint64_t UINT64; //Integer
  typedef UINT64 *PUINT64; //Pointer
  typedef UINT64 ULONGLONG; //Alias
  typedef ULONGLONG *PULONGLONG; //Pointer
  typedef UINT64 ULONG64; //Alias
  typedef ULONG64 *PULONG64; //Pointer
  typedef UINT64 DWORD64; //Alias
  typedef DWORD64 *PDWORD64; //Pointer
  typedef ULONGLONG DWORDLONG; //Alias
  typedef uint32_t DWORD; //Integer
  typedef DWORD *PDWORD; //Pointer
  typedef PDWORD LPDWORD; //Alias
  typedef char CHAR;
  typedef CHAR *LPSTR; //Pointer
  typedef LPSTR LPCSTR; //Alias
  typedef LPSTR PCSTR; //Alias
  typedef LPSTR PSTR; //Alias
  typedef LPSTR PCHAR; //Alias
  typedef wchar_t WCHAR;
  typedef WCHAR *LPWSTR; //Pointer
  typedef LPWSTR PWSTR; //Alias
  typedef PWSTR PCWSTR; //Alias
  typedef PWSTR LPCWSTR; //Alias
  typedef PWSTR PWCHAR; //Alias
  typedef char TCHAR;
  typedef TCHAR *LPTSTR; //Pointer
  typedef LPTSTR LPCTSTR; //Alias
  typedef LPTSTR PTSTR; //Alias
  typedef LPTSTR PCTSTR; //Alias
  typedef LPTSTR PCTSTR; //Alias
  typedef LPTSTR PTCHAR; //Alias
  typedef LPTSTR LPTCH; //Alias
  typedef LPTSTR LPCTCH; //Alias
  typedef size_t SIZE_T; //Alias
  typedef SIZE_T* PSIZE_T; //Alias
  typedef INT64 time_t; //Alias
  typedef float FLOAT; //Alias
  typedef FLOAT *PFLOAT; //Pointer
  typedef double DOUBLE; //Alias
  typedef int32_t HRESULT;
typedef enum  { 
  ASSOCF_NONE                  = 0x00000000,
  ASSOCF_INIT_NOREMAPCLSID     = 0x00000001,
  ASSOCF_INIT_BYEXENAME        = 0x00000002,
  ASSOCF_OPEN_BYEXENAME        = 0x00000002,
  ASSOCF_INIT_DEFAULTTOSTAR    = 0x00000004,
  ASSOCF_INIT_DEFAULTTOFOLDER  = 0x00000008,
  ASSOCF_NOUSERSETTINGS        = 0x00000010,
  ASSOCF_NOTRUNCATE            = 0x00000020,
  ASSOCF_VERIFY                = 0x00000040,
  ASSOCF_REMAPRUNDLL           = 0x00000080,
  ASSOCF_NOFIXUPS              = 0x00000100,
  ASSOCF_IGNOREBASECLASS       = 0x00000200,
  ASSOCF_INIT_IGNOREUNKNOWN    = 0x00000400,
  ASSOCF_INIT_FIXED_PROGID     = 0x00000800,
  ASSOCF_IS_PROTOCOL           = 0x00001000,
  ASSOCF_INIT_FOR_FILE         = 0x00002000
} ASSOCF;

typedef enum {
  ASSOCSTR_COMMAND,
  ASSOCSTR_EXECUTABLE,
  ASSOCSTR_FRIENDLYDOCNAME,
  ASSOCSTR_FRIENDLYAPPNAME,
  ASSOCSTR_NOOPEN,
  ASSOCSTR_SHELLNEWVALUE,
  ASSOCSTR_DDECOMMAND,
  ASSOCSTR_DDEIFEXEC,
  ASSOCSTR_DDEAPPLICATION,
  ASSOCSTR_DDETOPIC
} ASSOCSTR;

typedef struct _GUID {
    unsigned long  Data1;
    unsigned short Data2;
    unsigned short Data3;
    unsigned char  Data4[ 8 ];
} GUID;

HRESULT SHGetKnownFolderPath(GUID *rfid, DWORD dwFlags, HANDLE hToken, PWSTR *ppszPath);
int WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);
void CoTaskMemFree(void *pv);
HRESULT AssocQueryStringA(ASSOCF flags, ASSOCSTR str, LPCTSTR pszAssoc, LPCTSTR pszExtra, LPTSTR pszOut, DWORD* pcchOut);

]]

local Shell32 = ffi.load("Shell32")
local Ole32 = ffi.load("Ole32")
local Shlwapi = ffi.load("Shlwapi")

exports.FOLDERID_NetworkFolder = ffi.new("GUID", {0xD20BEEC4, 0x5CA8, 0x4905, {0xAE, 0x3B, 0xBF, 0x25, 0x1E, 0xA0, 0x9B, 0x53}})
exports.FOLDERID_ComputerFolder = ffi.new("GUID", {0x0AC0837C, 0xBBF8, 0x452A, {0x85, 0x0D, 0x79, 0xD0, 0x8E, 0x66, 0x7C, 0xA7}})
exports.FOLDERID_InternetFolder = ffi.new("GUID", {0x4D9F7874, 0x4E0C, 0x4904, {0x96, 0x7B, 0x40, 0xB0, 0xD2, 0x0C, 0x3E, 0x4B}})
exports.FOLDERID_ControlPanelFolder = ffi.new("GUID", {0x82A74AEB, 0xAEB4, 0x465C, {0xA0, 0x14, 0xD0, 0x97, 0xEE, 0x34, 0x6D, 0x63}})
exports.FOLDERID_PrintersFolder = ffi.new("GUID", {0x76FC4E2D, 0xD6AD, 0x4519, {0xA6, 0x63, 0x37, 0xBD, 0x56, 0x06, 0x81, 0x85}})
exports.FOLDERID_SyncManagerFolder = ffi.new("GUID", {0x43668BF8, 0xC14E, 0x49B2, {0x97, 0xC9, 0x74, 0x77, 0x84, 0xD7, 0x84, 0xB7}})
exports.FOLDERID_SyncSetupFolder = ffi.new("GUID", {0xf214138, 0xb1d3, 0x4a90, {0xbb, 0xa9, 0x27, 0xcb, 0xc0, 0xc5, 0x38, 0x9a}})
exports.FOLDERID_ConflictFolder = ffi.new("GUID", {0x4bfefb45, 0x347d, 0x4006, {0xa5, 0xbe, 0xac, 0x0c, 0xb0, 0x56, 0x71, 0x92}})
exports.FOLDERID_SyncResultsFolder = ffi.new("GUID", {0x289a9a43, 0xbe44, 0x4057, {0xa4, 0x1b, 0x58, 0x7a, 0x76, 0xd7, 0xe7, 0xf9}})
exports.FOLDERID_RecycleBinFolder = ffi.new("GUID", {0xB7534046, 0x3ECB, 0x4C18, {0xBE, 0x4E, 0x64, 0xCD, 0x4C, 0xB7, 0xD6, 0xAC}})
exports.FOLDERID_ConnectionsFolder = ffi.new("GUID", {0x6F0CD92B, 0x2E97, 0x45D1, {0x88, 0xFF, 0xB0, 0xD1, 0x86, 0xB8, 0xDE, 0xDD}})
exports.FOLDERID_Fonts = ffi.new("GUID", {0xFD228CB7, 0xAE11, 0x4AE3, {0x86, 0x4C, 0x16, 0xF3, 0x91, 0x0A, 0xB8, 0xFE}})
exports.FOLDERID_Desktop = ffi.new("GUID", {0xB4BFCC3A, 0xDB2C, 0x424C, {0xB0, 0x29, 0x7F, 0xE9, 0x9A, 0x87, 0xC6, 0x41}})
exports.FOLDERID_Startup = ffi.new("GUID", {0xB97D20BB, 0xF46A, 0x4C97, {0xBA, 0x10, 0x5E, 0x36, 0x08, 0x43, 0x08, 0x54}})
exports.FOLDERID_Programs = ffi.new("GUID", {0xA77F5D77, 0x2E2B, 0x44C3, {0xA6, 0xA2, 0xAB, 0xA6, 0x01, 0x05, 0x4A, 0x51}})
exports.FOLDERID_StartMenu = ffi.new("GUID", {0x625B53C3, 0xAB48, 0x4EC1, {0xBA, 0x1F, 0xA1, 0xEF, 0x41, 0x46, 0xFC, 0x19}})
exports.FOLDERID_Recent = ffi.new("GUID", {0xAE50C081, 0xEBD2, 0x438A, {0x86, 0x55, 0x8A, 0x09, 0x2E, 0x34, 0x98, 0x7A}})
exports.FOLDERID_SendTo = ffi.new("GUID", {0x8983036C, 0x27C0, 0x404B, {0x8F, 0x08, 0x10, 0x2D, 0x10, 0xDC, 0xFD, 0x74}})
exports.FOLDERID_Documents = ffi.new("GUID", {0xFDD39AD0, 0x238F, 0x46AF, {0xAD, 0xB4, 0x6C, 0x85, 0x48, 0x03, 0x69, 0xC7}})
exports.FOLDERID_Favorites = ffi.new("GUID", {0x1777F761, 0x68AD, 0x4D8A, {0x87, 0xBD, 0x30, 0xB7, 0x59, 0xFA, 0x33, 0xDD}})
exports.FOLDERID_NetHood = ffi.new("GUID", {0xC5ABBF53, 0xE17F, 0x4121, {0x89, 0x00, 0x86, 0x62, 0x6F, 0xC2, 0xC9, 0x73}})
exports.FOLDERID_PrintHood = ffi.new("GUID", {0x9274BD8D, 0xCFD1, 0x41C3, {0xB3, 0x5E, 0xB1, 0x3F, 0x55, 0xA7, 0x58, 0xF4}})
exports.FOLDERID_Templates = ffi.new("GUID", {0xA63293E8, 0x664E, 0x48DB, {0xA0, 0x79, 0xDF, 0x75, 0x9E, 0x05, 0x09, 0xF7}})
exports.FOLDERID_CommonStartup = ffi.new("GUID", {0x82A5EA35, 0xD9CD, 0x47C5, {0x96, 0x29, 0xE1, 0x5D, 0x2F, 0x71, 0x4E, 0x6E}})
exports.FOLDERID_CommonPrograms = ffi.new("GUID", {0x0139D44E, 0x6AFE, 0x49F2, {0x86, 0x90, 0x3D, 0xAF, 0xCA, 0xE6, 0xFF, 0xB8}})
exports.FOLDERID_CommonStartMenu = ffi.new("GUID", {0xA4115719, 0xD62E, 0x491D, {0xAA, 0x7C, 0xE7, 0x4B, 0x8B, 0xE3, 0xB0, 0x67}})
exports.FOLDERID_PublicDesktop = ffi.new("GUID", {0xC4AA340D, 0xF20F, 0x4863, {0xAF, 0xEF, 0xF8, 0x7E, 0xF2, 0xE6, 0xBA, 0x25}})
exports.FOLDERID_ProgramData = ffi.new("GUID", {0x62AB5D82, 0xFDC1, 0x4DC3, {0xA9, 0xDD, 0x07, 0x0D, 0x1D, 0x49, 0x5D, 0x97}})
exports.FOLDERID_CommonTemplates = ffi.new("GUID", {0xB94237E7, 0x57AC, 0x4347, {0x91, 0x51, 0xB0, 0x8C, 0x6C, 0x32, 0xD1, 0xF7}})
exports.FOLDERID_PublicDocuments = ffi.new("GUID", {0xED4824AF, 0xDCE4, 0x45A8, {0x81, 0xE2, 0xFC, 0x79, 0x65, 0x08, 0x36, 0x34}})
exports.FOLDERID_RoamingAppData = ffi.new("GUID", {0x3EB685DB, 0x65F9, 0x4CF6, {0xA0, 0x3A, 0xE3, 0xEF, 0x65, 0x72, 0x9F, 0x3D}})
exports.FOLDERID_LocalAppData = ffi.new("GUID", {0xF1B32785, 0x6FBA, 0x4FCF, {0x9D, 0x55, 0x7B, 0x8E, 0x7F, 0x15, 0x70, 0x91}})
exports.FOLDERID_LocalAppDataLow = ffi.new("GUID", {0xA520A1A4, 0x1780, 0x4FF6, {0xBD, 0x18, 0x16, 0x73, 0x43, 0xC5, 0xAF, 0x16}})
exports.FOLDERID_InternetCache = ffi.new("GUID", {0x352481E8, 0x33BE, 0x4251, {0xBA, 0x85, 0x60, 0x07, 0xCA, 0xED, 0xCF, 0x9D}})
exports.FOLDERID_Cookies = ffi.new("GUID", {0x2B0F765D, 0xC0E9, 0x4171, {0x90, 0x8E, 0x08, 0xA6, 0x11, 0xB8, 0x4F, 0xF6}})
exports.FOLDERID_History = ffi.new("GUID", {0xD9DC8A3B, 0xB784, 0x432E, {0xA7, 0x81, 0x5A, 0x11, 0x30, 0xA7, 0x59, 0x63}})
exports.FOLDERID_System = ffi.new("GUID", {0x1AC14E77, 0x02E7, 0x4E5D, {0xB7, 0x44, 0x2E, 0xB1, 0xAE, 0x51, 0x98, 0xB7}})
exports.FOLDERID_SystemX86 = ffi.new("GUID", {0xD65231B0, 0xB2F1, 0x4857, {0xA4, 0xCE, 0xA8, 0xE7, 0xC6, 0xEA, 0x7D, 0x27}})
exports.FOLDERID_Windows = ffi.new("GUID", {0xF38BF404, 0x1D43, 0x42F2, {0x93, 0x05, 0x67, 0xDE, 0x0B, 0x28, 0xFC, 0x23}})
exports.FOLDERID_Profile = ffi.new("GUID", {0x5E6C858F, 0x0E22, 0x4760, {0x9A, 0xFE, 0xEA, 0x33, 0x17, 0xB6, 0x71, 0x73}})
exports.FOLDERID_Pictures = ffi.new("GUID", {0x33E28130, 0x4E1E, 0x4676, {0x83, 0x5A, 0x98, 0x39, 0x5C, 0x3B, 0xC3, 0xBB}})
exports.FOLDERID_ProgramFilesX86 = ffi.new("GUID", {0x7C5A40EF, 0xA0FB, 0x4BFC, {0x87, 0x4A, 0xC0, 0xF2, 0xE0, 0xB9, 0xFA, 0x8E}})
exports.FOLDERID_ProgramFilesCommonX86 = ffi.new("GUID", {0xDE974D24, 0xD9C6, 0x4D3E, {0xBF, 0x91, 0xF4, 0x45, 0x51, 0x20, 0xB9, 0x17}})
exports.FOLDERID_ProgramFilesX64 = ffi.new("GUID", {0x6d809377, 0x6af0, 0x444b, {0x89, 0x57, 0xa3, 0x77, 0x3f, 0x02, 0x20, 0x0e }})
exports.FOLDERID_ProgramFilesCommonX64 = ffi.new("GUID", {0x6365d5a7, 0xf0d, 0x45e5, {0x87, 0xf6, 0xd, 0xa5, 0x6b, 0x6a, 0x4f, 0x7d }})
exports.FOLDERID_ProgramFiles = ffi.new("GUID", {0x905e63b6, 0xc1bf, 0x494e, {0xb2, 0x9c, 0x65, 0xb7, 0x32, 0xd3, 0xd2, 0x1a}})
exports.FOLDERID_ProgramFilesCommon = ffi.new("GUID", {0xF7F1ED05, 0x9F6D, 0x47A2, {0xAA, 0xAE, 0x29, 0xD3, 0x17, 0xC6, 0xF0, 0x66}})
exports.FOLDERID_UserProgramFiles = ffi.new("GUID", {0x5cd7aee2, 0x2219, 0x4a67, {0xb8, 0x5d, 0x6c, 0x9c, 0xe1, 0x56, 0x60, 0xcb}})
exports.FOLDERID_UserProgramFilesCommon = ffi.new("GUID", {0xbcbd3057, 0xca5c, 0x4622, {0xb4, 0x2d, 0xbc, 0x56, 0xdb, 0x0a, 0xe5, 0x16}})
exports.FOLDERID_AdminTools = ffi.new("GUID", {0x724EF170, 0xA42D, 0x4FEF, {0x9F, 0x26, 0xB6, 0x0E, 0x84, 0x6F, 0xBA, 0x4F}})
exports.FOLDERID_CommonAdminTools = ffi.new("GUID", {0xD0384E7D, 0xBAC3, 0x4797, {0x8F, 0x14, 0xCB, 0xA2, 0x29, 0xB3, 0x92, 0xB5}})
exports.FOLDERID_Music = ffi.new("GUID", {0x4BD8D571, 0x6D19, 0x48D3, {0xBE, 0x97, 0x42, 0x22, 0x20, 0x08, 0x0E, 0x43}})
exports.FOLDERID_Videos = ffi.new("GUID", {0x18989B1D, 0x99B5, 0x455B, {0x84, 0x1C, 0xAB, 0x7C, 0x74, 0xE4, 0xDD, 0xFC}})
exports.FOLDERID_Ringtones = ffi.new("GUID", {0xC870044B, 0xF49E, 0x4126, {0xA9, 0xC3, 0xB5, 0x2A, 0x1F, 0xF4, 0x11, 0xE8}})
exports.FOLDERID_PublicPictures = ffi.new("GUID", {0xB6EBFB86, 0x6907, 0x413C, {0x9A, 0xF7, 0x4F, 0xC2, 0xAB, 0xF0, 0x7C, 0xC5}})
exports.FOLDERID_PublicMusic = ffi.new("GUID", {0x3214FAB5, 0x9757, 0x4298, {0xBB, 0x61, 0x92, 0xA9, 0xDE, 0xAA, 0x44, 0xFF}})
exports.FOLDERID_PublicVideos = ffi.new("GUID", {0x2400183A, 0x6185, 0x49FB, {0xA2, 0xD8, 0x4A, 0x39, 0x2A, 0x60, 0x2B, 0xA3}})
exports.FOLDERID_PublicRingtones = ffi.new("GUID", {0xE555AB60, 0x153B, 0x4D17, {0x9F, 0x04, 0xA5, 0xFE, 0x99, 0xFC, 0x15, 0xEC}})
exports.FOLDERID_ResourceDir = ffi.new("GUID", {0x8AD10C31, 0x2ADB, 0x4296, {0xA8, 0xF7, 0xE4, 0x70, 0x12, 0x32, 0xC9, 0x72}})
exports.FOLDERID_LocalizedResourcesDir = ffi.new("GUID", {0x2A00375E, 0x224C, 0x49DE, {0xB8, 0xD1, 0x44, 0x0D, 0xF7, 0xEF, 0x3D, 0xDC}})
exports.FOLDERID_CommonOEMLinks = ffi.new("GUID", {0xC1BAE2D0, 0x10DF, 0x4334, {0xBE, 0xDD, 0x7A, 0xA2, 0x0B, 0x22, 0x7A, 0x9D}})
exports.FOLDERID_CDBurning = ffi.new("GUID", {0x9E52AB10, 0xF80D, 0x49DF, {0xAC, 0xB8, 0x43, 0x30, 0xF5, 0x68, 0x78, 0x55}})
exports.FOLDERID_UserProfiles = ffi.new("GUID", {0x0762D272, 0xC50A, 0x4BB0, {0xA3, 0x82, 0x69, 0x7D, 0xCD, 0x72, 0x9B, 0x80}})
exports.FOLDERID_Playlists = ffi.new("GUID", {0xDE92C1C7, 0x837F, 0x4F69, {0xA3, 0xBB, 0x86, 0xE6, 0x31, 0x20, 0x4A, 0x23}})
exports.FOLDERID_SamplePlaylists = ffi.new("GUID", {0x15CA69B3, 0x30EE, 0x49C1, {0xAC, 0xE1, 0x6B, 0x5E, 0xC3, 0x72, 0xAF, 0xB5}})
exports.FOLDERID_SampleMusic = ffi.new("GUID", {0xB250C668, 0xF57D, 0x4EE1, {0xA6, 0x3C, 0x29, 0x0E, 0xE7, 0xD1, 0xAA, 0x1F}})
exports.FOLDERID_SamplePictures = ffi.new("GUID", {0xC4900540, 0x2379, 0x4C75, {0x84, 0x4B, 0x64, 0xE6, 0xFA, 0xF8, 0x71, 0x6B}})
exports.FOLDERID_SampleVideos = ffi.new("GUID", {0x859EAD94, 0x2E85, 0x48AD, {0xA7, 0x1A, 0x09, 0x69, 0xCB, 0x56, 0xA6, 0xCD}})
exports.FOLDERID_PhotoAlbums = ffi.new("GUID", {0x69D2CF90, 0xFC33, 0x4FB7, {0x9A, 0x0C, 0xEB, 0xB0, 0xF0, 0xFC, 0xB4, 0x3C}})
exports.FOLDERID_Public = ffi.new("GUID", {0xDFDF76A2, 0xC82A, 0x4D63, {0x90, 0x6A, 0x56, 0x44, 0xAC, 0x45, 0x73, 0x85}})
exports.FOLDERID_ChangeRemovePrograms = ffi.new("GUID", {0xdf7266ac, 0x9274, 0x4867, {0x8d, 0x55, 0x3b, 0xd6, 0x61, 0xde, 0x87, 0x2d}})
exports.FOLDERID_AppUpdates = ffi.new("GUID", {0xa305ce99, 0xf527, 0x492b, {0x8b, 0x1a, 0x7e, 0x76, 0xfa, 0x98, 0xd6, 0xe4}})
exports.FOLDERID_AddNewPrograms = ffi.new("GUID", {0xde61d971, 0x5ebc, 0x4f02, {0xa3, 0xa9, 0x6c, 0x82, 0x89, 0x5e, 0x5c, 0x04}})
exports.FOLDERID_Downloads = ffi.new("GUID", {0x374de290, 0x123f, 0x4565, {0x91, 0x64, 0x39, 0xc4, 0x92, 0x5e, 0x46, 0x7b}})
exports.FOLDERID_PublicDownloads = ffi.new("GUID", {0x3d644c9b, 0x1fb8, 0x4f30, {0x9b, 0x45, 0xf6, 0x70, 0x23, 0x5f, 0x79, 0xc0}})
exports.FOLDERID_SavedSearches = ffi.new("GUID", {0x7d1d3a04, 0xdebb, 0x4115, {0x95, 0xcf, 0x2f, 0x29, 0xda, 0x29, 0x20, 0xda}})
exports.FOLDERID_QuickLaunch = ffi.new("GUID", {0x52a4f021, 0x7b75, 0x48a9, {0x9f, 0x6b, 0x4b, 0x87, 0xa2, 0x10, 0xbc, 0x8f}})
exports.FOLDERID_Contacts = ffi.new("GUID", {0x56784854, 0xc6cb, 0x462b, {0x81, 0x69, 0x88, 0xe3, 0x50, 0xac, 0xb8, 0x82}})
exports.FOLDERID_SidebarParts = ffi.new("GUID", {0xa75d362e, 0x50fc, 0x4fb7, {0xac, 0x2c, 0xa8, 0xbe, 0xaa, 0x31, 0x44, 0x93}})
exports.FOLDERID_SidebarDefaultParts = ffi.new("GUID", {0x7b396e54, 0x9ec5, 0x4300, {0xbe, 0xa, 0x24, 0x82, 0xeb, 0xae, 0x1a, 0x26}})
exports.FOLDERID_PublicGameTasks = ffi.new("GUID", {0xdebf2536, 0xe1a8, 0x4c59, {0xb6, 0xa2, 0x41, 0x45, 0x86, 0x47, 0x6a, 0xea}})
exports.FOLDERID_GameTasks = ffi.new("GUID", {0x54fae61, 0x4dd8, 0x4787, {0x80, 0xb6, 0x9, 0x2, 0x20, 0xc4, 0xb7, 0x0}})
exports.FOLDERID_SavedGames = ffi.new("GUID", {0x4c5c32ff, 0xbb9d, 0x43b0, {0xb5, 0xb4, 0x2d, 0x72, 0xe5, 0x4e, 0xaa, 0xa4}})
exports.FOLDERID_Games = ffi.new("GUID", {0xcac52c1a, 0xb53d, 0x4edc, {0x92, 0xd7, 0x6b, 0x2e, 0x8a, 0xc1, 0x94, 0x34}})
exports.FOLDERID_SEARCH_MAPI = ffi.new("GUID", {0x98ec0e18, 0x2098, 0x4d44, {0x86, 0x44, 0x66, 0x97, 0x93, 0x15, 0xa2, 0x81}})
exports.FOLDERID_SEARCH_CSC = ffi.new("GUID", {0xee32e446, 0x31ca, 0x4aba, {0x81, 0x4f, 0xa5, 0xeb, 0xd2, 0xfd, 0x6d, 0x5e}})
exports.FOLDERID_Links = ffi.new("GUID", {0xbfb9d5e0, 0xc6a9, 0x404c, {0xb2, 0xb2, 0xae, 0x6d, 0xb6, 0xaf, 0x49, 0x68}})
exports.FOLDERID_UsersFiles = ffi.new("GUID", {0xf3ce0f7c, 0x4901, 0x4acc, {0x86, 0x48, 0xd5, 0xd4, 0x4b, 0x04, 0xef, 0x8f}})
exports.FOLDERID_UsersLibraries = ffi.new("GUID", {0xa302545d, 0xdeff, 0x464b, {0xab, 0xe8, 0x61, 0xc8, 0x64, 0x8d, 0x93, 0x9b}})
exports.FOLDERID_SearchHome = ffi.new("GUID", {0x190337d1, 0xb8ca, 0x4121, {0xa6, 0x39, 0x6d, 0x47, 0x2d, 0x16, 0x97, 0x2a}})
exports.FOLDERID_OriginalImages = ffi.new("GUID", {0x2C36C0AA, 0x5812, 0x4b87, {0xbf, 0xd0, 0x4c, 0xd0, 0xdf, 0xb1, 0x9b, 0x39}})
exports.FOLDERID_DocumentsLibrary = ffi.new("GUID", {0x7b0db17d, 0x9cd2, 0x4a93, {0x97, 0x33, 0x46, 0xcc, 0x89, 0x02, 0x2e, 0x7c}})
exports.FOLDERID_MusicLibrary = ffi.new("GUID", {0x2112ab0a, 0xc86a, 0x4ffe, {0xa3, 0x68, 0xd, 0xe9, 0x6e, 0x47, 0x1, 0x2e}})
exports.FOLDERID_PicturesLibrary = ffi.new("GUID", {0xa990ae9f, 0xa03b, 0x4e80, {0x94, 0xbc, 0x99, 0x12, 0xd7, 0x50, 0x41, 0x4}})
exports.FOLDERID_VideosLibrary = ffi.new("GUID", {0x491e922f, 0x5643, 0x4af4, {0xa7, 0xeb, 0x4e, 0x7a, 0x13, 0x8d, 0x81, 0x74}})
exports.FOLDERID_RecordedTVLibrary = ffi.new("GUID", {0x1a6fdba2, 0xf42d, 0x4358, {0xa7, 0x98, 0xb7, 0x4d, 0x74, 0x59, 0x26, 0xc5}})
exports.FOLDERID_HomeGroup = ffi.new("GUID", {0x52528a6b, 0xb9e3, 0x4add, {0xb6, 0xd, 0x58, 0x8c, 0x2d, 0xba, 0x84, 0x2d}})
exports.FOLDERID_DeviceMetadataStore = ffi.new("GUID", {0x5ce4a5e9, 0xe4eb, 0x479d, {0xb8, 0x9f, 0x13, 0x0c, 0x02, 0x88, 0x61, 0x55}})
exports.FOLDERID_Libraries = ffi.new("GUID", {0x1b3ea5dc, 0xb587, 0x4786, {0xb4, 0xef, 0xbd, 0x1d, 0xc3, 0x32, 0xae, 0xae}})
exports.FOLDERID_PublicLibraries = ffi.new("GUID", {0x48daf80b, 0xe6cf, 0x4f4e, {0xb8, 0x00, 0x0e, 0x69, 0xd8, 0x4e, 0xe3, 0x84}})
exports.FOLDERID_UserPinned = ffi.new("GUID", {0x9e3995ab, 0x1f9c, 0x4f13, {0xb8, 0x27, 0x48, 0xb2, 0x4b, 0x6c, 0x71, 0x74}})
exports.FOLDERID_ImplicitAppShortcuts = ffi.new("GUID", {0xbcb5256f, 0x79f6, 0x4cee, {0xb7, 0x25, 0xdc, 0x34, 0xe4, 0x2, 0xfd, 0x46}})

exports.GetKnownFolderPath = function(guid)
  local pguid = ffi.new("GUID[1]", guid)
  local ppszPath = ffi.new("PWSTR[1]")
  local buf = ffi.new("CHAR[?]", ffi.C.MAX_PATH) --[[MAX_PATH--]]
  local result = Shell32.SHGetKnownFolderPath(pguid, 0, nil, ppszPath)
  if result ~= 0 then
    return nil
  end
  ffi.C.WideCharToMultiByte(65001 --[[CP_UTF8--]], 0, ppszPath[0], -1, buf, 260, ffi.cast("LPCSTR", 0), nil);
  Ole32.CoTaskMemFree(ppszPath[0])
  return ffi.string(buf)
end

exports.GetAssociatedExe = function(extension, verb)
  verb = verb or 'open'
  local exePathLen = ffi.new("DWORD[1]", ffi.C.MAX_PATH)
  local exePath = ffi.new("char[?]", ffi.C.MAX_PATH)
  local extensionffi = ffi.new("char[?]", #extension)
  local verbffi = ffi.new("char[?]", #verb)
  ffi.copy(extensionffi, extension)
  ffi.copy(verbffi, verb)
  local rv = Shlwapi.AssocQueryStringA(ffi.C.ASSOCF_INIT_IGNOREUNKNOWN,
    ffi.C.ASSOCSTR_EXECUTABLE, extensionffi, verbffi, exePath, exePathLen)
  if rv ~= 0 then return nil end
  return ffi.string(exePath)
end