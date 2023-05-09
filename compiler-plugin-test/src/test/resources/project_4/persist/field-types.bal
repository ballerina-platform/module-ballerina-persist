import ballerina/time;
import ballerinax/mysql;
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
    json[] jsonArray;

    time:Civil period;
    time:Civil[] periodArray;
    time:Civil|string unionType;

    error errorType;
    error[] errorArrayType;

    mysql:Client clientType;
    mysql:Client[] clientArrayType;
|};
