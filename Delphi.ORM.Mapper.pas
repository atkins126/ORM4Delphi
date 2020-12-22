unit Delphi.ORM.Mapper;

interface

uses System.Rtti, System.Generics.Collections, System.Generics.Defaults, System.SysUtils;

type
  EClassWithoutPrimaryKeyDefined = class(Exception);
  TField = class;
  TForeignKey = class;
  TManyValueAssociation = class;

  TTable = class
  private
    FPrimaryKey: TArray<TField>;
    FForeignKeys: TArray<TForeignKey>;
    FFields: TArray<TField>;
    FTypeInfo: TRttiInstanceType;
    FDatabaseName: String;
    FManyValueAssociations: TArray<TManyValueAssociation>;
  public
    constructor Create(TypeInfo: TRttiInstanceType);

    destructor Destroy; override;

    property DatabaseName: String read FDatabaseName write FDatabaseName;
    property Fields: TArray<TField> read FFields;
    property ForeignKeys: TArray<TForeignKey> read FForeignKeys;
    property ManyValueAssociations: TArray<TManyValueAssociation> read FManyValueAssociations write FManyValueAssociations;
    property PrimaryKey: TArray<TField> read FPrimaryKey;
    property TypeInfo: TRttiInstanceType read FTypeInfo;
  end;

  TField = class
  private
    FDatabaseName: String;
    FInPrimaryKey: Boolean;
    FTypeInfo: TRttiInstanceProperty;
  public
    property DatabaseName: String read FDatabaseName;
    property InPrimaryKey: Boolean read FInPrimaryKey;
    property TypeInfo: TRttiInstanceProperty read FTypeInfo;
  end;

  TFieldAlias = record
  private
    FTableAlias: String;
    FField: TField;
  public
    constructor Create(TableAlias: String; Field: TField);

    property Field: TField read FField write FField;
    property TableAlias: String read FTableAlias write FTableAlias;
  end;

  TForeignKey = class
  private
    FParentTable: TTable;
    FField: TField;
  public
    constructor Create(ParentTable: TTable; Field: TField);

    property Field: TField read FField;
    property ParentTable: TTable read FParentTable;
  end;

  TManyValueAssociation = class
  private
    FChildTable: TTable;
    FChildField: TField;
    FField: TField;
  public
    constructor Create(Field: TField; ChildTable: TTable; ChildField: TField);

    property Field: TField read FField write FField;
    property ChildField: TField read FChildField write FChildField;
    property ChildTable: TTable read FChildTable write FChildTable;
  end;

  TMapper = class
  private
    class var [Unsafe] FDefault: TMapper;

    class constructor Create;
    class destructor Destroy;
  private
    FContext: TRttiContext;
    FTables: TDictionary<TRttiInstanceType, TTable>;
    FLateLoadTables: TList<TTable>;

    function CheckAttribute<T: TCustomAttribute>(TypeInfo: TRttiType): Boolean;
    function GetFieldName(TypeInfo: TRttiInstanceProperty): String;
    function GetNameAttribute(TypeInfo: TRttiNamedObject; var Name: String): Boolean;
    function GetPrimaryKey(TypeInfo: TRttiInstanceType): TArray<String>;
    function GetTableName(TypeInfo: TRttiInstanceType): String;
    function GetTables: TArray<TTable>;
    function LoadClassInTable(TypeInfo: TRttiInstanceType): TTable;
    function LoadTable(TypeInfo: TRttiInstanceType): TTable;

    procedure LoadTableFields(TypeInfo: TRttiInstanceType; var Table: TTable);
    procedure LoadTableForeignKeys(var Table: TTable);
    procedure LoadTableInfo(TypeInfo: TRttiInstanceType; var Table: TTable);
    procedure LoadTableManyValueAssociations(Table: TTable);
  public
    constructor Create;

    destructor Destroy; override;

    class function IsForeignKey(Field: TField): Boolean;
    class function IsJoinLink(Field: TField): Boolean;
    class function IsManyValueAssociation(Field: TField): Boolean;

    function FindTable(ClassInfo: TClass): TTable;
    function LoadClass(ClassInfo: TClass): TTable;

    procedure LoadAll;

    property Tables: TArray<TTable> read GetTables;

    class property Default: TMapper read FDefault;
  end;

implementation

uses System.TypInfo, Delphi.ORM.Attributes, Delphi.ORM.Rtti.Helper;

{ TMapper }

function TMapper.CheckAttribute<T>(TypeInfo: TRttiType): Boolean;
begin
  Result := False;

  for var TypeToCompare in TypeInfo.GetAttributes do
    if TypeToCompare is T then
      Exit(True);
end;

class constructor TMapper.Create;
begin
  FDefault := TMapper.Create;
end;

constructor TMapper.Create;
begin
  FContext := TRttiContext.Create;
  FLateLoadTables := TList<TTable>.Create;
  FTables := TObjectDictionary<TRttiInstanceType, TTable>.Create([doOwnsValues]);
end;

destructor TMapper.Destroy;
begin
  FLateLoadTables.Free;

  FTables.Free;

  FContext.Free;
end;

function TMapper.FindTable(ClassInfo: TClass): TTable;
begin
  if not FTables.TryGetValue(FContext.GetType(ClassInfo).AsInstance, Result) then
    Result := nil;
end;

function TMapper.GetFieldName(TypeInfo: TRttiInstanceProperty): String;
begin
  if not GetNameAttribute(TypeInfo, Result) then
  begin
    Result := TypeInfo.Name;

    if TypeInfo.PropertyType.IsInstance then
      Result := 'Id' + Result;
  end;
end;

function TMapper.GetNameAttribute(TypeInfo: TRttiNamedObject; var Name: String): Boolean;
begin
  var Attribute := TypeInfo.GetAttribute<TCustomNameAttribute>;
  Result := Assigned(Attribute);

  if Result then
    Name := Attribute.Name;
end;

function TMapper.GetPrimaryKey(TypeInfo: TRttiInstanceType): TArray<String>;
begin
  var Attribute := TypeInfo.GetAttribute<PrimaryKeyAttribute>;

  if Assigned(Attribute) then
    Result := Attribute.Fields
  else
    Result := ['Id'];
end;

function TMapper.GetTableName(TypeInfo: TRttiInstanceType): String;
begin
  if not GetNameAttribute(TypeInfo, Result) then
    Result := TypeInfo.Name.Substring(1);
end;

function TMapper.GetTables: TArray<TTable>;
begin
  Result := FTables.Values.ToArray;
end;

class function TMapper.IsForeignKey(Field: TField): Boolean;
begin
  Result := Field.TypeInfo.PropertyType.IsInstance;
end;

class function TMapper.IsJoinLink(Field: TField): Boolean;
begin
  Result := IsForeignKey(Field) or IsManyValueAssociation(Field);
end;

class function TMapper.IsManyValueAssociation(Field: TField): Boolean;
begin
  Result := Field.TypeInfo.PropertyType.IsArray;
end;

class destructor TMapper.Destroy;
begin
  FDefault.Free;
end;

procedure TMapper.LoadAll;
begin
  FTables.Clear;

  for var TypeInfo in FContext.GetTypes do
    if CheckAttribute<EntityAttribute>(TypeInfo) then
      LoadClassInTable(TypeInfo.AsInstance);
end;

function TMapper.LoadClass(ClassInfo: TClass): TTable;
begin
  Result := LoadClassInTable(FContext.GetType(ClassInfo).AsInstance);
end;

function TMapper.LoadClassInTable(TypeInfo: TRttiInstanceType): TTable;
begin
  Result := LoadTable(TypeInfo);

  for var Table in FLateLoadTables do
    LoadTableManyValueAssociations(Table);

  FLateLoadTables.Clear;
end;

function TMapper.LoadTable(TypeInfo: TRttiInstanceType): TTable;
begin
  Result := FindTable(TypeInfo.MetaclassType);

  if not Assigned(Result) and (TypeInfo.GetAttribute<SingleTableInheritanceAttribute> = nil) then
  begin
    Result := TTable.Create(TypeInfo);
    Result.DatabaseName := GetTableName(TypeInfo);

    FTables.Add(TypeInfo, Result);

    FLateLoadTables.Add(Result);

    LoadTableInfo(TypeInfo, Result);
  end;
end;

procedure TMapper.LoadTableFields(TypeInfo: TRttiInstanceType; var Table: TTable);
begin
  for var Prop in TypeInfo.GetDeclaredProperties do
    if Prop.Visibility = mvPublished then
    begin
      var Field := TField.Create;
      Field.FDatabaseName := GetFieldName(Prop as TRttiInstanceProperty);
      Field.FTypeInfo := Prop as TRttiInstanceProperty;
      Table.FFields := Table.FFields + [Field];
    end;
end;

procedure TMapper.LoadTableForeignKeys(var Table: TTable);
begin
  for var Field in Table.Fields do
    if IsForeignKey(Field) then
    begin
      var ForeignTable := LoadTable(Field.TypeInfo.PropertyType.AsInstance);

      if Length(ForeignTable.PrimaryKey) = 0 then
        raise EClassWithoutPrimaryKeyDefined.CreateFmt('You must define a primary key for class %s!', [ForeignTable.TypeInfo.Name]);

      Table.FForeignKeys := Table.FForeignKeys + [TForeignKey.Create(ForeignTable, Field)];
    end;
end;

procedure TMapper.LoadTableInfo(TypeInfo: TRttiInstanceType; var Table: TTable);
begin
  var BaseClass := TypeInfo.BaseType;
  var IsSingleTable := BaseClass.GetAttribute<SingleTableInheritanceAttribute> <> nil;

  if BaseClass.MetaclassType = TObject then
    BaseClass := nil;

  if IsSingleTable then
    LoadTableFields(BaseClass, Table);

  LoadTableFields(TypeInfo, Table);

  if not IsSingleTable and Assigned(BaseClass) then
  begin
    var BaseTable := FindTable(BaseClass.MetaclassType);

    Table.FForeignKeys := Table.FForeignKeys + [TForeignKey.Create(BaseTable, BaseTable.PrimaryKey[0])];
    Table.FPrimaryKey := BaseTable.PrimaryKey;
  end
  else
    for var PropertyName in GetPrimaryKey(TypeInfo) do
      for var Field in Table.Fields do
        if Field.TypeInfo.Name = PropertyName then
        begin
          Field.FInPrimaryKey := True;
          Table.FPrimaryKey := Table.FPrimaryKey + [Field];
        end;

  LoadTableForeignKeys(Table);
end;

procedure TMapper.LoadTableManyValueAssociations(Table: TTable);
begin
  for var Field in Table.Fields do
    if IsManyValueAssociation(Field) then
    begin
      var ChildTable := LoadTable(Field.TypeInfo.PropertyType.AsArray.ElementType.AsInstance);

      for var ForeignKey in ChildTable.ForeignKeys do
        if ForeignKey.ParentTable = Table then
          Table.FManyValueAssociations := Table.FManyValueAssociations + [TManyValueAssociation.Create(Field, ChildTable, ForeignKey.Field)];
    end;
end;

{ TTable }

constructor TTable.Create(TypeInfo: TRttiInstanceType);
begin
  inherited Create;

  FTypeInfo := TypeInfo;
end;

destructor TTable.Destroy;
begin
  for var Field in Fields do
    Field.Free;

  for var ForeignKey in ForeignKeys do
    ForeignKey.Free;

  for var ManyValueAssociation in ManyValueAssociations do
    ManyValueAssociation.Free;

  inherited;
end;

{ TForeignKey }

constructor TForeignKey.Create(ParentTable: TTable; Field: TField);
begin
  inherited Create;

  FParentTable := ParentTable;
  FField := Field;
end;

{ TFieldAlias }

constructor TFieldAlias.Create(TableAlias: String; Field: TField);
begin
  FField := Field;
  FTableAlias := TableAlias;
end;

{ TManyValueAssociation }

constructor TManyValueAssociation.Create(Field: TField; ChildTable: TTable; ChildField: TField);
begin
  inherited Create;

  FChildField := ChildField;
  FChildTable := ChildTable;
  FField := Field;
end;

end.
