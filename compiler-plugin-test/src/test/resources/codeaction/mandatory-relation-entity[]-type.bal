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

type Workspace1 record {|
    readonly string workspaceId;
    string workspaceType;
    Building1 location;
|};

type Building2 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace2? workspace2;
|};

type Workspace2 record {|
    readonly string workspaceId;
    string workspaceType;
    Building2 location;
|};

type Building3 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace3? workspace2;
|};

type Workspace3 record {|
    readonly string workspaceId;
    string workspaceType;
    Building3 location;
    Building3? building;
|};

type Building4 record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    Workspace4? workspace2;
    Workspace4[] workspace;
|};

type Workspace4 record {|
    readonly string workspaceId;
    string workspaceType;
    Building4 location;
|};
