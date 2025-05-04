unit TimeEntry;

interface

uses
  Pkg.Json.DTO, System.Generics.Collections, REST.Json.Types;

{$M+}

type
  TTimeEntry = class(TJsonDTO)
  private
    FBillable: Boolean;
    [JSONName('created_with')]
    FCreatedWith: string;
    FDescription: string;
    [JSONName('project_id')]
    FProjectId: Integer;
    [SuppressZero]
    FStart: TDateTime;
    [SuppressZero]
    FStop: TDateTime;
    [JSONName('tag_ids')]
    FTagIdsArray: TArray<Integer>;
    [JSONMarshalled(False)]
    FTagIds: TList<Integer>;
    [JSONName('tags')]
    FTagsArray: TArray<string>;
    [JSONMarshalled(False)]
    FTags: TList<string>;
    [JSONName('workspace_id')]
    FWorkspaceId: Integer;
    function GetTagIds: TList<Integer>;
    function GetTags: TList<string>;
  protected
    function GetAsJson: string; override;
  published
    property Billable: Boolean read FBillable write FBillable;
    property CreatedWith: string read FCreatedWith write FCreatedWith;
    property Description: string read FDescription write FDescription;
    property ProjectId: Integer read FProjectId write FProjectId;
    property Start: TDateTime read FStart write FStart;
    property Stop: TDateTime read FStop write FStop;
    property TagIds: TList<Integer> read GetTagIds;
    property Tags: TList<string> read GetTags;
    property WorkspaceId: Integer read FWorkspaceId write FWorkspaceId;
  public
    destructor Destroy; override;
  end;

  TTimeEntryList = TList<TTimeEntry>;

implementation

{ TRoot }

destructor TTimeEntry.Destroy;
begin
  GetTags.Free;
  GetTagIds.Free;
  inherited;
end;

function TTimeEntry.GetTagIds: TList<Integer>;
begin
  Result := List<Integer>(FTagIds, FTagIdsArray);
end;

function TTimeEntry.GetTags: TList<string>;
begin
  Result := List<string>(FTags, FTagsArray);
end;

function TTimeEntry.GetAsJson: string;
begin
  RefreshArray<Integer>(FTagIds, FTagIdsArray);
  RefreshArray<string>(FTags, FTagsArray);
  Result := inherited;
end;

end.
