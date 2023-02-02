import ballerina/persist as _;

type Building record {|
    readonly string 'buildingCode;
    string city;
    string state;
    string country;
    'string postalCode;

    Workspace[] workspaces;
|};

type building record {|
    readonly string 'buildingCode;
    string city;
    string state;
    string country;
    'string postalCode;

    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    Building location;
    string Location;
|};

