import ballerina/time;
import ballerina/persist;

@persist:Entity {
    key: ["needId"],
    tableName: "MedicalItem"
}
public type MedicalItem record {|
    @persist:AutoIncrement
    readonly int needId = -1;

    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};
