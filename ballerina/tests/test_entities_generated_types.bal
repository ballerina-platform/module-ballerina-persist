import ballerina/time;

public type AllTypes record {|
    readonly int id;
    boolean booleanType;
    int intType;
    float floatType;
    decimal decimalType;
    string stringType;
    byte[] byteArrayType;
    time:Date dateType;
    time:TimeOfDay timeOfDayType;
    time:Civil civilType;
    boolean? booleanTypeOptional;
    int? intTypeOptional;
    float? floatTypeOptional;
    decimal? decimalTypeOptional;
    string? stringTypeOptional;
    time:Date? dateTypeOptional;
    time:TimeOfDay? timeOfDayTypeOptional;
    time:Civil? civilTypeOptional;
|};

public type AllTypesInsert AllTypes;

public type AllTypesUpdate record {|
    boolean booleanType?;
    int intType?;
    float floatType?;
    decimal decimalType?;
    string stringType?;
    byte[] byteArrayType?;
    time:Date dateType?;
    time:TimeOfDay timeOfDayType?;
    time:Civil civilType?;
    boolean? booleanTypeOptional?;
    int? intTypeOptional?;
    float? floatTypeOptional?;
    decimal? decimalTypeOptional?;
    string? stringTypeOptional?;
    time:Date? dateTypeOptional?;
    time:TimeOfDay? timeOfDayTypeOptional?;
    time:Civil? civilTypeOptional?;
|};

public type AllTypesOptionalized record {|
    readonly int id?;
    boolean booleanType?;
    int intType?;
    float floatType?;
    decimal decimalType?;
    string stringType?;
    byte[] byteArrayType?;
    time:Date dateType?;
    time:TimeOfDay timeOfDayType?;
    time:Civil civilType?;
    boolean? booleanTypeOptional?;
    int? intTypeOptional?;
    float? floatTypeOptional?;
    decimal? decimalTypeOptional?;
    string? stringTypeOptional?;
    time:Date? dateTypeOptional?;
    time:TimeOfDay? timeOfDayTypeOptional?;
    time:Civil? civilTypeOptional?;
|};

public type AllTypesTargetType typedesc<AllTypesOptionalized>;

public type StringIdRecord record {|
    readonly string id;
    string randomField;
|};

public type StringIdRecordInsert StringIdRecord;

public type StringIdRecordUpdate record {|
    string randomField?;
|};

public type StringIdRecordOptionalized record {|
    readonly string id?;
    string randomField?;
|};

public type StringIdRecordTargetType typedesc<StringIdRecordOptionalized>;

public type IntIdRecord record {|
    readonly int id;
    string randomField;
|};

public type IntIdRecordInsert IntIdRecord;

public type IntIdRecordUpdate record {|
    string randomField?;
|};

public type IntIdRecordOptionalized record {|
    readonly int id?;
    string randomField?;
|};

public type IntIdRecordTargetType typedesc<IntIdRecordOptionalized>;

public type FloatIdRecord record {|
    readonly float id;
    string randomField;
|};

public type FloatIdRecordInsert FloatIdRecord;

public type FloatIdRecordUpdate record {|
    string randomField?;
|};

public type FloatIdRecordOptionalized record {|
    readonly float id?;
    string randomField?;
|};

public type FloatIdRecordTargetType typedesc<FloatIdRecordOptionalized>;

public type DecimalIdRecord record {|
    readonly decimal id;
    string randomField;
|};

public type DecimalIdRecordInsert DecimalIdRecord;

public type DecimalIdRecordUpdate record {|
    string randomField?;
|};

public type DecimalIdRecordOptionalized record {|
    readonly decimal id?;
    string randomField?;
|};

public type DecimalIdRecordTargetType typedesc<DecimalIdRecordOptionalized>;

public type BooleanIdRecord record {|
    readonly boolean id;
    string randomField;
|};

public type BooleanIdRecordInsert BooleanIdRecord;

public type BooleanIdRecordUpdate record {|
    string randomField?;
|};

public type BooleanIdRecordOptionalized record {|
    readonly boolean id?;
    string randomField?;
|};

public type BooleanIdRecordTargetType typedesc<BooleanIdRecordOptionalized>;

public type CompositeAssociationRecord record {|
    readonly string id;
    string randomField;
    boolean alltypesidrecordBooleanType;
    int alltypesidrecordIntType;
    float alltypesidrecordFloatType;
    decimal alltypesidrecordDecimalType;
    string alltypesidrecordStringType;
|};

public type CompositeAssociationRecordInsert CompositeAssociationRecord;

public type CompositeAssociationRecordUpdate record {|
    string randomField?;
    boolean alltypesidrecordBooleanType?;
    int alltypesidrecordIntType?;
    float alltypesidrecordFloatType?;
    decimal alltypesidrecordDecimalType?;
    string alltypesidrecordStringType?;
|};

public type CompositeAssociationRecordOptionalized record {|
    readonly string id?;
    string randomField?;
    boolean alltypesidrecordBooleanType?;
    int alltypesidrecordIntType?;
    float alltypesidrecordFloatType?;
    decimal alltypesidrecordDecimalType?;
    string alltypesidrecordStringType?;
|};

public type CompositeAssociationRecordWithRelations record {|
    *CompositeAssociationRecordOptionalized;
    AllTypesIdRecord alltypesidrecord?;
|};

public type CompositeAssociationRecordTargetType typedesc<CompositeAssociationRecordWithRelations>;

public type AllTypesIdRecord record {|
    readonly boolean booleanType;
    readonly int intType;
    readonly float floatType;
    readonly decimal decimalType;
    readonly string stringType;
    string randomField;
|};

public type AllTypesIdRecordInsert AllTypesIdRecord;

public type AllTypesIdRecordUpdate record {|
    string randomField?;
|};

public type AllTypesIdRecordOptionalized record {|
    readonly boolean booleanType?;
    readonly int intType?;
    readonly float floatType?;
    readonly decimal decimalType?;
    readonly string stringType?;
    string randomField?;
|};

public type AllTypesIdRecordWithRelations record {|
    *AllTypesIdRecordOptionalized;
    CompositeAssociationRecord compositeassociationrecord?;
|};

public type AllTypesIdRecordTargetType typedesc<AllTypesIdRecordWithRelations>;
