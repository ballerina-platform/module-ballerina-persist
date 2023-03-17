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

public type AllTypesOptionalized record {|
    int id?;
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

public type StringIdRecord record {|
    readonly string id;
    string randomField;
|};

public type StringIdRecordOptionalized record {|
    string id?;
    string randomField?;
|};

public type StringIdRecordTargetType typedesc<StringIdRecordOptionalized>;

public type StringIdRecordInsert StringIdRecord;

public type StringIdRecordUpdate record {|
    string randomField?;
|};

public type IntIdRecord record {|
    readonly int id;
    string randomField;
|};

public type IntIdRecordOptionalized record {|
    int id?;
    string randomField?;
|};

public type IntIdRecordTargetType typedesc<IntIdRecordOptionalized>;

public type IntIdRecordInsert IntIdRecord;

public type IntIdRecordUpdate record {|
    string randomField?;
|};

public type FloatIdRecord record {|
    readonly float id;
    string randomField;
|};

public type FloatIdRecordOptionalized record {|
    float id?;
    string randomField?;
|};

public type FloatIdRecordTargetType typedesc<FloatIdRecordOptionalized>;

public type FloatIdRecordInsert FloatIdRecord;

public type FloatIdRecordUpdate record {|
    string randomField?;
|};

public type DecimalIdRecord record {|
    readonly decimal id;
    string randomField;
|};

public type DecimalIdRecordOptionalized record {|
    decimal id?;
    string randomField?;
|};

public type DecimalIdRecordTargetType typedesc<DecimalIdRecordOptionalized>;

public type DecimalIdRecordInsert DecimalIdRecord;

public type DecimalIdRecordUpdate record {|
    string randomField?;
|};

public type BooleanIdRecord record {|
    readonly boolean id;
    string randomField;
|};

public type BooleanIdRecordOptionalized record {|
    boolean id?;
    string randomField?;
|};

public type BooleanIdRecordTargetType typedesc<BooleanIdRecordOptionalized>;

public type BooleanIdRecordInsert BooleanIdRecord;

public type BooleanIdRecordUpdate record {|
    string randomField?;
|};

public type CompositeAssociationRecord record {|
    readonly string id;
    string randomField;
    boolean alltypesidrecordBooleanType;
    int alltypesidrecordIntType;
    float alltypesidrecordFloatType;
    decimal alltypesidrecordDecimalType;
    string alltypesidrecordStringType;
|};

public type CompositeAssociationRecordOptionalized record {|
    string id?;
    string randomField?;
    boolean alltypesidrecordBooleanType?;
    int alltypesidrecordIntType?;
    float alltypesidrecordFloatType?;
    decimal alltypesidrecordDecimalType?;
    string alltypesidrecordStringType?;
|};

public type CompositeAssociationRecordWithRelations record {|
    *CompositeAssociationRecordOptionalized;
    AllTypesIdRecordOptionalized allTypesIdRecord?;
|};

public type CompositeAssociationRecordTargetType typedesc<CompositeAssociationRecordWithRelations>;

public type CompositeAssociationRecordInsert CompositeAssociationRecord;

public type CompositeAssociationRecordUpdate record {|
    string randomField?;
    boolean alltypesidrecordBooleanType?;
    int alltypesidrecordIntType?;
    float alltypesidrecordFloatType?;
    decimal alltypesidrecordDecimalType?;
    string alltypesidrecordStringType?;
|};

public type AllTypesIdRecord record {|
    readonly boolean booleanType;
    readonly int intType;
    readonly float floatType;
    readonly decimal decimalType;
    readonly string stringType;
    string randomField;
|};

public type AllTypesIdRecordOptionalized record {|
    boolean booleanType?;
    int intType?;
    float floatType?;
    decimal decimalType?;
    string stringType?;
    string randomField?;
|};

public type AllTypesIdRecordWithRelations record {|
    *AllTypesIdRecordOptionalized;
    CompositeAssociationRecordOptionalized compositeAssociationRecord?;
|};

public type AllTypesIdRecordTargetType typedesc<AllTypesIdRecordWithRelations>;

public type AllTypesIdRecordInsert AllTypesIdRecord;

public type AllTypesIdRecordUpdate record {|
    string randomField?;
|};
