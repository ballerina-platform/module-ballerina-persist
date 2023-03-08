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
    Building? building;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    Building2 location;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace2[]? workspaces;
|};

type Building3 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace3 workspaces;
|};

type Workspace3 record {|
    readonly string workspaceId;
    string workspaceType;
    Building3 building;
|};

type Workspace4 record {|
    readonly string workspaceId;
    string workspaceType;
    Building4 location;
|};

type Building4 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace4? workspaces;
|};
