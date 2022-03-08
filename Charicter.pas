unit Charicter;

interface
  uses SysUtils, Windows, TlHelp32, PsAPI, MemAPI, StrAPI;

type TVector3 = packed record
  x, y, z: Single;
end;

type TIVector3 = packed record
  x, y, z: Integer;
end;

type TObjectList = record
  _u0: Array [1..$10] of Byte; {0x0}
  entryBase: DWORD64; {0x10}
  sz: DWORD64; {0x18}
end;

type TCharicter = packed record
  _u0: Array [1..$168] of Byte;
  pDirection: DWORD64; {0x168}
  _u1: Array [1..$10] of Byte; {0x170}
  pList: ^TObjectList; {0x180}
  _u2: Array [1..$18] of Byte; {0x188}
  pMotion: Pointer; {0x1A0}
  _u3: Array [1..$180] of Byte; {0x1A8}
  _Position: ^TVector3; {0x328}
  _u4: Array [1..$220] of Byte; {0x330}
  dMotion: DWORD64; {0x550}
  _u5: Array [1..$8A8] of Byte; {0x558}
  Team: DWORD; {0xE00}
  _u5_1: Array [1..$234] of Byte; {0xE04}
  isSuperArmor1: Boolean; {0x1038}
  _u6: Array [1..$2B8F] of Byte; {0x1039}
  pMStand: Pointer; {0x3BC8}
  _u7: Array [1..8] of Byte; {0x3BD0}
  pMWalk: Pointer; {0x3BD8}
  _u8: Array [1..$18] of Byte; {0x3BE0}
  pMDash: Pointer; {0x3BF8}
  _u9: Array [1..$18] of Byte; {0x3C00}
  pMQuick: Pointer; {0x3C18}
  _uA: Array [1..$18] of Byte; {0x3C20}
  pMHited1: Pointer; {0x3C38}
  _uB: Array [1..8] of Byte; {0x3C40}
  pMHited2: Pointer; {0x3C48}
  _uC: Array [1..8] of Byte; {0x3C50}
  pMDown: Pointer; {0x3C58}
  _uD: Array [1..$924] of Byte; {0x3C60}
  comDamage: DWORD64; {0x4584}
  _uE: Array [1..$37C] of Byte; {0x458C}
  isNohit: Boolean; {0x4908}
  _uF: Array [1..$6C7] of Byte; {0x4909}
  currentHP: DWORD64; {0x4FD0}
  _u10: Array [1..$5F8] of Byte; {0x4FD8}
  Name: Array [0..31] of WideChar; {0x55D0}
  _u11: Array [1..$27C] of Byte; {0x5610}
  ctype: DWORD; {0x588C}
  _u12: Array [1..$37B0] of Byte; {0x5890}
  skillKey: DWORD64; {0x9040}

  const LEFT = 0;
  const RIGHT = 1;
  function Direction: Byte;
  function Position: TVector3;
  function ObjectList: TObjectList;
  function isCharicter: Boolean;
end;


function MapCharicter(const dwBase: DWORD64): TCharicter; overload;
function MapCharicter: TCharicter; overload;

implementation
  uses Main;

function MapCharicter(const dwBase: DWORD64): TCharicter; overload;
var
  res: TCharicter;
begin
  if not ReadProcessMemory(hProcess, Ptr(dwBase), @res, SizeOf(TCharicter), PSIZE_T(nil)^) then
    raise EAbort.Create('')
  else
    Result:= res;
end;

function MapCharicter: TCharicter; overload;
var
  res: TCharicter;
begin
  if not ReadProcessMemory(hProcess, Ptr(rd4(dwLocal)), @res, SizeOf(TCharicter), PSIZE_T(nil)^) then
    raise EAbort.Create('')
  else
    Result:= res;
end;


function TCharicter.Direction: Byte;
begin
  Result:= rd1(rd4(Self.pDirection + 8) + $68);
end;


function TCharicter.Position: TVector3;
var
  res: TVector3;
begin
  if ReadProcessMemory(hProcess, Ptr(DWORD(Self._Position)), @res, SizeOf(TVector3), PSIZE_T(nil)^) then
    Result:= res
  else
    raise EAbort.Create('');
end;

function TCharicter.ObjectList: TObjectList;
var
  res: TObjectList;
begin
  if ReadProcessMemory(hProcess, Ptr(DWORD(Self.pList)), @res, SizeOf(TObjectList), PSIZE_T(nil)^) then
    Result:= res
  else
    raise EAbort.Create('');
end;

function TCharicter.isCharicter: Boolean;
begin
  Result:= False;
  case StrCase(Self.Name, ['Swordman', 'ATSwordman', 'DSSwordman', 'Mage', 'ATMage', 'Gunner', 'ATGunner', 'Fighter', 'ATFighter', 'Priest', 'ATPriest', 'Thief', 'Knight', 'DemonicLancer', 'GunBlader']) of
    0..14:
    begin
      Result:= True;
    end;
  end;
end;

function Enemy: DWORD64;
var
  local, enemy: TCharicter;
begin
  local:= MapCharicter;
  if local.pList <> nil then
  begin
    const entity = local.ObjectList.entryBase;
    const size = (local.ObjectList.sz - entity) shr 2;

    for var i:= 0 to size do
    begin
      try
        const enemyBase = entity + i * 8;
        enemy:= MapCharicter(enemyBase);

        if (enemyBase <> rd4(dwLocal)) And (enemy.Team <> local.Team) And (enemy.isCharicter) then
        begin
          Result:= enemyBase;
          Exit;
        end;
      except;
      end;
    end;
  end;
  Result:= 0;
end;
end.
