import ballerina/persist as _;

type Integer int;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Integer[] workspaces;
|};
