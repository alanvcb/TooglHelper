program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmToogl},
  Pkg.Json.DTO in 'Pkg.Json.DTO.pas',
  TimeEntry in 'TimeEntry.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmToogl, frmToogl);
  Application.Run;
end.
