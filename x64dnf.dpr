program x64dnf;

uses
  Vcl.Forms,
  main in 'main.pas' {_},
  ProcessAPI in 'ProcessAPI.pas',
  MemAPI in 'MemAPI.pas',
  DirectInput8 in 'DirectInput8.pas',
  AOBScanAPI in 'AOBScanAPI.pas',
  Charicter in 'Charicter.pas',
  StrAPI in 'StrAPI.pas',
  BinaryMapping in 'BinaryMapping.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(T_, _);
  Application.Run;
end.
