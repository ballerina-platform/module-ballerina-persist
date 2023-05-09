import ballerina/time;
import ballerina/persist as _;

public enum EnumType {
	TYPE_1,
	TYPE_2
}

public type MedicalNeed record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    EnumType enumType;
|};

public type MedicalNeed2 record {
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
};
