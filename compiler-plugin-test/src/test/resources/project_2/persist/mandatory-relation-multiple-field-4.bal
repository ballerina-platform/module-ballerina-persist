import ballerina/persist as _;

type User record {|
    readonly int userId;
    string name;
    int age;
    string follow;
|};

type Follow record {|
    readonly int followId;
    User leader;
|};
