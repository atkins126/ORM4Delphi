﻿unit Delphi.ORM.Attributes;

interface

type
  EntityAttribute = class(TCustomAttribute);

  TCustomNameAttribute = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(Name: String);

    property Name: String read FName write FName;
  end;

  AutoGeneratedAttribute = class(TCustomAttribute);
  FieldNameAttribute = class(TCustomNameAttribute);
  ManyValueAssociationLinkNameAttribute = class(TCustomNameAttribute);
  PrimaryKeyAttribute = class(TCustomNameAttribute);
  SingleTableInheritanceAttribute = class(TCustomAttribute);
  TableNameAttribute = class(TCustomNameAttribute);

implementation

uses System.SysUtils;

{ TCustomNameAttribute }

constructor TCustomNameAttribute.Create(Name: String);
begin
  inherited Create;

  FName := Name;
end;

end.
