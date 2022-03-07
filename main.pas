unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ProcessAPI, Vcl.StdCtrls, DirectInput8, AOBScanAPI, Charicter, MemAPI;

type
  T_ = class(TForm)
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  _: T_;
  p: Process;
  hProcess, hWindow: THandle;

  dwCBase,
  dwLocal: DWORD64;

  swQuickKey: Boolean;

implementation

{$R *.dfm}

function CreateThread(lpStartAddress: Pointer): THandle;
begin
  Result:= Winapi.Windows.CreateThread(nil, 0, lpStartAddress, nil, 0, PDWORD(nil)^);
  CloseHandle(Result);
end;

function GetKeyStateEx(vKey: Integer): Boolean;
begin
  Result:= GetKeyState(vKey) And $8000 <> 0;
end;

function IsActiveWindow: Boolean;
begin
  Result:= GetForegroundWindow = hWindow;
end;

procedure Callback1;
begin
  while True do
  begin
    Sleep(1);
    if not IsActiveWindow then
      Continue;

    if (swQuickKey) And (GetKeyStateEx(Ord('X'))) then
    begin
      Inoutput(DirectInput8.X);
    end;
  end;
end;

procedure T_.CheckBox1Click(Sender: TObject);
begin
  swQuickKey:= CheckBox1.Checked;
end;

procedure SetVariablesWithAOBScan;
var
  t: DWORD64;
begin
  ScanStructure.hProcess:= hProcess;
  ScanStructure.StartAddr:= dwCBase;
  ScanStructure.EndAddr:= dwCBase + p.GetModuleSize(dwCBase);

  t:= AOBSCAN('48 8B 05 ?? ?? ?? ?? 48 85 C9 48 0F 45 C1', 0);
  dwLocal:= t + rd4(t + 3) + 7;
end;

procedure T_.FormCreate(Sender: TObject);
begin

  p.GetProcessId('DNF.exe');

  hProcess:= OpenProcess(PROCESS_ALL_ACCESS, False, p.Id);
  hWindow:= FindWindow(nil, 'Dungeon & Fighter');

  dwCBase:= p.GetModuleBase('DNF.exe');

  SetVariablesWithAOBScan;

  caption:= MapCharicter.Direction.ToString;



  CreateThread(@Callback1);
end;

end.
