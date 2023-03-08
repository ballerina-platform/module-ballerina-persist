import ballerina/time;

type AllTypes record {|
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
    byte[]? byteArrayTypeOptional;
    time:Date? dateTypeOptional;
    time:TimeOfDay? timeOfDayTypeOptional;
    time:Utc? utcTypeOptional;
    time:Civil? civilTypeOptional;
|};

type StringIdRecord record {|
    readonly string id;
    string randomField;
|};

type IntIdRecord record {|
    readonly int id;
    string randomField;
|};

type FloatIdRecord record {|
    readonly float id;
    string randomField;
|};

type DecimalIdRecord record {|
    readonly decimal id;
    string randomField;
|};

type BooleanIdRecord record {|
    readonly boolean id;
    string randomField;
|};

type CompositeAssociationRecord record {|
    readonly string id;
    string randomField;
    AllTypesIdRecord allTypesIdRecord;
|};

type AllTypesIdRecord record {|
    readonly boolean booleanType;
    readonly int intType;
    readonly float floatType;
    readonly decimal decimalType;
    readonly string stringType;
    string randomField;
    CompositeAssociationRecord? compositeAssociationRecord;
|};
