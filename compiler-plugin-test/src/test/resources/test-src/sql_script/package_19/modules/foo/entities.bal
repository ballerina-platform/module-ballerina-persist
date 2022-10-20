import ballerina/persist;

@persist:Entity {
    key: ["id"],
    tableName: "Users"
}
public type User record  {|
    readonly int id;
    string name;
|};
