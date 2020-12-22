unit Delphi.ORM.Mapper.Test;

interface

uses System.Rtti, DUnitX.TestFramework, Delphi.ORM.Attributes;

type
  [TestFixture]
  TMapperTest = class
  private
    FContext: TRttiContext;
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure WhenCallLoadAllMustLoadAllClassesWithTheEntityAttribute;
    [Test]
    procedure WhenTryToFindATableMustReturnTheTableOfTheClass;
    [Test]
    procedure WhenTryToFindATableWithoutTheEntityAttributeMustReturnANilValue;
    [Test]
    procedure WhenLoadATableMustLoadAllFieldsToo;
    [Test]
    procedure WhenTheFieldsAreLoadedMustFillTheNameWithTheNameOfPropertyOfTheClass;
    [Test]
    procedure WhenLoadAClassMustKeepTheOrderingOfTablesToTheFindTableContinueToWorking;
    [Test]
    procedure WhenLoadAFieldMustFillThePropertyWithThePropertyInfo;
    [Test]
    procedure WhenAClassDoesNotHaveThePrimaryKeyAttributeAndHasAnIdFieldThisWillBeThePrimaryKey;
    [Test]
    procedure WhenTheClassHaveThePrimaryKeyAttributeThePrimaryKeyWillBeTheFieldFilled;
    [Test]
    procedure WhenThePrimaryKeyAttributeHasMoreThanOneFieldHasToPutEveryoneOnTheList;
    [Test]
    procedure TheFieldInPrimaryKeyMustBeMarkedWithInPrimaryKey;
    [Test]
    procedure TheDatabaseNameOfATableMustBeTheNameOfClassRemovingTheFirstCharOfTheClassName;
    [Test]
    procedure WhenTheClassHaveTheTableNameAttributeTheDatabaseNameMustBeLikeTheNameInAttribute;
    [Test]
    procedure OnlyPublishedFieldMutsBeLoadedInTheTable;
    [Test]
    procedure WhenTheFieldHaveTheFieldNameAttributeMustLoadThisNameInTheDatabaseName;
    [Test]
    procedure EveryPropertyThatIsAnObjectMustCreateAForeignKeyInTheListOfTheTable;
    [Test]
    procedure WhenTheForeignKeyIsCreatesMustLoadTheParentTable;
    [Test]
    procedure TheParentTableMustBeTheTableLinkedToTheField;
    [Test]
    procedure WhenTheFieldIsAClassMustFillTheDatabaseNameWithIdPlusPropertyName;
    [Test]
    procedure TheFieldOfAForeignKeyMustBeFilledWithTheFieldOfTheClassThatIsAForeignKey;
    [Test]
    procedure TheLoadingOfForeingKeyMustBeAfterAllTablesAreLoadedToTheFindTableWorksPropertily;
    [Test]
    procedure WhenMapAForeignKeyIsToAClassWithoutAPrimaryKeyMustRaiseAnError;
    [Test]
    procedure WhenCallLoadAllMoreThemOneTimeCantRaiseAnError;
    [Test]
    procedure TheClassWithTheSingleTableInheritanceAttributeCantBeMappedInTheTableList;
    [Test]
    procedure WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeMustLoadAllFieldsInTheTable;
    [Test]
    procedure WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeCantGenerateAnyForeignKey;
    [Test]
    procedure WhenTheClassIsInheritedFromANormalClassCantLoadFieldsFormTheBaseClass;
    [Test]
    procedure WhenTheClassIsInheritedFromANormalClassMustCreateAForeignKeyForTheBaseClass;
    [Test]
    procedure WhenTheClassIsInheritedFromTObjectCantCreateAForeignKeyForThatClass;
    [Test]
    procedure WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeThePrimaryKeyMustBeLoadedFromTheTopClass;
    [Test]
    procedure WhenTheClassIsInheritedFromANormalClassMustCreateAForeignKeyForTheBaseClassWithThePrimaryKeyFields;
    [Test]
    procedure WhenTheClassIsInheritedMustLoadThePrimaryKeyFromBaseClass;
    [Test]
    procedure WhenTheClassIsInheritedMustShareTheSamePrimaryKeyFromTheBaseClass;
    [Test]
    procedure WhenTheForeignKeyIsAClassAliasMustLoadTheForeignClassAndLinkToForeignKey;
    [Test]
    procedure WhenLoadMoreThenOneTimeTheSameClassCantRaiseAnError;
    [Test]
    procedure WhenAPropertyIsAnArrayMustLoadAManyValueLink;
    [Test]
    procedure TheTableOfManyValueAssociationMustBeTheChildTableOfThisLink;
    [Test]
    procedure TheFieldLinkingTheParentAndChildOfManyValueAssociationMustBeLoaded;
    [Test]
    procedure WhenTheChildClassIsDeclaredBeforeTheParentClassTheLinkBetweenOfTablesMustBeCreated;
    [Test]
    procedure TheManyValueAssociationMustLoadTheFieldThatGeneratedTheValue;
  end;

  [Entity]
  TMyEntity = class
  private
    FId: Integer;
    FName: String;
    FValue: Double;
    FPublicField: String;
  public
    property PublicField: String read FPublicField write FPublicField;
  published
    property Id: Integer read FId write FId;
    property Name: String read FName write FName;
    property Value: Double read FValue write FValue;
  end;

  [Entity]
  [TableName('AnotherTableName')]
  TMyEntity2 = class
  private
    FId: Integer;
    FName: String;
    FValue: Double;
    FAField: Integer;
  published
    property AField: Integer read FAField write FAField;
    property Id: Integer read FId write FId;
    property Name: String read FName write FName;
    property Value: Double read FValue write FValue;
  end;

  [Entity]
  TMyEntity3 = class
  private
    FId: Integer;
  published
    property Id: Integer read FId write FId;
  end;

  [Entity]
  [PrimaryKey('Value')]
  TMyEntityWithPrimaryKey = class
  private
    FId: Integer;
    FValue: Double;
  published
    property Id: Integer read FId write FId;
    property Value: Double read FValue write FValue;
  end;

  [Entity]
  [PrimaryKey('Value,Id')]
  TMyEntityWithPrimaryKey2 = class
  private
    FId: Integer;
    FValue: Double;
  published
    property Id: Integer read FId write FId;
    property Value: Double read FValue write FValue;
  end;

  [Entity]
  TMyEntityWithFieldNameAttribute = class
  private
    FName: String;
    FMyForeignKey: TMyEntityWithPrimaryKey;
    FMyForeignKey2: TMyEntity2;
  published
    [FieldName('AnotherFieldName')]
    property Name: String read FName write FName;
    property MyForeignKey: TMyEntityWithPrimaryKey read FMyForeignKey write FMyForeignKey;
    property MyForeignKey2: TMyEntity2 read FMyForeignKey2 write FMyForeignKey2;
  end;

  TMyEntityWithoutEntityAttribute = class
  private
    FId: Integer;
    FName: String;
    FValue: Double;
  published
    property Id: Integer read FId write FId;
    property Name: String read FName write FName;
    property Value: Double read FValue write FValue;
  end;

  [Entity]
  TAAAA = class
  private
    FId: Integer;
    FValue: String;
  published
    property Id: Integer read FId write FId;
    property Value: String read FValue write FValue;
  end;

  [Entity]
  TZZZZ = class
  private
    FId: Integer;
    FAAAA: TAAAA;
  published
    property AAAA: TAAAA read FAAAA write FAAAA;
    property Id: Integer read FId write FId;
  end;

  [Entity]
  TMyEntityWithoutPrimaryKey = class
  private
    FValue: String;
  published
    property Value: String read FValue write FValue;
  end;

  TMyEntityForeignKeyToClassWithoutPrimaryKey = class
  private
    FValue: String;
    FId: Integer;
    FForerignKey: TMyEntityWithoutPrimaryKey;
  published
    property Id: Integer read FId write FId;
    property ForerignKey: TMyEntityWithoutPrimaryKey read FForerignKey write FForerignKey;
    property Value: String read FValue write FValue;
  end;

  [Entity]
  [SingleTableInheritance]
  TMyEntityWithSingleTableInheritanceAttribute = class
  private
    FId: Integer;
    FBaseProperty: String;
  published
    property BaseProperty: String read FBaseProperty write FBaseProperty;
    property Id: Integer read FId write FId;
  end;

  [Entity]
  TMyEntityInheritedFromSingle = class(TMyEntityWithSingleTableInheritanceAttribute)
  private
    FAnotherProperty: String;
  published
    property AnotherProperty: String read FAnotherProperty write FAnotherProperty;
  end;

  [Entity]
  TMyEntityInheritedFromSimpleClass = class(TMyEntityInheritedFromSingle)
  private
    FSimpleProperty: Integer;
  published
    property SimpleProperty: Integer read FSimpleProperty write FSimpleProperty;
  end;

  TMyEntityAlias = class;

  TMyEntityWithForeignKeyAlias = class
  private
    FId: Integer;
    FForeignKey: TMyEntity;
  published
    property ForeignKey: TMyEntity read FForeignKey write FForeignKey;
    property Id: Integer read FId write FId;
  end;

  TMyEntityAlias = class
  private
    FId: Integer;
  published
    property Id: Integer read FId write FId;
  end;

  TMyEntityWithManyValueAssociation = class;

  [Entity]
  TMyEntityWithManyValueAssociationChild = class
  private
    FId: Integer;
    FManyValueAssociation: TMyEntityWithManyValueAssociation;
  published
    property Id: Integer read FId write FId;
    property ManyValueAssociation: TMyEntityWithManyValueAssociation read FManyValueAssociation write FManyValueAssociation;
  end;

  [Entity]
  TMyEntityWithManyValueAssociation = class
  private
    FId: Integer;
    FManyValueAssociation: TArray<TMyEntityWithManyValueAssociationChild>;
  published
    property Id: Integer read FId write FId;
    property ManyValueAssociation: TArray<TMyEntityWithManyValueAssociationChild> read FManyValueAssociation write FManyValueAssociation;
  end;

implementation

uses Delphi.ORM.Mapper;

{ TMapperTest }

procedure TMapperTest.EveryPropertyThatIsAnObjectMustCreateAForeignKeyInTheListOfTheTable;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.AreEqual<Integer>(2, Length(Table.ForeignKeys));

  Mapper.Free;
end;

procedure TMapperTest.OnlyPublishedFieldMutsBeLoadedInTheTable;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntity);

  Assert.AreEqual<Integer>(3, Length(Table.Fields));

  Mapper.Free;
end;

procedure TMapperTest.Setup;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  FContext.GetType(TMyEntity);

  Mapper.Free;
end;

procedure TMapperTest.TheClassWithTheSingleTableInheritanceAttributeCantBeMappedInTheTableList;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.IsNull(Mapper.FindTable(TMyEntityWithSingleTableInheritanceAttribute));

  Mapper.Free;
end;

procedure TMapperTest.TheDatabaseNameOfATableMustBeTheNameOfClassRemovingTheFirstCharOfTheClassName;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity);

  Assert.AreEqual('MyEntity', Table.DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.TheFieldInPrimaryKeyMustBeMarkedWithInPrimaryKey;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity);

  Assert.IsTrue(Table.PrimaryKey[0].InPrimaryKey);

  Mapper.Free;
end;

procedure TMapperTest.TheFieldLinkingTheParentAndChildOfManyValueAssociationMustBeLoaded;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var ChildTable := Mapper.FindTable(TMyEntityWithManyValueAssociationChild);
  var Table := Mapper.FindTable(TMyEntityWithManyValueAssociation);

  Assert.AreEqual(ChildTable.Fields[1], Table.ManyValueAssociations[0].ChildField);

  Mapper.Free;
end;

procedure TMapperTest.TheFieldOfAForeignKeyMustBeFilledWithTheFieldOfTheClassThatIsAForeignKey;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.AreEqual(Table.Fields[1], Table.ForeignKeys[0].Field);

  Mapper.Free;
end;

procedure TMapperTest.TheLoadingOfForeingKeyMustBeAfterAllTablesAreLoadedToTheFindTableWorksPropertily;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TZZZZ);

  Assert.IsNotNull(Table.ForeignKeys[0].ParentTable);

  Mapper.Free;
end;

procedure TMapperTest.TheManyValueAssociationMustLoadTheFieldThatGeneratedTheValue;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithManyValueAssociation);

  Assert.AreEqual(Table.Fields[1], Table.ManyValueAssociations[0].Field);

  Mapper.Free;
end;

procedure TMapperTest.TheParentTableMustBeTheTableLinkedToTheField;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var ParentTable := Mapper.FindTable(TMyEntityWithPrimaryKey);
  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.AreEqual(ParentTable, Table.ForeignKeys[0].ParentTable);

  Mapper.Free;
end;

procedure TMapperTest.TheTableOfManyValueAssociationMustBeTheChildTableOfThisLink;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var ChildTable := Mapper.FindTable(TMyEntityWithManyValueAssociationChild);
  var Table := Mapper.FindTable(TMyEntityWithManyValueAssociation);

  Assert.AreEqual(ChildTable, Table.ManyValueAssociations[0].ChildTable);

  Mapper.Free;
end;

procedure TMapperTest.WhenAClassDoesNotHaveThePrimaryKeyAttributeAndHasAnIdFieldThisWillBeThePrimaryKey;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity2);

  Assert.AreEqual<Integer>(1, Length(Table.PrimaryKey));
  Assert.AreEqual('Id', Table.PrimaryKey[0].DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeCantGenerateAnyForeignKey;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.AreEqual<Integer>(0, Length(Mapper.FindTable(TMyEntityInheritedFromSingle).ForeignKeys));

  Mapper.Free;
end;

procedure TMapperTest.WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeMustLoadAllFieldsInTheTable;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.AreEqual<Integer>(3, Length(Mapper.FindTable(TMyEntityInheritedFromSingle).Fields));

  Mapper.Free;
end;

procedure TMapperTest.WhenAClassIsInheritedFromAClassWithTheSingleTableInheritanceAttributeThePrimaryKeyMustBeLoadedFromTheTopClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityInheritedFromSingle);

  Assert.AreEqual<Integer>(1, Length(Table.PrimaryKey));

  Mapper.Free;
end;

procedure TMapperTest.WhenAPropertyIsAnArrayMustLoadAManyValueLink;
begin
  var Mapper := TMapper.Create;

  var Table := Mapper.LoadClass(TMyEntityWithManyValueAssociation);

  Assert.AreEqual<Integer>(1, Length(Table.ManyValueAssociations));

  Mapper.Free;
end;

procedure TMapperTest.WhenCallLoadAllMoreThemOneTimeCantRaiseAnError;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.WillNotRaise(Mapper.LoadAll);

  Mapper.Free;
end;

procedure TMapperTest.WhenCallLoadAllMustLoadAllClassesWithTheEntityAttribute;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.IsTrue(Length(Mapper.Tables) > 0, 'No entities loaded!');

  Mapper.Free;
end;

procedure TMapperTest.WhenLoadAClassMustKeepTheOrderingOfTablesToTheFindTableContinueToWorking;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadClass(TMyEntity2);

  Mapper.LoadClass(TMyEntity);

  Mapper.LoadClass(TMyEntity3);

  var Table := Mapper.FindTable(TMyEntity);

  Assert.AreSame(FContext.GetType(TMyEntity), Table.TypeInfo);

  Mapper.Free;
end;

procedure TMapperTest.WhenLoadAFieldMustFillThePropertyWithThePropertyInfo;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity3);
  var TypeInfo := FContext.GetType(TMyEntity3).GetProperties[0];

  Assert.AreEqual<TObject>(TypeInfo, Table.Fields[0].TypeInfo);

  Mapper.Free;
end;

procedure TMapperTest.WhenLoadATableMustLoadAllFieldsToo;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntity);

  Assert.AreEqual<Integer>(3, Length(Table.Fields));

  Mapper.Free;
end;

procedure TMapperTest.WhenLoadMoreThenOneTimeTheSameClassCantRaiseAnError;
begin
  var Mapper := TMapper.Create;

  Assert.WillNotRaise(
    procedure
    begin
      Mapper.LoadClass(TMyEntity);

      Mapper.LoadClass(TMyEntity);
    end);

  Mapper.Free;
end;

procedure TMapperTest.WhenMapAForeignKeyIsToAClassWithoutAPrimaryKeyMustRaiseAnError;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.WillRaise(
    procedure
    begin
      Mapper.LoadClass(TMyEntityForeignKeyToClassWithoutPrimaryKey);
    end, EClassWithoutPrimaryKeyDefined);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheChildClassIsDeclaredBeforeTheParentClassTheLinkBetweenOfTablesMustBeCreated;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithManyValueAssociation);

  Assert.AreEqual<Integer>(1, Length(Table.ManyValueAssociations));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassHaveThePrimaryKeyAttributeThePrimaryKeyWillBeTheFieldFilled;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntityWithPrimaryKey);

  Assert.AreEqual('Value', Table.PrimaryKey[0].DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassHaveTheTableNameAttributeTheDatabaseNameMustBeLikeTheNameInAttribute;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity2);

  Assert.AreEqual('AnotherTableName', Table.DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedFromANormalClassCantLoadFieldsFormTheBaseClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.AreEqual<Integer>(1, Length(Mapper.FindTable(TMyEntityInheritedFromSimpleClass).Fields));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedFromANormalClassMustCreateAForeignKeyForTheBaseClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.AreEqual<Integer>(1, Length(Mapper.FindTable(TMyEntityInheritedFromSimpleClass).ForeignKeys));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedFromANormalClassMustCreateAForeignKeyForTheBaseClassWithThePrimaryKeyFields;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityInheritedFromSimpleClass);

  var ForeignKey := Table.ForeignKeys[0];
  var PrimaryKey := Table.PrimaryKey;

  Assert.AreEqual(PrimaryKey[0], ForeignKey.Field);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedFromTObjectCantCreateAForeignKeyForThatClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  Assert.AreEqual<Integer>(0, Length(Mapper.FindTable(TMyEntity).ForeignKeys));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedMustLoadThePrimaryKeyFromBaseClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityInheritedFromSimpleClass);

  Assert.AreEqual<Integer>(1, Length(Table.PrimaryKey));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheClassIsInheritedMustShareTheSamePrimaryKeyFromTheBaseClass;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var BaseTable := Mapper.FindTable(TMyEntityInheritedFromSingle);
  var Table := Mapper.FindTable(TMyEntityInheritedFromSimpleClass);

  Assert.AreSame(BaseTable.PrimaryKey[0], Table.PrimaryKey[0]);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheFieldHaveTheFieldNameAttributeMustLoadThisNameInTheDatabaseName;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.AreEqual('AnotherFieldName', Table.Fields[0].DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheFieldIsAClassMustFillTheDatabaseNameWithIdPlusPropertyName;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.AreEqual('IdMyForeignKey', Table.Fields[1].DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheFieldsAreLoadedMustFillTheNameWithTheNameOfPropertyOfTheClass;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity3);

  Assert.AreEqual('Id', Table.Fields[0].DatabaseName);

  Mapper.Free;
end;

procedure TMapperTest.WhenTheForeignKeyIsAClassAliasMustLoadTheForeignClassAndLinkToForeignKey;
begin
  var Mapper := TMapper.Create;

  var Table := Mapper.LoadClass(TMyEntityWithForeignKeyAlias);

  Assert.AreEqual<Integer>(1, Length(Table.ForeignKeys));

  Mapper.Free;
end;

procedure TMapperTest.WhenTheForeignKeyIsCreatesMustLoadTheParentTable;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithFieldNameAttribute);

  Assert.IsNotNull(Table.ForeignKeys[0].ParentTable);

  Mapper.Free;
end;

procedure TMapperTest.WhenThePrimaryKeyAttributeHasMoreThanOneFieldHasToPutEveryoneOnTheList;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntityWithPrimaryKey2);

  Assert.AreEqual<Integer>(2, Length(Table.PrimaryKey));

  Mapper.Free;
end;

procedure TMapperTest.WhenTryToFindATableMustReturnTheTableOfTheClass;
begin
  var Mapper := TMapper.Create;
  var Table := Mapper.LoadClass(TMyEntity3);

  Assert.AreEqual(TMyEntity3, Table.TypeInfo.MetaclassType);

  Mapper.Free;
end;

procedure TMapperTest.WhenTryToFindATableWithoutTheEntityAttributeMustReturnANilValue;
begin
  var Mapper := TMapper.Create;

  Mapper.LoadAll;

  var Table := Mapper.FindTable(TMyEntityWithoutEntityAttribute);

  Assert.IsNull(Table);

  Mapper.Free;
end;

end.

