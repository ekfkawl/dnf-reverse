unit ProcessAPI;

interface

uses
  SysUtils, Windows, TlHelp32, PsAPI;

  function IsWin64: Boolean;

type Process = record
  Id, Width, Height: DWORD64;
  Rect: TRect;
  DC: HDC;

  function GetProcessId(const ProcName: String): Boolean;
  function GetModuleSize(const hModule: HMODULE): DWORD64;
  function GetModuleBase(const ModuleName: PChar): DWORD64;
  function GetRect(const lpClassName, lpWindowName: PWideChar): Boolean;
  function Suspend: Boolean;
  function SelfExcludeSuspend: Boolean;
  function Resume: Boolean;
  function MainThread: DWORD64;
  function ThreadStartAddress(th32ThreadID: DWORD64): Pointer;
  function IsThreadSuspended(th32ThreadID: DWORD64): Boolean;
end;

type
  UNICODE_STRING = packed record
    Length, MaximumLength: WORD;
    Buffer: PWideChar;
  end;

  TUnicodeString = UNICODE_STRING;
  PUnicodeString = ^TUnicodeString;

  CLIENT_ID = packed record
    UniqueProcess: Cardinal;
    UniqueThread: Cardinal;
  end;

  _VM_COUNTERS = packed record
    PeakVirtualSize: ULONG;
    VirtualSize: ULONG;
    PageFaultCount: ULONG;
    PeakWorkingSetSize: ULONG;
    WorkingSetSize: ULONG;
    QuotaPeakPagedPoolUsage: ULONG;
    QuotaPagedPoolUsage: ULONG;
    QuotaPeakNonPagedPoolUsage: ULONG;
    QuotaNonPagedPoolUsage: ULONG;
    PageFileUsage: ULONG;
    PeakPageFileUsage: ULONG;
  end;

  _IO_COUNTERS = packed record
    ReadOperationCount: Int64;
    WriteOperationCount: Int64;
    OtherOperationCount: Int64;
    ReadTransferCount: Int64;
    WriteTransferCount: Int64;
    OtherTransferCount: Int64;
  end;

  SYSTEM_THREADS = packed record
    KernelTime: LARGE_INTEGER;
    UserTime: LARGE_INTEGER;
    CreateTime: LARGE_INTEGER;
    WaitTime: ULONG;
    StartAddress: Pointer;
    ClientId: CLIENT_ID;
    Priority: Integer;
    BasePriority: Integer;
    ContextSwitchCount: ULONG;
    State: Integer;
    WaitReason: Integer;
    Reserved: ULONG;
  end;

  PSYSTEM_THREADS = ^SYSTEM_THREADS;

  SYSTEM_THREADS_ARRAY = array [0 .. 1024] of SYSTEM_THREADS;
  PSYSTEM_THREADS_ARRAY = ^SYSTEM_THREADS_ARRAY;

  SYSTEM_PROCESS_INFORMATION = packed record
    NextEntryDelta: ULONG;
    ThreadCount: ULONG;
    Reserved1: array [0 .. 5] of ULONG;
    CreateTime: FILETIME;
    UserTime: FILETIME;
    KernelTime: FILETIME;
    ProcessName: UNICODE_STRING;
    BasePriority: Integer;
    ProcessId: ULONG;
    InheritedFromProcessId: ULONG;
    HandleCount: ULONG;
    Reserved2: array [0 .. 1] of ULONG;
    VmCounters: _VM_COUNTERS;
    PrivatePageCount: ULONG;
    IoCounters: _IO_COUNTERS;
    Threads: array [0 .. 1024] of SYSTEM_THREADS;
  end;

  PSYSTEM_PROCESS_INFORMATION = ^SYSTEM_PROCESS_INFORMATION;


implementation

const
  THREAD_QUERY_INFORMATION   = $0040;
  STATUS_SUCCESS             = $00000000;
  ThreadQuerySetWin32StartAddress = 9;

type
  NTSTATUS = LONG;
  THREADINFOCLASS = DWORD64;

function NtQueryInformationThread(
    ThreadHandle: THandle;  ThreadInformationClass: THREADINFOCLASS;
    ThreadInformation: Pointer; ThreadInformationLength: ULONG;  ReturnLength: PULONG): NTSTATUS; stdcall; external 'ntdll.dll';


function IsWin64: Boolean;
var
  Kernel32Handle      : THandle;
  IsWow64Process      : function(Handle: THandle; var Res: BOOL): BOOL; stdcall;
  GetNativeSystemInfo : procedure(var lpSystemInfo: TSystemInfo); stdcall;
  isWoW64             : BOOL;
  SystemInfo          : TSystemInfo;
const
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
  PROCESSOR_ARCHITECTURE_IA64  = 6;
begin
  Kernel32Handle:= GetModuleHandle('KERNEL32.DLL');
  if Kernel32Handle = 0 then
    Kernel32Handle:= LoadLibrary('KERNEL32.DLL');
  if Kernel32Handle <> 0 then
  begin
    IsWOW64Process:= GetProcAddress(Kernel32Handle,'IsWow64Process');
    GetNativeSystemInfo:= GetProcAddress(Kernel32Handle,'GetNativeSystemInfo');
    if Assigned(IsWow64Process) then
    begin
      IsWow64Process(GetCurrentProcess, isWoW64);
      Result:= isWoW64 and Assigned(GetNativeSystemInfo);
      if Result then
      begin
        GetNativeSystemInfo(SystemInfo);
        Result:= (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64) or (SystemInfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_IA64);
      end;
    end
    else
     Result:= False;
  end
  else
    Result:= False;
end;

function Process.GetProcessId(const ProcName: String): Boolean;
var
  hSnap: THandle;
  PE32: TPROCESSENTRY32;
begin
  Result:= False;
  Self.Id:= 0;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
  PE32.dwSize:= SizeOf(PROCESSENTRY32);
  Process32First(hSnap, PE32);
  while Process32Next(hSnap, PE32) do
  begin
    if PE32.szExeFile = procName then
    begin
      Self.Id:= PE32.th32ProcessID;
      Result:= True;
      break;
    end;
  end;
  CloseHandle(hSnap);
end;

function Process.GetModuleSize(const hModule: HMODULE): DWORD64;
var SnapShot: THandle;
    Modules: TModuleEntry32;
begin
  Result:= 0;
  SnapShot:= CreateToolhelp32SnapShot(TH32CS_SNAPMODULE, Self.Id);
  Modules.dwSize:= SizeOf(TModuleEntry32);
  if Module32First(SnapShot, Modules) then
  repeat
    if hModule = Modules.hModule then
    begin
      Result:= DWORD64(Modules.modBaseSize);
      break;
    end;
  until not Module32Next(SnapShot, Modules);
  CloseHandle(SnapShot);
end;

function Process.GetModuleBase(const ModuleName: PChar): DWORD64;
var
  SnapShot: THandle;
  Modules: TModuleEntry32;
begin
  Result:= 0;
  SnapShot:= CreateToolhelp32SnapShot(TH32CS_SNAPMODULE, Self.Id);
  Modules.dwSize:= SizeOf(TModuleEntry32);
  if Module32First(SnapShot, Modules) then
  repeat
    if StrComp(PWideChar(UpperCase(ModuleName)), PWideChar(UpperCase(Modules.szModule))) = 0 then
    begin
      Result:= DWORD64(Modules.modBaseAddr);
      break;
    end;
  until not Module32Next(SnapShot, Modules);
  CloseHandle(SnapShot);
end;

function Process.GetRect(const lpClassName, lpWindowName: PWideChar): Boolean;
var
  hWindiw: THandle;
begin
  Result:= False;
  hWindiw:= FindWindow(lpClassName, lpWindowName);
  if hWindiw <> 0 then
  begin
    Self.DC:= GetDC(hWindiw);
    if GetWindowRect(hWindiw, Self.Rect) then
    begin
      Self.Width:= Rect.Right - Rect.Left;
      Self.Height:= Rect.Bottom - Rect.Top;
      Result:= True;
    end;
  end;
end;

function OpenThread(dwDesiredAccess: DWORD64; bInheritHandle: BOOL; dwThreadId: DWORD64): THandle; stdcall; external kernel32;
function NtQuerySystemInformation(SystemInformationClass: DWORD64; SystemInformation: Pointer; SystemInformationLength: ULONG; ReturnLength: PULONG): Cardinal; stdcall; external 'ntdll.dll' name 'NtQuerySystemInformation';

function Process.IsThreadSuspended(th32ThreadID: DWORD64): Boolean;
var
  spi: PSYSTEM_PROCESS_INFORMATION;
  crt: PSYSTEM_PROCESS_INFORMATION;
  PThreadInfo: PSYSTEM_THREADS;
  sz: DWORD64;
  LastProcess: Boolean;
begin
  Result:= False;
  if (NtQuerySystemInformation(5, nil, 0, @sz) = $C0000004) And (sz > 0) then
  begin
    GetMem(spi, sz);
    try
      if NtQuerySystemInformation(5, spi, sz, @sz) = 0 then
      begin
        crt:= spi;
        LastProcess:= False;
        While not LastProcess do
        begin
          LastProcess:= crt^.NextEntryDelta = 0;
          if crt^.ProcessID = Self.Id then
          begin
            for var j:= 0 to crt^.ThreadCount - 1 do
            begin
              PThreadInfo:= PSYSTEM_THREADS(@crt^.Threads[j]);
              if PThreadInfo^.ClientId.UniqueThread = th32ThreadID then
              begin
                if PThreadInfo^.WaitReason = 5 then
                begin
                  Result:= True;
                  break;
                end
                else
                begin
                  Result:= False;
                  break;
                end;
                break;
              end;
            end;
            break;
          end;
          crt:= Pointer(DWORD64(crt) + crt^.NextEntryDelta);
        end;
      end;
    finally
      FreeMem(spi);
    end;
  end;
end;


function Process.Suspend: Boolean;
var
  hSnap, hOpen: THandle;
  THR32: THREADENTRY32;
begin
  Result:= False;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if hSnap <> INVALID_HANDLE_VALUE then
  begin
    THR32.dwSize := SizeOf(THR32);
    Thread32First(hSnap, THR32);
    repeat
      if THR32.th32OwnerProcessID = Self.Id then
      begin
        hOpen:= OpenThread($0002, FALSE, THR32.th32ThreadID);
        if hOpen <> INVALID_HANDLE_VALUE then
        begin
          Result:= True;
          SuspendThread(hOpen);
        end;
        CloseHandle(hOpen);
      end;
    until Thread32Next(hSnap, THR32) = False;
    CloseHandle(hSnap);
  end;
end;

function Process.SelfExcludeSuspend: Boolean;
var
  hSnap, hOpen: THandle;
  THR32: THREADENTRY32;
begin
  Result:= False;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if hSnap <> INVALID_HANDLE_VALUE then
  begin
    THR32.dwSize:= SizeOf(THR32);
    Thread32First(hSnap, THR32);
    repeat
      if THR32.th32OwnerProcessID = Self.Id then
      begin
        if THR32.th32ThreadID <> GetCurrentThreadId then
        begin
          hOpen:= OpenThread($0002, FALSE, THR32.th32ThreadID);
          if hOpen <> INVALID_HANDLE_VALUE then
          begin
            Result:= True;
            SuspendThread(hOpen);
          end;
          CloseHandle(hOpen);
        end;
      end;
    until Thread32Next(hSnap, THR32) = False;
    CloseHandle(hSnap);
  end;
end;

function Process.Resume: Boolean;
var
  cThr, hSnap, hOpen: THandle;
  THR32: THREADENTRY32;
begin
  Result:= False;
  cThr:= GetCurrentThreadId;
  hSnap:= CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if hSnap <> INVALID_HANDLE_VALUE then
  begin
    THR32.dwSize:= SizeOf(TThreadEntry32);
    if Thread32First(hSnap, THR32) then
    repeat
      if (THR32.th32ThreadID <> cThr) And (THR32.th32OwnerProcessID = Self.Id) then
      begin
        hOpen:= OpenThread($001F03FF, False, THR32.th32ThreadID);
        if hOpen = 0 then
          Exit;
        ResumeThread(hOpen);
        CloseHandle(hOpen);
      end;
    until not Thread32Next(hSnap, THR32);
    Result:= CloseHandle(hSnap);
  end;
end;

function Process.MainThread: DWORD64;
var
  dwMainThreadId: DWORD64;
  ullMinTime, ullTest: DWORD64;
  SSHandle: THandle;
  th32: THREADENTRY32;
  hThread: DWORD64;
  FT: Array [0..3] of TFileTime;
begin
  Result:= 0;
  dwMainThreadId:= 0;
  ullMinTime:= $7fffffffffffffff;
  SSHandle:= CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if (SSHandle <> INVALID_HANDLE_VALUE) then
	begin
    th32.dwSize:= SizeOf(THREADENTRY32);
    Thread32First(SSHandle, th32);
    while Thread32Next(SSHandle, th32) do
    begin
      if th32.th32OwnerProcessID = Self.Id then
      begin
        hThread:= OpenThread($0040, False, th32.th32ThreadID); // THREAD_QUERY_INFORMATION
        if hThread <> 0 then
        begin
          if GetThreadTimes(hThread, FT[0], FT[1], FT[2], FT[3]) then
          begin
            ullTest:= PDWORD64(@FT[0])^;
            if (ullTest < ullMinTime) then
            begin
              ullMinTime:= ullTest;
              dwMainThreadId:= th32.th32ThreadID;
            end;
          end;
        end;
        CloseHandle(hThread);
      end;
    end;
  end;
  if dwMainThreadID <> 0 then
    Result:= dwMainThreadId;
end;

function Process.ThreadStartAddress(th32ThreadID: DWORD64): Pointer;
var
  hThread : THandle;
  ThreadStartAddress : Pointer;
begin
  Result:= nil;
  hThread:= OpenThread(THREAD_QUERY_INFORMATION, False, th32ThreadID);
  if hThread = 0 then RaiseLastOSError;
  try
    if NtQueryInformationThread(hThread, ThreadQuerySetWin32StartAddress, @ThreadStartAddress, SizeOf(ThreadStartAddress), nil) = STATUS_SUCCESS then
      Result:= ThreadStartAddress
    else
      RaiseLastOSError;
  finally
    CloseHandle(hThread);
  end;
end;

end.
