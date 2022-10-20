import ballerina/persist;
import package_18;

@persist:Entity {
    key: ["id"],
    tableName: "MultipleAssociations"
}
public type MultipleAssociations record {|
    readonly int id;
    string name;

    @persist:Relation {keyColumns: ["profileId"], reference: ["id"]}
    package_18:Profile profile?;

    @persist:Relation {keyColumns: ["userId"], reference: ["id"]}
    package_18:User user?;
|};
