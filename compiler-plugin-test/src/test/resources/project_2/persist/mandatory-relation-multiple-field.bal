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
|};

type Building1 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
|};

type Workspace1 record {|
    readonly string workspaceId;
    string workspaceType;
    Building1 location;
    Building1 building;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace2? workspace2;
    Workspace2[] workspaces;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    Building2 location;
    Building2 building;
|};

type Building3 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace3? workspace2;
    Workspace3[] workspaces;
|};

type Workspace3 record {|
    readonly string workspaceId;
    string workspaceType;
    Building3 location;
    Building3 building;
    Building3 testBuilding;
|};

type Building4 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace4? workspace2;
    Workspace4[] workspace;
    Workspace4[] workspaces;
|};

type Workspace4 record {|
    readonly string workspaceId;
    string workspaceType;
    Building4 location;
    Building4 building;
|};
