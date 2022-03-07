unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ProcessAPI, Vcl.StdCtrls, DirectInput8, AOBScanAPI, Charicter, MemAPI;

type
  T_ = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
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

  swQuickKey: Boolean = True;
  swAutoDash: Boolean = True;

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
var
  local: TCharicter;
begin
  while True do
  begin
    Sleep(1);
    try
      if not IsActiveWindow then
        Continue;

      local:= MapCharicter;

      // ÄüÅ°
      if (swQuickKey) And (GetKeyStateEx(Ord('X'))) then
      begin
        Inoutput(DirectInput8.X);
      end;

      // ´ë½Ã
      if (swAutoDash) And (GetKeyStateEx(VK_SHIFT)) then
      begin
        Output(DirectInput8.SHIFT);
        if local.pMotion = local.pMWalk then
        begin
          var sink:= False;
          if (GetKeyStateEx(VK_LEFT)) And (not GetKeyStateEx(VK_RIGHT)) And (local.Direction = local.LEFT) then
          begin
            Outinput(DirectInput8.LEFT);
            sink:= True;
          end;
          if (GetKeyStateEx(VK_RIGHT)) And (not GetKeyStateEx(VK_LEFT)) And (local.Direction = local.RIGHT) then
          begin
            Outinput(DirectInput8.RIGHT);
            sink:= True;
          end;

          if sink then
          begin
            if local.pMotion <> local.pMDash then
              Continue;
          end;

          if not GetKeyStateEx(VK_LEFT) then
            Output(DirectInput8.LEFT)
          else if not GetKeyStateEx(VK_RIGHT) then
            Output(DirectInput8.RIGHT);
        end;

      end;
    except;
    end;

  end;
end;

procedure T_.CheckBox1Click(Sender: TObject);
begin
  swQuickKey:= CheckBox1.Checked;
end;

procedure T_.CheckBox2Click(Sender: TObject);
begin
  swAutoDash:= CheckBox2.Checked;
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

  CreateThread(@Callback1);
end;

end.
