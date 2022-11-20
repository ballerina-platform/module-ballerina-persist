import ballerina/time;
import ballerina/persist;

@persist:Entity {
    key: ["needId"],
    tableName: "Stores"
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
    tableName: "Stores"
}
public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    int unit;
|};
