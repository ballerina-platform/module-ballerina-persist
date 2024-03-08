import ballerina/persist as _;
import ballerina/time;

enum EnumType {
    TYPE_1,
    TYPE_2,
    TYPE_3,
    TYPE_4
}

type AllTypes record {|
    readonly int id;
    boolean? booleanType;
    int? intType;
    float? floatType;
    decimal? decimalType;
    string? stringType;
    time:Date? dateType;
    time:TimeOfDay? timeOfDayType;
    EnumType? enumType;
|};