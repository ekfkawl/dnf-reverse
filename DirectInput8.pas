unit DirectInput8;

interface

uses
  SysUtils, Windows, MemAPI;

const
  N1 = 2;
  N2 = 3;
  CAPTICAL = $3A;
  CTRL = $1D;
  TAB = $F;
  Q = $10;
  W = $11;
  E = $12;
  R = $13;
  T = $14;
  Y = $15;
  A = $1E;
  S = $1F;
  D = $20;
  F = $21;
  G = $22;
  H = $23;
  Z = $2C;
  X = $2D;
  C = $2E;
  V = $2F;
  B = $30;
  LEFT = $CB;
  RIGHT = $CD;
  UP = $C8;
  DOWN = $D0;
  SHIFT = $2A;
  ALT = $38;
  SPACE = $39;
  Key: Array [0..18] of DWORD = (CTRL, Q, W, E, R, T, Y, A, S, D, F, G, H, Z, X, C, V, B, SHIFT);

var
  dwEntry: DWORD64 = $3D160;
  dwdInput8Base: DWORD64 = 0;

procedure Input(const Key: DWORD);
procedure Output(const Key: DWORD);
procedure Inoutput(const Key: DWORD);
procedure Outinput(const Key: DWORD);

implementation

uses Main;

function GetDInput8Base: DWORD64;
begin
  if dwdInput8Base = 0 then
  begin
    dwdInput8Base:= p.GetModuleBase('DINPUT8.dll');
  end;
  Result:= dwdInput8Base;
end;

procedure Input(const key: DWORD);
begin
  wd1(GetDInput8Base + dwEntry + key, $80);
end;

procedure Output(const key: DWORD);
begin
  wd1(GetDInput8Base + dwEntry + key, 0);
end;

procedure Inoutput(const key: DWORD);
begin
  Input(key);
  Sleep(10);
  Output(key);
  Sleep(10);
end;

procedure Outinput(const key: DWORD);
begin
  Output(key);
  Sleep(10);
  Input(key);
  Sleep(10);
end;
end.
