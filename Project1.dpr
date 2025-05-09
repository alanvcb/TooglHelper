program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmToogl},
  Pkg.Json.DTO in 'Pkg.Json.DTO.pas',
  UTimeEntry in 'UTimeEntry.pas',
  UToogl in 'UToogl.pas',
  Rest in 'Rest.pas',
  ULog in 'ULog.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmToogl, frmToogl);
  Application.Run;
end.
