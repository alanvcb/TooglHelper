unit Rest;

interface

uses System.JSON,REST.Client,System.Generics.Collections,IPPeerClient,
  System.Classes, REST.Types;


type
  TVerbo = (vPost, vPut, vGet, vDelete, vPatch);
  TParamType = (ptURL,ptHeader,ptGetPost,ptQuery);

type
  TStatusExecucao = record
    StatusCode: Integer;
    Status, ErrorMessage: string;
  end;


Type TRest = class
  strict private
    iRequest: TRESTRequest;
    iResponse: TRESTResponse;
    iClient: TRESTClient;
  private
    FBody: TJsonValue;
    FVerbo: TVerbo;
    FResource: String;
    FBaseUrl: String;
    FURLParams: String;
    FResourceParamsSeparator: String;
    FContentType: string;
    FStatus: TStatusExecucao;
    FResultado: String;
    FHeaders: TStrings;
    FContentResponse: String;
    FResultadoJson: TJSONValue;
    procedure SetBaseUrl(const Value: String);
    procedure SetBody(const Value: TJsonValue);
    procedure SetResource(const Value: String);
    procedure SetVerbo(const Value: TVerbo);
    procedure SetContentType(const Value: string);
    procedure SetResultado(const Value: String);
    procedure SetStatus(const Value: TStatusExecucao);
    function TrataScape(Json: String): String;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure AddParams(ANome, AValor: String;
      ATipo: TParamType;Encode: Boolean = False);
    property BaseUrl: String read FBaseUrl write SetBaseUrl;
    property Resource: String read FResource write SetResource;
    property Verbo: TVerbo read FVerbo write SetVerbo;
    property Body: TJsonValue read FBody write SetBody;
    property ContentType: string read FContentType write SetContentType;
    property ContentResponse: String read FContentResponse;
    property Resultado: String read FResultado write SetResultado;
    property ResultadoJson: TJSONValue read FResultadoJson write FResultadoJson;
    property HeadersResponse: TStrings read FHeaders;
    property Status: TStatusExecucao read FStatus write SetStatus;
    procedure ClearBodyParams;
    function Execute: TStatusExecucao;

end;


implementation

uses System.SysUtils, REST.HttpClient;

{ TRest }

procedure TRest.AddParams(ANome, AValor: String;
  ATipo: TParamType;
  Encode: Boolean);
var ParamKind: TRESTRequestParameterKind;
  Options: TRESTRequestParameterOptions;
begin
  if Encode then
    Options := []
  else
    Options := [poDoNotEncode];

  // Converter TParamType para TRESTRequestParameterKind

  case ATipo of
    ptURL: ParamKind := TRESTRequestParameterKind.pkURLSEGMENT;
    ptHeader: ParamKind := TRESTRequestParameterKind.pkHTTPHEADER;
    ptGetPost: ParamKind := TRESTRequestParameterKind.pkGETorPOST;
    ptQuery : ParamKind := TRESTRequestParameterKind.pkQUERY;
  else
    ParamKind := TRESTRequestParameterKind.pkREQUESTBODY;
  end;

  iRequest.AddParameter(ANome, AValor, ParamKind, Options);
end;

procedure TRest.ClearBodyParams;
begin
  if Assigned(FBody) then
    FBody.DisposeOf;
  FBody := nil;
end;

constructor TRest.Create;
begin
  inherited Create;
  iClient := TRESTClient.Create(nil);
  iResponse := TRESTResponse.Create(nil);
  iRequest := TRESTRequest.Create(nil);

  iResponse.Name := 'Response';

  iRequest.Name := 'Request';
  iRequest.HandleRedirects := False;
  iRequest.Client := iClient;
  iRequest.Response := iResponse;
  iRequest.SynchronizedEvents := False;

  iClient.Name := 'Client';
  iClient.Accept := '*/*';
  iClient.AcceptCharset := 'UTF-8, *;q=0.8';
  iClient.HandleRedirects := False;

  FResourceParamsSeparator := '/';
  FBody := nil;
  FResultadoJson := nil;
  FHeaders := TStringList.Create;
end;

destructor TRest.Destroy;
begin
  iClient.DisposeOf;
  iRequest.DisposeOf;
  iResponse.DisposeOf;
  ClearBodyParams;
  FHeaders.Free;
  inherited Destroy;
end;

function TRest.Execute: TStatusExecucao;
var
  parametro: string;
  JsonBody: TStringStream;
begin
  try
    try
      JsonBody := nil;
      FStatus.StatusCode := 0;
      FStatus.Status := '';
      FStatus.ErrorMessage := '';

      iClient.BaseURL := BaseUrl;
      iClient.ContentType := FContentType;
      iRequest.Resource := Resource;

      case Verbo of
        vPost:   iRequest.Method := TRESTRequestMethod.rmPOST;
        vPut:    iRequest.Method := TRESTRequestMethod.rmPUT;
        vGet:    iRequest.Method := TRESTRequestMethod.rmGET;
        vDelete: iRequest.Method := TRESTRequestMethod.rmDELETE ;
        vPatch : iRequest.Method := TRESTRequestMethod.rmPATCH;
      end;

      if Assigned(Body) then
      begin
        JsonBody := TStringStream.Create(Body.ToString,TEncoding.UTF8);
        iRequest.AddBody(TrataScape(JsonBody.DataString),ctAPPLICATION_JSON);
      end;

      iRequest.Execute;

      if Assigned(iResponse.JSONValue) then
      begin
        ResultadoJson := iResponse.JSONValue;
        Resultado := ResultadoJson.Value;
      end;

      FHeaders.Text := iResponse.Headers.Text;
      FContentResponse := iResponse.Content;

      FStatus.StatusCode := iResponse.StatusCode;
      FStatus.Status := iResponse.StatusText;
      FStatus.ErrorMessage := iResponse.ErrorMessage;

      Result := FStatus;
    except
      on E: EHTTPProtocolException do
      begin
        FStatus.StatusCode := e.ErrorCode;
        FStatus.ErrorMessage := e.ErrorMessage;
        FStatus.Status := e.Message;
      end;
      on e: Exception do
      begin
        FStatus.StatusCode := -1;
        FStatus.ErrorMessage := e.Message;
        FStatus.Status := iResponse.StatusText;

        if Assigned(iResponse.JSONValue) then
        begin
          ResultadoJson := iResponse.JSONValue;
          Resultado := ResultadoJson.Value;
        end;

      end;
    end;
  finally
    if Assigned(JsonBody) then
      JsonBody.Free;

  end;

  Result := FStatus;

end;

procedure TRest.SetBaseUrl(const Value: String);
begin
  FBaseUrl := Value;
end;

procedure TRest.SetBody(const Value: TJsonValue);
begin
  FBody := Value;
end;

procedure TRest.SetContentType(const Value: string);
begin
  FContentType := Value;
end;

procedure TRest.SetResource(const Value: String);
begin
  FResource := Value;
end;

procedure TRest.SetResultado(const Value: String);
begin
  FResultado := Value;
end;

procedure TRest.SetStatus(const Value: TStatusExecucao);
begin
  FStatus := Value;
end;

procedure TRest.SetVerbo(const Value: TVerbo);
begin
  FVerbo := Value;
end;

function TRest.TrataScape(Json: String): String;
var
  I: Integer;
  InString: Boolean;
begin
  Result := Json;
  InString := False;

  for I := Length(Result) downto 1 do // Varre de trás para frente para não interferir nos índices
  begin
    if Result[I] = '"' then
      InString := not InString
    else if InString and (Result[I] = '/') and (I > 1) and (Result[I-1] <> '\') then
      Insert('\', Result, I);
  end;
end;


end.
