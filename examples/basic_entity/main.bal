import ballerina/io;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

public function main() returns error? {
    MedicalNeedClient mnClient = check new();
    int id = check mnClient->create({
        itemId: 1,
        beneficiaryId: 1,
        period: {year: 2022, month: 10, day: 10, hour: 0, minute: 0},
        urgency: "URGENT",
        quantity: 5
    });
    io:println(id);

    MedicalNeed need = check mnClient->readByKey(id);
    io:println(need);

    stream<MedicalNeed, error?> medicalNeedStream = check mnClient->read({itemId: 1, urgency: "URGENT"});
    _ = check from MedicalNeed x in medicalNeedStream
        do {
            io:println(x);
        };

    check mnClient->update({beneficiaryId: 2, quantity: 10}, {itemId: 1, urgency: "URGENT"});
    medicalNeedStream = check mnClient->read({itemId: 1, urgency: "URGENT"});
    _ = check from MedicalNeed x in medicalNeedStream
        do {
            io:println(x);
        };

    check mnClient->delete({itemId: 1, urgency: "URGENT"});
    medicalNeedStream = check mnClient->read({itemId: 1, urgency: "URGENT"});
    _ = check from MedicalNeed x in medicalNeedStream
        do {
            io:println(x);
        };



    MedicalItemClient miClient = check new();
    id = check miClient->create({
        itemId: 1,
        name: "item1",
        'type: "liquid",
        unit: "ml"
    });
    io:println(id);

    MedicalItem item = check miClient->readByKey(1);
    io:println(item);

    stream<MedicalItem, error?> medicalItemStream = check miClient->read({'type: "liquid", unit: "ml"});
    _ = check from MedicalItem x in medicalItemStream
        do {
            io:println(x);
        };

    check miClient->update({name: "item2"}, {'type: "liquid", unit: "ml"});
    medicalItemStream = check miClient->read({'type: "liquid", unit: "ml"});
    _ = check from MedicalItem x in medicalItemStream
        do {
            io:println(x);
        };

    check miClient->delete({'type: "liquid", unit: "ml"});
    medicalItemStream = check miClient->read({'type: "liquid", unit: "ml"});
    _ = check from MedicalItem x in medicalItemStream
        do {
            io:println(x);
        };
}
