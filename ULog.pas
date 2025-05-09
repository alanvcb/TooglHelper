unit ULog;

interface

uses
  Vcl.ComCtrls, System.SysUtils, Vcl.Graphics;

type TLogger = class
  private
    FLogDest: TRichEdit;
    procedure AddColoredLine(const Text: string; Color: TColor);
  public
    property LogDest: TRichEdit read FLogDest write FLogDest;
    procedure LogMessage(AMessage: string);
    procedure LogError(AError: string); overload;
    procedure LogError(AError: Exception); overload;
    procedure LogWarning(AWarning: String);
    procedure LogTrace(ATrace: string);
end;

var Log: TLogger;

implementation

uses
  Vcl.Dialogs;

{ TLogger }

procedure TLogger.LogError(AError: string);
begin
  AddColoredLine(AError,clRed);
end;

procedure TLogger.AddColoredLine(const Text: string; Color: TColor);
begin
  if Assigned(FLogDest) then
  begin
    FLogDest.SelStart := FLogDest.GetTextLen; // Move para o fim do texto
    FLogDest.SelLength := 0; // Garante que nada está selecionado
    FLogDest.SelAttributes.Color := Color; // Define a cor da fonte
    FLogDest.Lines.Add(Text); // Adiciona a linha com a cor especificada
  end
  else
    ShowMessage(Text);
end;

procedure TLogger.LogError(AError: Exception);
begin
  LogError(AError.Message);
end;

procedure TLogger.LogMessage(AMessage: string);
begin
  AddColoredLine(AMessage,clWhite);
end;

procedure TLogger.LogTrace(ATrace: string);
begin
  AddColoredLine(ATrace,clAqua);
end;

procedure TLogger.LogWarning(AWarning: String);
begin
  AddColoredLine(AWarning,clYellow);
end;


initialization
  Log := TLogger.Create;

finalization
  Log.Free;

end.
