unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ProcessAPI, Vcl.StdCtrls, DirectInput8, AOBScanAPI, Charicter, MemAPI, BinaryMapping,
  SkillHook, Generics.Collections, iniFiles;

type
  T_ = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type TIniDate = record
  key, value: String;
end;

var
  _: T_;
  p: Process;
  hProcess, hWindow: THandle;

  dwCBase, dwVBase,
  dwLocal, dwSkillHook: DWORD64;

  swQuickKey: Boolean = false;
  swAutoDash: Boolean = false;
  swSkillCool: Boolean = true;

  function IsInGame: Boolean;
  procedure GetEnemySkillCoolList;

implementation

{$R *.dfm}

uses D110verlay;



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

procedure IniWrite(v: TList<TIniDate>);
var
  ini: TiniFile;
begin
  ini:= TiniFile.Create('C:\df.ini');
  if v.Count = 0 then
    Exit;

  while v.Count > 0 do
  begin
    ini.WriteString('Hash', v.First.key, v.First.value + ',' + GetTickCount.ToString);
    v.Delete(0);
  end;

  ini.Free;
end;

function IniRead: TStringList;
var
  ini: TiniFile;
  buf: TStringList;
begin
  ini:= TiniFile.Create('C:\df.ini');

  buf:= TStringList.Create;
  ini.ReadSectionValues('Hash', buf);
  Result:= buf;
end;

function IsInGame: Boolean;
begin
  Result:= True;
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

      // quick key
      if (swQuickKey) And (GetKeyStateEx(Ord('X'))) then
      begin
        Inoutput(DirectInput8.X);
      end;

      // auto dash
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

procedure GetEnemySkillCoolList;
var
  v: TStringList;
  val: TArray<string>;
begin
  v:= IniRead;
  if v.Count > 0 then
  begin

    const drawX = 120;
    const drawY = 800;
    const tabspace = 20;


    var j:= 0;
    for var i:= 0 to v.Count - 1 do
    begin
      var key:= v.Names[i];
      val:= v.ValueFromIndex[i].Split([',']);
      var cool:= val[0];
      var color:= val[1];
      var tick:= val[2];

      if GetTickCount - tick.ToInteger < 1000 then
      begin
        DrawOutlineCenterText(fHead, drawX, drawY + j * tabspace, $FFFFFFFF, key);
        DrawOutlineCenterText(fHead, drawX + 200, drawY + j * tabspace, $FF00FF00, cool);
        Inc(j);
      end;

    end;


  v.Free;
  end;

end;

procedure Callback2;
begin
  while True do
  begin
    try
      Sleep(900);
      if swSkillCool then
        D110verlay.Render;
    except;
    end;
  end;
end;

procedure T_.Button1Click(Sender: TObject);
begin
  caption:= IniRead.Names[0] + IniRead.ValueFromIndex[0];
end;

procedure T_.CheckBox1Click(Sender: TObject);
begin
  swQuickKey:= CheckBox1.Checked;
end;

procedure T_.CheckBox2Click(Sender: TObject);
begin
  swAutoDash:= CheckBox2.Checked;
end;


procedure T_.CheckBox3Click(Sender: TObject);
begin
  swSkillCool:= CheckBox3.Checked;
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

  dwSkillHook:= AOBSCAN('E8 ?? ?? ?? ?? 48 3B C7 75 0D BA 06 00 00 00 48 8B CF E8', 0);
end;

procedure T_.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  var str:= 'Notepad';
  EnumWindows(@TerminateOverlay, DWORD(str));
end;

procedure T_.FormCreate(Sender: TObject);
begin
  p.GetProcessId('DNF.exe');
  if p.Id = 0 then
  begin
    showmessage('process not find');
    Exit;
  end;

  hProcess:= OpenProcess(PROCESS_ALL_ACCESS, False, p.Id);
  hWindow:= FindWindow(nil, 'Dungeon & Fighter');

//  dwCBase:= p.GetModuleBase('DNF.exe');
//  dwVBase:= MapInitialize(dwCBase);
//
//  SetVariablesWithAOBScan;
//
//
//  SkillHook.Init;

  D110verlay.hTarget:= hWindow;
  f:= False;
  w:= False;
  ShellOverlayAndHijac(False);

//  CreateThread(@Callback1);
  CreateThread(@Callback2);
end;

end.
