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
    time:Utc utcType;
    time:Civil civilType;
    boolean? booleanTypeOptional;
    int? intTypeOptional;
    float? floatTypeOptional;
    decimal? decimalTypeOptional;
    string? stringTypeOptional;
    time:Date dateTypeOptional;
    time:TimeOfDay timeOfDayTypeOptional;
    time:Utc utcTypeOptional;
    time:Civil civilTypeOptional;
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
    time:Utc utcType?;
    time:Civil civilType?;
    boolean? booleanTypeOptional?;
    int? intTypeOptional?;
    float? floatTypeOptional?;
    decimal? decimalTypeOptional?;
    string? stringTypeOptional?;
    time:Date? dateTypeOptional?;
    time:TimeOfDay? timeOfDayTypeOptional?;
    time:Utc? utcTypeOptional?;
    time:Civil? civilTypeOptional?;
|};

public type StringIdRecord record {|
    readonly string id;
    string randomField;
|};

public type StringIdRecordInsert StringIdRecord;

public type StringIdRecordUpdate record {|
    string randomField?;
|};

public type IntIdRecord record {|
    readonly int id;
    string randomField;
|};

public type IntIdRecordInsert IntIdRecord;

public type IntIdRecordUpdate record {|
    string randomField?;
|};

public type FloatIdRecord record {|
    readonly float id;
    string randomField;
|};

public type FloatIdRecordInsert FloatIdRecord;

public type FloatIdRecordUpdate record {|
    string randomField?;
|};

public type DecimalIdRecord record {|
    readonly decimal id;
    string randomField;
|};

public type DecimalIdRecordInsert DecimalIdRecord;

public type DecimalIdRecordUpdate record {|
    string randomField?;
|};

public type BooleanIdRecord record {|
    readonly boolean id;
    string randomField;
|};

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

public type AllTypesIdRecordInsert AllTypesIdRecord;

public type AllTypesIdRecordUpdate record {|
    string randomField?;
|};
