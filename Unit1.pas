unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.NetEncoding, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, UTimeEntry, System.ImageList, Vcl.ImgList,REST.Client, REST.Types;

const ConfFile = 'toogl.conf';

type
  TfrmToogl = class(TForm)
    ImageList1: TImageList;
    pgcToogl: TPageControl;
    tshConfig: TTabSheet;
    tshDados: TTabSheet;
    tshDebug: TTabSheet;
    edtWorkspace: TButtonedEdit;
    Label2: TLabel;
    edtApiKey: TEdit;
    Label1: TLabel;
    btnSaveConfig: TButton;
    mmLog: TRichEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure edtWorkspaceRightButtonClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
    Ativou: Boolean;
    procedure LoadConfig;
    procedure SaveConfig;
  public
  procedure getRest(out AClient: TRESTClient; out ARequest: TRESTRequest;
  out AResponse: TRESTResponse;AAPIKey: String);
  function getWorkSpace(AAPIKey: string): string;
  procedure GetTogglEntries(AAPIKey: string; ADate: TDateTime);
  procedure SetTogglEntries(AAPIKey, AWorkSpaceID: string;TimeEntrys: TTimeEntryList);
    { Public declarations }
  end;

var
  frmToogl: TfrmToogl;

implementation

{$R *.dfm}

{ TForm1 }

uses  System.JSON, ULog;

procedure TfrmToogl.btnSaveConfigClick(Sender: TObject);
begin
  SaveConfig;
end;

procedure TfrmToogl.Button1Click(Sender: TObject);
begin
  GetTogglEntries('29c0db61244940fc192f41c2750c3b07',StrToDate('17/04/2025'))
end;

procedure TfrmToogl.Button2Click(Sender: TObject);
begin
  SetTogglEntries('29c0db61244940fc192f41c2750c3b07','1795011',nil);
end;

procedure TfrmToogl.edtWorkspaceRightButtonClick(Sender: TObject);
begin
  if edtApiKey.Text <> '' then
    edtWorkspace.Text := getWorkSpace(edtApiKey.Text);
end;

procedure TfrmToogl.FormActivate(Sender: TObject);
begin
  if not Ativou then
  begin
    Log.LogDest :=  mmLog;
    LoadConfig;
    Ativou := True;
  end;
end;

procedure TfrmToogl.FormCreate(Sender: TObject);
begin
  Ativou := False;
end;

procedure TfrmToogl.getRest(out AClient: TRESTClient; out ARequest: TRESTRequest;
  out AResponse: TRESTResponse;AAPIKey: String);
begin
  AClient := TRESTClient.Create(nil);
  ARequest := TRESTRequest.Create(nil);
  AResponse := TRESTResponse.Create(nil);

  // Configura o cliente REST
  AClient.BaseURL := 'https://api.track.toggl.com/api/v9/me/time_entries';
  AClient.Authenticator := nil;

  // Configura a requisição
  ARequest.Client := AClient;
  ARequest.Response := AResponse;

  // Adiciona a autenticação básica (API Key)
  ARequest.AddAuthParameter('Authorization', 'Basic ' +
    TNetEncoding.Base64.Encode(AAPIKey + ':api_token'), pkHTTPHEADER, [poDoNotEncode]);
end;

procedure TfrmToogl.GetTogglEntries(AAPIKey: string; ADate: TDateTime);
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  StartDate, EndDate: string;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  i: Integer;
begin
  try
  // Configura os componentes REST
   getRest(RestClient,RestRequest,RestResponse,AAPIKey);
   RestRequest.Method := rmGET;

    // Formata as datas no formato ISO 8601
    StartDate := FormatDateTime('yyyy-mm-dd', ADate) + 'T00:00:00+00:00';
    EndDate := FormatDateTime('yyyy-mm-dd', ADate) + 'T23:59:59+00:00';

    // Adiciona os parâmetros de data à requisição
    RestRequest.AddParameter('start_date', StartDate, pkQUERY);
    RestRequest.AddParameter('end_date', EndDate, pkQUERY);

    // Executa a requisição
    RestRequest.Execute;

    // Verifica se a resposta foi bem-sucedida
    if RestResponse.StatusCode = 200 then
    begin
      // Parseia a resposta JSON
      JSONArray := TJSONObject.ParseJSONValue(RestResponse.Content) as TJSONArray;
      try
        if Assigned(JSONArray) then
        begin
          for i := 0 to JSONArray.Count - 1 do
          begin
            JSONObject := JSONArray.Items[i] as TJSONObject;
            // Exibe os dados das entradas (ajuste conforme necessário)
          {  EscreveLN('Description: ' + JSONObject.GetValue('description').Value);
            EscreveLN('Start: ' + JSONObject.GetValue('start').Value);
            EscreveLN('End: ' + JSONObject.GetValue('stop').Value);
            EscreveLN('Duration: ' + JSONObject.GetValue('duration').Value);}
            log.LogTrace(JSONObject.ToString);


          end;
        end
        else
        begin
          Log.LogWarning('Nenhuma entrada encontrada para o dia especificado.');
        end;
      finally
        JSONArray.Free;
      end;
    end
    else
    begin
      Log.LogError('Erro na requisição: ' + RestResponse.StatusText);
    end;
  finally
    // Libera os componentes
    RestClient.Free;
    RestRequest.Free;
    RestResponse.Free;
  end;
end;

function TfrmToogl.getWorkSpace(AAPIKey: string): string;
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
begin
  try
    log.LogTrace('Finding workspace id...');
    getRest(RestClient,RestRequest,RestResponse,AAPIKey);
    RestRequest.Method := rmGET;
    // Configura o cliente REST
    RestClient.BaseURL := 'https://api.track.toggl.com/api/v9/me/workspaces';
    RestClient.Authenticator := nil;

    log.LogTrace('Executing rest requisition');
    RestRequest.Execute;

    if RestResponse.StatusCode = 200 then
    begin
      // Parseia a resposta JSON
      JSONArray := TJSONObject.ParseJSONValue(RestResponse.Content) as TJSONArray;
      try
        if Assigned(JSONArray) then
        begin
          JSONObject := JSONArray.Items[0] as TJSONObject;
          Result := JSONObject.Values['id'].ToString;
        end;
      finally
        JSONArray.Free;
      end;
    end;
  finally
    RestClient.Free;
    RestRequest.Free;
    RestResponse.Free;
  end;
end;

procedure TfrmToogl.LoadConfig;
var config: TJSONObject;
load: TStringStream;
begin
  if FileExists(ConfFile) then
  begin
    log.LogTrace('Loading config...');
    load := TStringStream.Create;
    try
      load.LoadFromFile(ConfFile);
      config := TJSONObject.ParseJSONValue(load.DataString) as TJSONObject;
      try
        edtApiKey.Text := config.Values['api_key'].AsType<string>;
        edtWorkspace.Text := config.Values['workspace_id'].AsType<string>;
      finally
        config.Free;
      end;
    finally
      load.Free;
    end;
  end;
end;

procedure TfrmToogl.SaveConfig;
var config: TJSONObject;
save: TStringStream;
begin
  config := TJSONObject.Create;
  try
    log.LogTrace('Saving Config...');
    config.AddPair('api_key',edtApiKey.Text);
    config.AddPair('workspace_id',edtWorkspace.Text);
    save := TStringStream.Create(config.ToString,TEncoding.UTF8,False);
    try
      save.SaveToFile(ConfFile);
      log.LogTrace('Save config: '+ConfFile);
    finally
      save.Free;
    end;
  finally
    config.Free;
  end;
end;

procedure TfrmToogl.SetTogglEntries(AAPIKey, AWorkSpaceID: string;TimeEntrys: TTimeEntryList);
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  JSONObject: TJSONObject;
  i: Integer;
begin
  try
     getRest(RestClient,RestRequest,RestResponse,AAPIKey);
     RestRequest.Method := rmGET;
    // Configura o cliente REST
    RestClient.BaseURL := 'https://api.track.toggl.com/api/v9/workspaces/'+AWorkSpaceID+'/time_entries';
    RestClient.Authenticator := nil;

    for I := 0 to TimeEntrys.Count -1 do
    begin
      RestRequest.Body.ClearBody;
      RestRequest.AddBody(TimeEntrys[i].AsJson,'application/json');

      // Executa a requisição
      RestRequest.Execute;

      // Verifica se a resposta foi bem-sucedida
      if RestResponse.StatusCode = 200 then
      begin
        // Parseia a resposta JSON
        JSONObject := TJSONObject.ParseJSONValue(RestResponse.Content) as TJSONObject;
        try
           if Assigned(JSONObject) then
           begin
                log.LogMessage(JSONObject.ToString);
           end;
        finally
          JSONObject.Free;
        end;
      end
      else
      begin
        log.LogError('Erro na requisição: ' + RestResponse.Content);
      end;
    end;
  finally
    // Libera os componentes
    RestClient.Free;
    RestRequest.Free;
    RestResponse.Free;
  end;

end;

end.



