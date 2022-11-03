import ballerina/time;
import ballerina/persist;

@persist:Entity {
    key: ["needId"],
    tableName: "MedicalNeeds"
}
public type MedicalNeed record {|
    @persist:AutoIncrement
    readonly int needId = -1;
    int itemId;
    string name;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    string quantity;
|};

@persist:Entity {
    key: ["itemId"],
    tableName: "MedicalItems"
}
public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    int unit;
|};
