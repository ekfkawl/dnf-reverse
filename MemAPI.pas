unit MemAPI;

interface

uses
  SysUtils, Windows, TlHelp32, PsAPI;

  function alloc: Pointer; overload;
  function alloc(Size: Integer): Pointer; overload;
  function Inject(f: Pointer): DWORD64;
  function wd1(const dwAddress: DWORD64; dwValue: Byte): Boolean;
  function wd2(const dwAddress: DWORD64; dwValue: Word): Boolean;
  function wd4(const dwAddress: DWORD64; dwValue: DWORD): Boolean;
  function wd8(const dwAddress: DWORD64; dwValue: DWORD64): Boolean;
  function wf4(const dwAddress: DWORD64; dwValue: Single): Boolean;
  function rd1(const dwAddress: DWORD64): Byte;
  function rd2(const dwAddress: DWORD64): Word;
  function rd4(const dwAddress: DWORD64): DWORD;
  function rd8(const dwAddress: DWORD64): DWORD64;
  function rf4(const dwAddress: DWORD64): Single;
  procedure cpymem4(const dwOrigin, dwNewm, Size: DWORD64);
  procedure CopyMemory(const dest, source, size: DWORD64);
  procedure JumpHook64(const dwHookAddress, dwMyAddress: DWORD64);
  procedure CallHook64(const dwHookAddress, dwMyAddress: DWORD64);

implementation

  uses Main;


function alloc: Pointer; overload;
begin
  Result:= VirtualAllocEx(hProcess, nil, 1024, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
end;

function alloc(Size: Integer): Pointer; overload;
begin
  Result:= VirtualAllocEx(hProcess, nil, Size, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
end;

function Inject(f: Pointer): DWORD64;
begin
  const base = alloc;
  WriteProcessMemory(hProcess, base, f, 1024, PSIZE_T(nil)^);
  Result:= DWORD64(base);
end;

function wd1(const dwAddress: DWORD64; dwValue: Byte): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 1, PSIZE_T(nil)^);
end;

function wd2(const dwAddress: DWORD64; dwValue: Word): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 2, PSIZE_T(nil)^);
end;

function wd4(const dwAddress: DWORD64; dwValue: DWORD): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 4, PSIZE_T(nil)^);
end;

function wd8(const dwAddress: DWORD64; dwValue: DWORD64): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 8, PSIZE_T(nil)^);
end;

function wf4(const dwAddress: DWORD64; dwValue: Single): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 4, PSIZE_T(nil)^);
end;

function rd1(const dwAddress: DWORD64): Byte;
begin
  if not ReadProcessMemory(hProcess, ptr(dwAddress), @Result, 1, PSIZE_T(nil)^) then
    raise EAbort.Create('');
end;

function rd2(const dwAddress: DWORD64): Word;
begin
  if not ReadProcessMemory(hProcess, ptr(dwAddress), @Result, 2, PSIZE_T(nil)^) then
    raise EAbort.Create('');
end;

function rd4(const dwAddress: DWORD64): DWORD;
begin
  if not ReadProcessMemory(hProcess, ptr(dwAddress), @Result, 4, PSIZE_T(nil)^) then
    raise EAbort.Create('');
end;

function rd8(const dwAddress: DWORD64): DWORD64;
begin
  if not ReadProcessMemory(hProcess, ptr(dwAddress), @Result, 8, PSIZE_T(nil)^) then
    raise EAbort.Create('');
end;

function rf4(const dwAddress: DWORD64): Single;
begin
  if not ReadProcessMemory(hProcess, ptr(dwAddress), @Result, 4, PSIZE_T(nil)^) then
    raise EAbort.Create('');
end;

procedure cpymem4(const dwOrigin, dwNewm, Size: DWORD64);
var i: DWORD;
begin
  for i:= 0 to Size do
    wd4(dwNewm+i*4, rd4(dwOrigin+i*4));
end;

procedure CopyMemory(const dest, source, size: DWORD64);
var
  buf: Array of Byte;
begin
  SetLength(buf, size);
  ReadProcessMemory(hProcess, ptr(source), buf, size, PSIZE_T(nil)^);
  WriteProcessMemory(hProcess, ptr(dest), buf, size, PSIZE_T(nil)^);
end;

procedure JumpHook64(const dwHookAddress, dwMyAddress: DWORD64);
var dOldProtect: DWORD;
begin
  VirtualProtectEx(hProcess, Ptr(dwHookAddress), $e, PAGE_EXECUTE_READWRITE, dOldProtect);
  wd8(dwHookAddress, $00000000000025FF);
  wd8(dwHookAddress + 6, dwMyAddress);
  VirtualProtectEx(hProcess, Ptr(dwHookAddress), $e, dOldProtect, dOldProtect);
end;

procedure CallHook64(const dwHookAddress, dwMyAddress: DWORD64);
var dOldProtect: DWORD;
begin
  VirtualProtectEx(hProcess, Ptr(dwHookAddress), $e, PAGE_EXECUTE_READWRITE, dOldProtect);
  wd8(dwHookAddress, $08EB0000000215FF);
  wd8(dwHookAddress + 8, dwMyAddress);
  wd2(dwHookAddress + $10, $EEEB);
  VirtualProtectEx(hProcess, Ptr(dwHookAddress), $e, dOldProtect, dOldProtect);
end;

procedure InputAddress(lpBuffer: Array of DWORD);
var
  i, j: DWORD;
begin
//  for i:= 1 to Length(lpBuffer) - 1 do
//    for j:= 0 to 1024 do
//    begin
//      const v = Self.PDWORD(lpBuffer[0] + j);
//      if (v = $0FFFFFFF) Or (v = $1FFFFFFF) then
//      begin
//        Self._PDWORD(lpBuffer[0] + j, lpBuffer[i]);
//        break;
//      end;
//    end;
end;

end.
