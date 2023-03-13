import ballerina/persist as _;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace[] workspaces;
    Workspace workspace;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    Building building;
    Building? location;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace2 workspace2;
    Workspace2 workspace;
    Workspace2 workspaces;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    Building2? location;
    Building2[] building;
    Building2[] building2;
|};
