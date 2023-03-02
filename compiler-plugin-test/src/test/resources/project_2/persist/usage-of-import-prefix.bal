import ballerina/time as time2;
import ballerina/persist as _;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    time2:Date completionDate;
|};
