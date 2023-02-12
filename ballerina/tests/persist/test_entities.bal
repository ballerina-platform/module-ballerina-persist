import ballerina/time;

type AllTypes record {|
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
|}
