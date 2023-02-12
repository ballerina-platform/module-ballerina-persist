// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for test_entities.
// It should not be modified by hand.

import ballerina/time;

public type AllTypes record {|
    readonly string id;
    boolean booleanType;
    int intType;
    float floatType;
    decimal decimalType;
    string stringType;
    byte byteArrayType;
    time:Date dateType;
    time:TimeOfDay timeOfDayType;
    time:Utc utcType;
    time:Civil civilType;
|};

public type AllTypesInsert AllTypes;

public type AllTypesUpdate record {|
    boolean booleanType?;
    int intType?;
    float floatType?;
    decimal decimalType?;
    string stringType?;
    byte byteArrayType?;
    time:Date dateType?;
    time:TimeOfDay timeOfDayType?;
    time:Utc utcType?;
    time:Civil civilType?;
|};

