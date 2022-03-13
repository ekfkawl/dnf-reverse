unit FileAPI;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.ExtActns, Winapi.ShellAPI, System.StrUtils,VMProtectSDK, StrAPI;

function IsFileInUse(const fName: String): Boolean;
function FileDownload(const sURL, sLocalFileName: String): Boolean;
function RunAs(const p_str: String; Param: String = ''): Boolean;
function DeleteExtension: AnsiString;
procedure DeleteFileEx(const Path: String);
procedure WaitForClose(Param: String);

implementation

function IsFileInUse(const fName: String): Boolean;
var
  HFileRes: HFILE;
begin
  Result:= False;
  if not FileExists(fName) then
    Exit;
  HFileRes:= CreateFile(pchar(fName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result:= (HFileRes = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(HFileRes);
end;

procedure DeleteFileEx(const Path: String);
var
  TFile: TextFile;
  ReName: String;
begin
  VMProtectBeginMutation('DeleteFileEx');
  if FileExists(Path) then
  begin
    try
      ReName:= GetEnvironmentVariable(VMProtectDecryptStringW('HOMEDRIVE')) + VMProtectDecryptStringW('\새 텍스트 문서.txt');
      RenameFile(Path, ReName);
      AssignFile(TFile, ReName);
      Rewrite(TFile);
      Writeln(TFile, '');
      CloseFile(TFile);
      DeleteFile(PWideChar(ReName));
    except;
    end;
  end;
  VMProtectEnd;
end;

function FileDownload(const sURL, sLocalFileName: String): Boolean;
begin
  with TDownLoadURL.Create(nil) do
  try
    URL:= sURL;
    Filename:= sLocalFileName;
    try
      ExecuteTarget(nil);
    except
      //Result:= False;
    end;
  finally
    Free;
    Result:= FileExists(sLocalFileName);
  end;
end;

function RunAs(const p_str: String; Param: String = ''): Boolean;
var
  shExecInfo: SHELLEXECUTEINFO;
begin
  shExecInfo.cbSize:= SizeOf(SHELLEXECUTEINFO);
  shExecInfo.fMask        := 0;
  shExecInfo.wnd          := 0;
  shExecInfo.lpVerb       := PWideChar('runas') ;
  shExecInfo.lpFile       := PWideChar(WideString(p_str));
  shExecInfo.lpParameters := PWideChar(WideString(Param));
  shExecInfo.lpDirectory  := nil;
  shExecInfo.nShow        := SW_HIDE;
  shExecInfo.hInstApp     := 0 ;
  Result:= ShellExecuteEx(@shExecInfo);
end;

procedure WaitForClose(Param: String);
var
  proc_info: TProcessInformation;
  startinfo: TStartupInfo;
begin
  Param:= Trim(Param);
  FillChar(proc_info, SizeOf(TProcessInformation), 0);
  FillChar(startinfo, SizeOf(TStartupInfo), 0);
  startinfo.cb:= sizeof(TStartupInfo);
  if CreateProcess(nil, PWideChar(Param), nil, nil, False, CREATE_NO_WINDOW, nil, nil, startinfo, proc_info) then
  begin
    WaitForSingleObject(proc_info.hProcess, INFINITE);
    CloseHandle(proc_info.hProcess);
    CloseHandle(proc_info.hThread);
  end;
end;


function DeleteExtension: AnsiString;
var
  FullPath: Array [0..MAX_PATH - 1] of Char;
  Path: String;
begin
  VMProtectBeginMutation('DeleteExtension');
  GetModuleFileName(hInstance, FullPath, MAX_PATH);
  Path:= Copy(FullPath, 1, RPos('\', FullPath));
  RenameFile(FullPath, Path + RandomString(10));
  Result:= '';
  //Result:= AnsiString(Copy(FullPath, RPos('\', FullPath) + 1, Length(FullPath)));
  VMProtectEnd;
end;



end.
