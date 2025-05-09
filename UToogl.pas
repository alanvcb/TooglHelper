unit UToogl;

interface

uses
  UTimeEntry;

type TToogl = class
const BaseURL = 'https://api.track.toggl.com/api/v9';
private
  FAPIKey : string;
  FWorkSpaceID: string;
public
  property APIKey: string read FAPIKey write FAPIKey;
  property WorkSpaceID: String read FWorkSpaceID write FWorkSpaceID;
  function InsertTimeEntry(ATimeEntry: TTimeEntry): Boolean;
  function InsertTimeEntryList(AList: TTimeEntryList): Boolean;
  function GetTimeEntryList(ADate: TDateTime): TTimeEntryList;
end;

implementation

{ TToogl }

Uses Rest, System.NetEncoding, System.SysUtils, System.JSON, ULog;

function TToogl.GetTimeEntryList(ADate: TDateTime): TTimeEntryList;
var
  Rest: TRest;
  StartDate, EndDate: string;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  i: Integer;
begin
  Rest := TRest.Create;
  Result := TTimeEntryList.Create;
  try
    Rest.BaseUrl := BaseURL;
    Rest.Resource := 'me/time_entries';
    Rest.AddParams('Authorization','Basic ' +TNetEncoding.Base64.Encode(FAPIKey + ':api_token'),ptHeader);
    // Formata as datas no formato ISO 8601
    StartDate := FormatDateTime('yyyy-mm-dd', ADate) + 'T00:00:00+00:00';
    EndDate := FormatDateTime('yyyy-mm-dd', ADate) + 'T23:59:59+00:00';

    // Adiciona os parâmetros de data à requisição
    Rest.AddParams('start_date', StartDate, ptQuery);
    Rest.AddParams('end_date', EndDate, ptQuery);
    Rest.Execute;

    // Verifica se a resposta foi bem-sucedida
    if Rest.Status.StatusCode = 200  then
    begin
      // Parseia a resposta JSON
      JSONArray := Rest.ResultadoJson as TJSONArray;
      try
        if Assigned(JSONArray) then
        begin
          for i := 0 to JSONArray.Count - 1 do
          begin
            JSONObject := JSONArray.Items[i] as TJSONObject;
            Result.Add(TTimeEntry.Create(JSONObject));
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
      Log.LogError('Erro ao buscar entradas de texto: '+Rest.Status.ErrorMessage);
  finally
    // Libera os componentes
   Rest.Free;
  end;

end;

function TToogl.InsertTimeEntry(ATimeEntry: TTimeEntry): Boolean;
var Rest: TRest;
begin
  Result := True;
  Rest := TRest.Create;
  try
    Rest.BaseUrl := BaseURL;
    Rest.Resource := 'workspaces/'+FWorkSpaceID+'/time_entries';
    Rest.AddParams('Authorization','Basic ' +TNetEncoding.Base64.Encode(FAPIKey + ':api_token'),ptHeader);
    Rest.Verbo := vPost;
    Rest.Body := ATimeEntry.AsJsonObject;
    Rest.Execute;

    Result := Rest.Status.StatusCode = 200;

    if not Result then
    begin
//      EscreveLN('Erro na requisição: ' + RestResponse.Content);
      raise Exception.Create('Erro ao inserir uma entrada de tempo: '+Rest.Status.ErrorMessage);
      Result := False;
    end;

  finally
    Rest.Free;
  end;

end;

function TToogl.InsertTimeEntryList(AList: TTimeEntryList): Boolean;
var tmpResult: Boolean;
begin
  Result := True;
  for var TimeEntry in AList do
  begin
    try
      if not InsertTimeEntry(TimeEntry) then
        Result := False;
    except
      Result := False;
    end;
  end;
end;

end.
