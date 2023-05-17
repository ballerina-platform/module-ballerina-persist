// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;

# Represents the metadata of an entity.
#
# + entityName - Name of the entity
# + tableName - Table name of the entity
# + fieldMetadata - Metadata of all the fields of the entity
# + keyFields - Names of the identity fields
# + joinMetadata - Metadata of the fields that are used for `JOIN` operations
public type SQLMetadata record {|
    string entityName;
    sql:ParameterizedQuery tableName;
    map<FieldMetadata> fieldMetadata;
    string[] keyFields;
    map<JoinMetadata> joinMetadata?;
|};

public type TableMetadata record {|
    string[] keyFields;
    isolated function (string[]) returns stream<record {}, Error?> query;
    isolated function (anydata) returns record {}|NotFoundError queryOne;
    map<isolated function (record {}, string[]) returns record {}[]> associationsMethods = {};
|};

public type SheetMetadata record {|
    string entityName;
    string tableName;
    map<SheetFieldMetadata> fieldMetadata;
    string[] keyFields;
    string range;
    map<string> dataTypes = {};
    function (string[]) returns stream<record {}, Error?>|Error query;
    function (anydata) returns record {}|InvalidKeyError queryOne;
    map<function (record {}, string[]) returns record {}[]|Error> associationsMethods = {};
|};

# Represents the metadata associated with a simple field in the entity record.
#
# + columnName - The name of the SQL table column to which the field is mapped
# + columnId - The alphabetical Id of the column
public type SimpleSheetFieldMetadata record {|
    string columnName;
    string columnId;
|};

# Represents the metadata associated with a field from a related entity.
#
# + relation - The relational metadata associated with the field
public type EntityFieldMetadata record {|
    RelationMetadata relation;
|};

# Represents the metadata associated with a field of an entity.
# Only used by the generated persist clients and `persist:SQLClient`.
#
public type SheetFieldMetadata SimpleSheetFieldMetadata;

# Represents the metadata associated with a simple field in the entity record.
#
# + columnName - The name of the SQL table column to which the field is mapped
public type SimpleFieldMetadata record {|
    string columnName;
|};

# Represents the metadata associated with a field from a related entity.
#
# + relation - The relational metadata associated with the field
public type SheetEntityFieldMetadata record {|
    SheetRelationMetadata relation;
|};

# Represents the metadata associated with a field of an entity.
# Only used by the generated persist clients and `persist:SQLClient`.
#
public type FieldMetadata SimpleFieldMetadata|EntityFieldMetadata;

# Represents the metadata associated with a relation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + entityName - The name of the entity represented in the relation  
# + refField - The name of the referenced column in the soogle sheets table
# + columnId - The alphabetical Id of the column

public type SheetRelationMetadata record {|
    string entityName;
    string refField;
    string columnId;
|};

# Represents the metadata associated with a relation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + entityName - The name of the entity represented in the relation  
# + refField - The name of the referenced column in the SQL table

public type RelationMetadata record {|
    string entityName;
    string refField;
|};

# Represents the metadata associated with performing an SQL `JOIN` operation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + entity - The name of the entity that is being joined  
# + fieldName - The name of the field in the `entity` that is being joined  
# + refTable - The name of the SQL table to be joined  
# + refColumns - The names of the referenced columns of the referenced table
# + joinColumns - The names of the join columns
# + joinTable - The name of the joining table used for a many-to-many relation
# + joiningRefColumns - The names of the referenced columns in the joining table     
# + joiningJoinColumns - The names of the join columns in the joining table     
# + 'type - The type of the relation
public type JoinMetadata record {|
    typedesc<record {}> entity;
    string fieldName;
    string refTable;
    string[] refColumns;
    string[] joinColumns;
    string joinTable?;
    string[] joiningRefColumns?;
    string[] joiningJoinColumns?;
    JoinType 'type;
|};

# Represents the type of the relation used in a `JOIN` operation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + ONE_TO_ONE - The association type is a one-to-one association
# + ONE_TO_MANY - The entity is in the 'one' side of a one-to-many association
# + MANY_TO_ONE - The entity is in the 'many' side of a one-to-many association
public enum JoinType {
    ONE_TO_ONE,
    ONE_TO_MANY,
    MANY_TO_ONE
}
