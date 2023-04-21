import ballerina/persist as _;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspacesWorkspaceId;
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
    string locationBuildingCode;
    Building2 location;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspacesWorkspaceId;
    Workspace2[] workspaces;
|};

type Building3 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspacesWorkspaceId;
    Workspace3 workspaces;
|};

type Workspace3 record {|
    readonly string workspaceId;
    string workspaceType;
    string buildingBuildingCode;
    Building3? building;
|};

type Workspace4 record {|
    readonly string workspaceId;
    string workspaceType;
    string locationBuildingCode;
    Building4? location;
|};

type Building4 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string workspacesWorkspaceId;
    Workspace4 workspaces;
|};
