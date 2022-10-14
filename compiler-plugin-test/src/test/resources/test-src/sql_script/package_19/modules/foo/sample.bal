import ballerina/persist;
import package_22 as entities;

@persist:Entity {
    key: ["id"],
    tableName: "MultipleAssociations"
}
public type MultipleAssociations record {|
    readonly int id;
    string name;

    @persist:Relation {keyColumns: ["profileId"], reference: ["id"]}
    entities:Profile profile?;

    @persist:Relation {keyColumns: ["userId"], reference: ["id"]}
    entities:User user?;
|};