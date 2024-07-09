import ballerina/time;
import ballerinax/java.jdbc;
import ballerina/persist as _;

public enum Gender {
    M,
    F
}

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

    jdbc:Client clientType;
    jdbc:Client[] clientArrayType;

    Gender gender;
    Gender[] genderArray;
|};
