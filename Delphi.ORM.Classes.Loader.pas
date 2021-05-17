unit Delphi.ORM.Classes.Loader;

interface

uses System.Rtti, System.Generics.Collections, System.SysUtils, Delphi.ORM.Database.Connection, Delphi.ORM.Mapper, Delphi.ORM.Query.Builder;

type
  TClassLoader = class
  private
    FCache: TDictionary<String, TObject>;
    FContext: TRttiContext;
    FConnection: IDatabaseConnection;
    FCursor: IDatabaseCursor;
    FFields: TArray<TFieldAlias>;
    FJoin: TQueryBuilderJoin;

    function CreateObject(Table: TTable; const FieldIndexStart: Integer; var PrimaryKeyValue: String): TObject;
    function FieldValueToString(Field: TField; const FieldValue: Variant): String;
    function GetFieldValueVariant(const Index: Integer): Variant;
    function GetObjectFromCache(const Key: String; CreateFunction: TFunc<TObject>): TObject;
    function GetPrimaryKeyFromTable(Table: TTable; const FieldIndexStart: Integer): String;
    function LoadClass(var PrimaryKey: String): TObject;
    function LoadClassJoin(Join: TQueryBuilderJoin; var FieldIndexStart: Integer; var PrimaryKey: String): TObject;
  public
    constructor Create(Connection: IDatabaseConnection; From: TQueryBuilderFrom);

    destructor Destroy; override;

    function Load<T: class>: T;
    function LoadAll<T: class>: TArray<T>;
  end;

implementation

uses System.Variants, System.TypInfo, System.SysConst, Delphi.ORM.Rtti.Helper, Delphi.ORM.Lazy, Delphi.ORM.Lazy.Loader;

{ TClassLoader }

constructor TClassLoader.Create(Connection: IDatabaseConnection; From: TQueryBuilderFrom);
begin
  inherited Create;

  FCache := TDictionary<String, TObject>.Create;
  FContext := TRttiContext.Create;
  FConnection := Connection;
  FCursor := Connection.OpenCursor(From.Builder.GetSQL);
  FFields := From.Fields;
  FJoin := From.Join;
end;

function TClassLoader.CreateObject(Table: TTable; const FieldIndexStart: Integer; var PrimaryKeyValue: String): TObject;
begin
  PrimaryKeyValue := GetPrimaryKeyFromTable(Table, FieldIndexStart);

  if PrimaryKeyValue.IsEmpty then
    Result := nil
  else
    Result := GetObjectFromCache(PrimaryKeyValue,
      function: TObject
      begin
        Result := Table.TypeInfo.MetaclassType.Create;
      end);
end;

destructor TClassLoader.Destroy;
begin
  FCache.Free;

  inherited;
end;

function TClassLoader.GetFieldValueVariant(const Index: Integer): Variant;
begin
  Result := FCursor.GetFieldValue(Index);
end;

function TClassLoader.FieldValueToString(Field: TField; const FieldValue: Variant): String;
begin
  if VarIsNull(FieldValue) then
    Result := EmptyStr
  else if Field.TypeInfo.PropertyType = FContext.GetType(TypeInfo(TGUID)) then
    Result := FieldValue
  else if Field.TypeInfo.PropertyType is TRttiEnumerationType then
    Result := TRttiEnumerationType.GetName(FieldValue)
  else
    Result := FieldValue;
end;

function TClassLoader.GetObjectFromCache(const Key: String; CreateFunction: TFunc<TObject>): TObject;
begin
  if not FCache.ContainsKey(Key) then
    FCache.Add(Key, CreateFunction);

  Result := FCache[Key];
end;

function TClassLoader.GetPrimaryKeyFromTable(Table: TTable; const FieldIndexStart: Integer): String;
begin
  Result := EmptyStr;

  if Assigned(Table.PrimaryKey) then
  begin
    var Field := FFields[FieldIndexStart].Field;
    var FieldValue := GetFieldValueVariant(FieldIndexStart);

    if VarIsNull(FieldValue) then
      Exit
    else
      Result := Result + '.' + FieldValueToString(Field, FieldValue);
  end;

  Result := Table.DatabaseName + Result;
end;

function TClassLoader.Load<T>: T;
begin
  var All := LoadAll<T>;
  Result := nil;

  if Assigned(All) then
    Result := All[0];
end;

function TClassLoader.LoadAll<T>: TArray<T>;
begin
  var GroupControl := TDictionary<String, String>.Create;
  var ObjectLoaded: TObject := nil;
  var PrimaryKey := EmptyStr;
  Result := nil;

  while FCursor.Next do
  begin
    ObjectLoaded := LoadClass(PrimaryKey);

    if not GroupControl.ContainsKey(PrimaryKey) then
    begin
      Result := Result + [ObjectLoaded as T];

      GroupControl.Add(PrimaryKey, EmptyStr);
    end;
  end;

  GroupControl.Free;
end;

function TClassLoader.LoadClass(var PrimaryKey: String): TObject;
begin
  var FieldIndex := Low(FJoin.Table.Fields);
  Result := LoadClassJoin(FJoin, FieldIndex, PrimaryKey);
end;

function TClassLoader.LoadClassJoin(Join: TQueryBuilderJoin; var FieldIndexStart: Integer; var PrimaryKey: String): TObject;
begin
  Result := CreateObject(Join.Table, FieldIndexStart, PrimaryKey);

  for var Field in Join.Table.Fields do
    if not Field.IsJoinLink or Field.IsLazy then
    begin
      if Assigned(Result) then
      begin
        var FieldValue := GetFieldValueVariant(FieldIndexStart);

        if Field.IsLazy then
          GetLazyLoadingAccess(Field.TypeInfo.GetValue(Result)).SetLazyLoader(TLazyLoader.Create(FConnection, Field.ForeignKey.ParentTable, TValue.FromVariant(FieldValue)))
        else
          Field.SetValue(Result, FieldValue);
      end;

      Inc(FieldIndexStart);
    end;

  for var Link in Join.Links do
  begin
    var ChildPrimaryKey := EmptyStr;
    var Value: TValue;

    if Link.Field.IsForeignKey then
      Value := LoadClassJoin(Link, FieldIndexStart, ChildPrimaryKey)
    else
    begin
      var AlreadyExists := FCache.ContainsKey(GetPrimaryKeyFromTable(Link.Table, FieldIndexStart));
      var ChildObject := LoadClassJoin(Link, FieldIndexStart, ChildPrimaryKey);

      if AlreadyExists then
        Continue
      else if Assigned(ChildObject) then
      begin
        Value := Link.Field.GetValue(Result);

        var ArrayLength := Value.ArrayLength;

        Value.ArrayLength := Succ(ArrayLength);

        Value.ArrayElement[ArrayLength] := ChildObject;

        Link.RightField.SetValue(ChildObject, Result);
      end;
    end;

    if Assigned(Result) then
      Link.Field.SetValue(Result, Value);
  end;
end;

end.

