import ballerina/persist as _;

type User record {|
    readonly int userId;
    string name;
    int age;
    string follow;
	Follow? follow1;
|};

type Follow record {|
    readonly int followId;
    User leader;
|};
