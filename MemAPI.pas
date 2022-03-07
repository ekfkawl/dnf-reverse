unit MemAPI;

interface

uses
  SysUtils, Windows, TlHelp32, PsAPI;

  function AllocMemory: Pointer;
  function AllocMemoryEx(Size: Integer): Pointer;
  function wd1(const dwAddress: DWORD64; dwValue: Byte): Boolean;
  function wd4(const dwAddress: DWORD64; dwValue: DWORD): Boolean;
  function wd8(const dwAddress: DWORD64; dwValue: DWORD64): Boolean;
  function wf4(const dwAddress: DWORD64; dwValue: Single): Boolean;
  function rd1(const dwAddress: DWORD64): Byte;
  function rd2(const dwAddress: DWORD64): Word;
  function rd4(const dwAddress: DWORD64): DWORD;
  function rd8(const dwAddress: DWORD64): DWORD64;
  function rf4(const dwAddress: DWORD64): Single;
  procedure cpymem4(const dwOrigin, dwNewm, Size: DWORD64);

implementation

  uses Main;


function AllocMemory: Pointer;
begin
  Result:= VirtualAllocEx(hProcess, nil, 16, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
end;

function AllocMemoryEx(Size: Integer): Pointer;
begin
  Result:= VirtualAllocEx(hProcess, nil, Size, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
end;

function wd1(const dwAddress: DWORD64; dwValue: Byte): Boolean;
begin
  Result:= WriteProcessMemory(hProcess, ptr(dwAddress), @dwValue, 1, PSIZE_T(nil)^);
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


end.
