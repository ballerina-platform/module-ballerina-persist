import ballerina/time;
import ballerina/persist as _;

public type MedicalNeed record {|
    readonly int needId;
    boolean booleanTest;
    int itemId;
    float floatTest;
    decimal decimalTest;
    string beneficiaryId;
    byte[] beneficiaryIdByteArray;

    boolean[] booleanArray;

    json jsonTest;
    byte[] jsonArray;

    time:Civil period;
    time:Civil[] periodArray;
    time:Civil|string unionType;
|};
