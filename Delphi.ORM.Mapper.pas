unit Delphi.ORM.Mapper;

interface

uses System.Rtti, System.Generics.Collections, System.Generics.Defaults, System.SysUtils, Delphi.ORM.Attributes;

type
  EClassWithoutPrimaryKeyDefined = class(Exception);
  TField = class;
  TForeignKey = class;
  TManyValueAssociation = class;
  TMapper = class;
  TTable = class;

  EClassWithPrimaryKeyNullable = class(Exception)
  public
    constructor Create(Table: TTable);
  end;

  EManyValueAssociationLinkError = class(Exception)
  public
    constructor Create(ParentTable, ChildTable: TTable);
  end;

  TTable = class
  private
    FPrimaryKey: TField;
    FForeignKeys: TArray<TForeignKey>;
    FFields: TArray<TField>;
    FTypeInfo: TRttiInstanceType;
    FDatabaseName: String;
    FManyValueAssociations: TArray<TManyValueAssociation>;
    FMapper: TMapper;
  public
    constructor Create(TypeInfo: TRttiInstanceType);

    destructor Destroy; override;

    property DatabaseName: String read FDatabaseName;
    property Fields: TArray<TField> read FFields;
    property ForeignKeys: TArray<TForeignKey> read FForeignKeys;
    property ManyValueAssociations: TArray<TManyValueAssociation> read FManyValueAssociations;
    property Mapper: TMapper read FMapper;
    property PrimaryKey: TField read FPrimaryKey;
    property TypeInfo: TRttiInstanceType read FTypeInfo;
  end;

  TField = class
  private
    FDatabaseName: String;
    FInPrimaryKey: Boolean;
    FTypeInfo: TRttiInstanceProperty;
    FAutoGenerated: Boolean;
    FIsForeignKey: Boolean;
    FIsManyValueAssociation: Boolean;
    FTable: TTable;
    FIsNullable: Boolean;
    FIsLazy: Boolean;
    FForeignKey: TForeignKey;

    function GetIsJoinLink: Boolean;
  public
    function GetValue(Instance: TObject): TValue;
    function GetAsString(Instance: TObject): String; overload;
    function GetAsString(const Value: TValue): String; overload;

    procedure SetValue(Instance: TObject; const Value: TValue); overload;
    procedure SetValue(Instance: TObject; const Value: Variant); overload;

    property AutoGenerated: Boolean read FAutoGenerated;
    property DatabaseName: String read FDatabaseName;
    property ForeignKey: TForeignKey read FForeignKey;
    property InPrimaryKey: Boolean read FInPrimaryKey;
    property IsForeignKey: Boolean read FIsForeignKey;
    property IsJoinLink: Boolean read GetIsJoinLink;
    property IsLazy: Boolean read FIsLazy;
    property IsManyValueAssociation: Boolean read FIsManyValueAssociation;
    property IsNullable: Boolean read FIsNullable;
    property Table: TTable read FTable;
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
    FField: TField;
    FForeignKey: TForeignKey;
  public
    constructor Create(Field: TField; ChildTable: TTable; ForeignKey: TForeignKey);

    property ChildTable: TTable read FChildTable;
    property Field: TField read FField write FField;
    property ForeignKey: TForeignKey read FForeignKey;
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
    function GetNameAttribute<T: TCustomNameAttribute>(TypeInfo: TRttiNamedObject; var Name: String): Boolean;
    function GetManyValuAssociationLinkName(Field: TField): String;
    function GetPrimaryKey(TypeInfo: TRttiInstanceType): String;
    function GetTableName(TypeInfo: TRttiInstanceType): String;
    function GetTables: TArray<TTable>;
    function LoadClassInTable(TypeInfo: TRttiInstanceType): TTable;
    function LoadTable(TypeInfo: TRttiInstanceType): TTable;

    procedure LoadTableFields(TypeInfo: TRttiInstanceType; var Table: TTable);
    procedure LoadTableForeignKey(var Table: TTable; const Field: TField; const RttiType: TRttiInstanceType);
    procedure LoadTableForeignKeys(var Table: TTable);
    procedure LoadTableInfo(TypeInfo: TRttiInstanceType; var Table: TTable);
    procedure LoadTableManyValueAssociations(Table: TTable);
  public
    constructor Create;

    destructor Destroy; override;

    function FindTable(ClassInfo: TClass): TTable;
    function LoadClass(ClassInfo: TClass): TTable;

    procedure LoadAll;

    property Tables: TArray<TTable> read GetTables;

    class property Default: TMapper read FDefault;
  end;

implementation

uses System.TypInfo, System.Variants, Delphi.ORM.Rtti.Helper, Delphi.ORM.Nullable, Delphi.ORM.Lazy;

function SortFieldFunction(const Left, Right: TField): Integer;

  function FieldPriority(const Field: TField): Integer;
  begin
    if Field.InPrimaryKey then
      Result := 0
    else if Field.IsLazy then
      Result := 1
    else if Field.IsForeignKey then
      Result := 2
    else if Field.IsManyValueAssociation then
      Result := 3
    else
      Result := 1;
  end;

begin
  Result := FieldPriority(Left) - FieldPriority(Right);

  if Result = 0 then
    Result := CompareStr(Left.DatabaseName, Right.DatabaseName);
end;

function CreateFieldComparer: IComparer<TField>;
begin
  Result := TDelegatedComparer<TField>.Create(SortFieldFunction);
end;

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
  if not GetNameAttribute<FieldNameAttribute>(TypeInfo, Result) then
    Result := TypeInfo.Name;
end;

function TMapper.GetManyValuAssociationLinkName(Field: TField): String;
begin
  if not GetNameAttribute<ManyValueAssociationLinkNameAttribute>(Field.TypeInfo, Result) then
    Result := Field.Table.TypeInfo.Name.Substring(1);
end;

function TMapper.GetNameAttribute<T>(TypeInfo: TRttiNamedObject; var Name: String): Boolean;
begin
  var Attribute := TypeInfo.GetAttribute<T>;
  Result := Assigned(Attribute);

  if Result then
    Name := Attribute.Name;
end;

function TMapper.GetPrimaryKey(TypeInfo: TRttiInstanceType): String;
begin
  var Attribute := TypeInfo.GetAttribute<PrimaryKeyAttribute>;

  if Assigned(Attribute) then
    Result := Attribute.Name
  else
    Result := 'Id';
end;

function TMapper.GetTableName(TypeInfo: TRttiInstanceType): String;
begin
  if not GetNameAttribute<TableNameAttribute>(TypeInfo, Result) then
    Result := TypeInfo.Name.Substring(1);
end;

function TMapper.GetTables: TArray<TTable>;
begin
  Result := FTables.Values.ToArray;
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
  begin
    LoadTableManyValueAssociations(Table);

    TArray.Sort<TField>(Table.FFields, CreateFieldComparer);
  end;

  FLateLoadTables.Clear;
end;

function TMapper.LoadTable(TypeInfo: TRttiInstanceType): TTable;
begin
  Result := FindTable(TypeInfo.MetaclassType);

  if not Assigned(Result) and (TypeInfo.GetAttribute<SingleTableInheritanceAttribute> = nil) then
  begin
    Result := TTable.Create(TypeInfo);
    Result.FDatabaseName := GetTableName(TypeInfo);
    Result.FMapper := Self;

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
      Field.FAutoGenerated := Prop.GetAttribute<AutoGeneratedAttribute> <> nil;
      Field.FDatabaseName := GetFieldName(Prop as TRttiInstanceProperty);
      Field.FIsLazy := IsLazyLoading(Prop.PropertyType);
      Field.FIsNullable := Prop.PropertyType.IsRecord and IsNullableType(Prop.PropertyType);
      Field.FTable := Table;
      Field.FTypeInfo := Prop as TRttiInstanceProperty;
      Table.FFields := Table.FFields + [Field];

      Field.FIsForeignKey := Field.TypeInfo.PropertyType.IsInstance or Field.IsLazy;
      Field.FIsManyValueAssociation := Field.TypeInfo.PropertyType.IsArray;

      if Field.IsForeignKey then
        Field.FDatabaseName := 'Id' + Field.DatabaseName;
    end;
end;

procedure TMapper.LoadTableForeignKey(var Table: TTable; const Field: TField; const RttiType: TRttiInstanceType);
begin
  var ForeignTable := LoadTable(RttiType);

  if not Assigned(ForeignTable.PrimaryKey) then
    raise EClassWithoutPrimaryKeyDefined.CreateFmt('You must define a primary key for class %s!', [ForeignTable.TypeInfo.Name]);

  Field.FForeignKey := TForeignKey.Create(ForeignTable, Field);
  Table.FForeignKeys := Table.FForeignKeys + [Field.FForeignKey];
end;

procedure TMapper.LoadTableForeignKeys(var Table: TTable);
begin
  for var Field in Table.Fields do
    if Field.IsForeignKey then
      if Field.IsLazy then
        LoadTableForeignKey(Table, Field, GetLazyLoadingRttiType(Field.TypeInfo.PropertyType) as TRttiInstanceType)
      else
        LoadTableForeignKey(Table, Field, Field.TypeInfo.PropertyType.AsInstance);
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

    Table.FForeignKeys := Table.FForeignKeys + [TForeignKey.Create(BaseTable, BaseTable.PrimaryKey)];
    Table.FPrimaryKey := BaseTable.PrimaryKey;
  end
  else
  begin
    var PropertyName := GetPrimaryKey(TypeInfo);

    for var Field in Table.Fields do
      if Field.TypeInfo.Name = PropertyName then
      begin
        Field.FInPrimaryKey := True;
        Table.FPrimaryKey := Field;

        if Field.IsNullable then
          raise EClassWithPrimaryKeyNullable.Create(Table);
      end;
  end;

  LoadTableForeignKeys(Table);
end;

procedure TMapper.LoadTableManyValueAssociations(Table: TTable);
begin
  for var Field in Table.Fields do
    if Field.IsManyValueAssociation then
    begin
      var ChildTable := LoadTable(Field.TypeInfo.PropertyType.AsArray.ElementType.AsInstance);
      var LinkName := GetManyValuAssociationLinkName(Field);
      var ManyValueAssociation: TManyValueAssociation := nil;

      for var ForeignKey in ChildTable.ForeignKeys do
        if (ForeignKey.ParentTable = Table) and (ForeignKey.Field.TypeInfo.Name = LinkName) then
          ManyValueAssociation := TManyValueAssociation.Create(Field, ChildTable, ForeignKey);

      if Assigned(ManyValueAssociation) then
        Table.FManyValueAssociations := Table.FManyValueAssociations + [ManyValueAssociation]
      else
        raise EManyValueAssociationLinkError.Create(Table, ChildTable);
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

constructor TManyValueAssociation.Create(Field: TField; ChildTable: TTable; ForeignKey: TForeignKey);
begin
  inherited Create;

  FChildTable := ChildTable;
  FField := Field;
  FForeignKey := ForeignKey;
end;

{ TField }

function TField.GetAsString(Instance: TObject): String;
begin
  Result := GetAsString(GetValue(Instance));
end;

function TField.GetAsString(const Value: TValue): String;
begin
  if Value.IsEmpty then
    Result := 'null'
  else
  begin
    var Info := TypeInfo.PropertyType;

    if IsNullable then
      Info := GetNullableRttiType(Info)
    else if IsLazy then
      Info := GetLazyLoadingRttiType(Info);

    case Info.TypeKind of
      tkChar,
      tkRecord,
      tkString,
      tkLString,
      tkUString,
      tkWChar,
      tkWString: Result := QuotedStr(Value.GetAsString);

      tkClass:
      begin
        var PrimaryKey := Table.Mapper.FindTable(Info.AsInstance.MetaclassType).PrimaryKey;

        if Value.Kind = tkClass then
          Result := PrimaryKey.GetAsString(Value.AsObject)
        else
          Result := PrimaryKey.GetAsString(Value);
      end;

      tkFloat:
      begin
        if Info.Handle = System.TypeInfo(TDate) then
          Result := QuotedStr(DateToStr(Value.AsExtended, TValue.FormatSettings))
        else if Info.Handle = System.TypeInfo(TDateTime) then
          Result := QuotedStr(DateTimeToStr(Value.AsExtended, TValue.FormatSettings))
        else if Info.Handle = System.TypeInfo(TTime) then
          Result := QuotedStr(TimeToStr(Value.AsExtended, TValue.FormatSettings))
        else
          Result := FloatToStr(Value.AsExtended, TValue.FormatSettings);
      end;

      tkEnumeration,
      tkInteger,
      tkInt64:
        Result := Value.GetAsString;

      else raise Exception.Create('Type not mapped!');
    end;
  end;
end;

function TField.GetIsJoinLink: Boolean;
begin
  Result := IsForeignKey or IsManyValueAssociation;
end;

function TField.GetValue(Instance: TObject): TValue;
begin
  Result := TypeInfo.GetValue(Instance);

  if IsNullable then
    Result := GetNullableAccess(Result).GetValue
  else if IsLazy then
  begin
    var LazyAccess := GetLazyLoadingAccess(Result);

    if LazyAccess.Loaded then
      Result := LazyAccess.GetValue
    else
      Result := LazyAccess.GetKey;
  end;
end;

procedure TField.SetValue(Instance: TObject; const Value: TValue);
begin
  if IsNullable then
    GetNullableAccess(TypeInfo.GetValue(Instance)).SetValue(Value)
  else if IsLazy then
  begin
    var LazyAccess := GetLazyLoadingAccess(TypeInfo.GetValue(Instance));

    LazyAccess.SetValue(Value);
  end
  else
    TypeInfo.SetValue(Instance, Value);
end;

procedure TField.SetValue(Instance: TObject; const Value: Variant);
begin
  if Value = System.Variants.NULL then
    SetValue(Instance, TValue.Empty)
  else if TypeInfo.PropertyType is TRttiEnumerationType then
    SetValue(Instance, TValue.FromOrdinal(TypeInfo.PropertyType.Handle, Value))
  else if TypeInfo.PropertyType.Handle = System.TypeInfo(TGUID) then
    SetValue(Instance, TValue.From(StringToGuid(Value)))
  else
    SetValue(Instance, TValue.FromVariant(Value));
end;

{ EManyValueAssociationLinkError }

constructor EManyValueAssociationLinkError.Create(ParentTable, ChildTable: TTable);
begin
  inherited CreateFmt('The link between %s and %s can''t be maded. Check if it exists, as the same name of the parent table or has the attribute defining the name of the link!',
    [ParentTable.TypeInfo.Name, ChildTable.TypeInfo.Name]);
end;

{ EClassWithPrimaryKeyNullable }

constructor EClassWithPrimaryKeyNullable.Create(Table: TTable);
begin
  inherited CreateFmt('The primary key of the class %s is nullable, it''s not accepted!', [Table.TypeInfo.Name]);
end;

end.

