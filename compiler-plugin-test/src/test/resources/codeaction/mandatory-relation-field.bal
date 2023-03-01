import ballerina/persist as _;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
	Building building;
|};

type Building1 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    Building1 location;
|};