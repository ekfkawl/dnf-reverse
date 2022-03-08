unit StrAPI;

interface

uses
  Winapi.Windows, System.SysUtils, StrUtils, System.Types;

//function itoa(Value: Integer; lpBuffer: AnsiString; Radix: Integer): PAnsiChar; stdcall external 'ntdll.dll' name '_itoa';
function sprintf(S: PAnsiChar; const Format: PAnsiChar): Integer; cdecl; varargs; external 'msvcrt.dll';
function IntToAnsiStr(X: Integer; Width: Integer = 0): AnsiString;
function StrCase(Selector: String; StrList: Array of String): Integer;
function Split(Source: String; Split: String; Num: Integer): String;
function strcmp(const SubStr, S: AnsiString): Boolean;
function RPos(SubStr: String; S: String): Integer;
function RandomString(PLen: Integer): String;
function AnsiStartsText(const ASubText, AText: string): Boolean;
function GetTextSize(Font: AnsiString; fHeight: Integer; Str: AnsiString): TSize;

implementation

function IntToAnsiStr(X: Integer; Width: Integer = 0): AnsiString;
begin
   Str(X: Width, Result);
end;

function StrCase(Selector: String; StrList: Array of String): Integer;
var
  i: Integer;
begin
  Result:= -1;
  for i:= 0 to High(StrList) do
    if Selector = StrList[i] then
    begin
      Result:= i;
      break;
    end;
end;

function Split(Source: String; Split: String; Num: Integer): String;
const
  MAXLENGTH = 255;
var
  Res: array[0..MaxLength] of String;
  i: Integer;
begin
  i:= 1;
  while AnsiPos(Split, Source) <> 0 do
  begin
    Res[i]:= Copy(Source, 1, AnsiPos(Split, Source) - 1);
    Delete(Source, 1, AnsiPos(Split, Source) + Length(Split) - 1);
    Inc(i);
  end;
  Res[i]:= Copy(Source, 1, Length(Source));
  Result:= Res[Num + 1];
end;


function RPos(SubStr: String; S: String): Integer;
var
  i: integer;
begin
  SubStr:= AnsiReverseString(SubStr);
  S:= AnsiReverseString(S);
  i:= Pos(SubStr, S);
  if i <> 0 then
    i:= (Length(S) + 1) - (i + Length(SubStr) - 1);
  Result := I;
end;

function RandomString(PLen: Integer): String;
const
  Str = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
begin
  Result:= '';
  Randomize;
  repeat
    Result:= Result + Str[Random(Length(Str)) + 1];
  until Length(Result) = PLen
end;

function strcmp(const SubStr, S: AnsiString): Boolean;
var
  i,
  len: DWORD;
begin
  Result:= True;
  len:= Length(SubStr);
  if (len <> 0) And (Length(S) <> 0) then
    for i:= 0 to len - 1 do
      if PByte(DWORD64(SubStr) + i)^ <> PByte(DWORD64(S) + i)^ then
      begin
        Result:= False;
        break;
      end;
end;

function AnsiStartsText(const ASubText, AText: string): Boolean;
var
{$IFDEF MSWINDOWS}
  P: PChar;
{$ENDIF}
  L, L2: Integer;
begin
{$IFDEF MSWINDOWS}
  P := PChar(AText);
{$ENDIF}
  L := Length(ASubText);
  L2 := Length(AText);
  if L > L2 then
    Result := False
  else
{$IFDEF MSWINDOWS}
    Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE,
      P, L, PChar(ASubText), L) = 2;
{$ENDIF}
{$IFDEF POSIX}
    Result := SameText(ASubText, Copy(AText, 1, L));
{$ENDIF}
end;

function GetTextSize(Font: AnsiString; fHeight: Integer; Str: AnsiString): TSize;
var
  f: HFONT;
  dc: HDC;
  textSize: TSize;
  saveFont: HFont;
begin
  f:= CreateFont(fHeight, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_NATURAL_QUALITY, DEFAULT_PITCH or FF_DONTCARE, PWideChar(String(Font)));
  dc:= GetDC(0);
  saveFont:= Winapi.Windows.SelectObject(dc, f);
  GetTextExtentPoint32(dc, String(Str), Length(String(Str)), textSize);
  Winapi.Windows.SelectObject(dc, saveFont);
  Result.cx:= textSize.cx;
  Result.cy:= textSize.cy;
  ReleaseDC(0, dc);
  DeleteObject(f);
end;


{
function strcmp(const SubStr, S: AnsiString): Boolean; stdcall;
var
  pSubStr, pS: ^AnsiString;
  len, count: DWORD;
begin
  Result:= False;
  pSubStr:= @SubStr;
  pS:= @S;
  len:= Length(SubStr);
  if (len = 0) Or (Length(S) = 0) then Exit;
  asm
    pushad
    mov esi, [pSubStr]
    mov esi, [esi]
    mov edi, [pS]
    mov edi, [edi]

    mov ecx, [len]
    inc ecx
    repe cmpsb
    mov [count], ecx
    popad
  end;
  Result:= count = 0;
end;
}
end.
