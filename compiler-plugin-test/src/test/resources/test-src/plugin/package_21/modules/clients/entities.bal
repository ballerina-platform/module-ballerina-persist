import ballerina/time;
import ballerina/persist;

@persist:Entity {
    key: ["needId"],
    tableName: "MedicalItem"
}
public type MedicalNeed1 record {|
    @persist:AutoIncrement
    readonly int needId = -1;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

@persist:Entity {
    key: ["needId"],
    uniqueConstraints: [["beneficiaryId", "urgency"]],
    tableName: "MedicalNeeds"
}
public type MedicalNeed record {|
    @persist:AutoIncrement
    readonly int needId = 1;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};
