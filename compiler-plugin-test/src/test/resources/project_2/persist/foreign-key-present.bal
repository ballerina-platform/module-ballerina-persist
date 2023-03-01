import ballerina/persist as _;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspaceWorkspaceId;
    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    string buildingBuildingCode;
    Building building;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    string building2BuildingCode;
    Building2 location;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspace2WorkspaceId;
    Workspace2[] workspaces;
|};

type Building3 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspace3WorkspaceId;
    Workspace3 workspaces;
|};

type Workspace3 record {|
    readonly string workspaceId;
    string workspaceType;
    string building3BuildingCode;
    Building3 building;
|};

type Workspace4 record {|
    readonly string workspaceId;
    string workspaceType;
    string building4BuildingCode;
    Building4 location;
|};

type Building4 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspace4WorkspaceId;
    Workspace4 workspaces;
|};
