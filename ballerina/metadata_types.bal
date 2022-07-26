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

# Represents the metadata associated with a field of an entity.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + columnName - The name of the SQL table column to which the field is mapped. `()` if the field is not present in the table
# + 'type - The data type of the field  
# + autoGenerated - If true, the value of the field is not defined on creation 
#                   but is instead generated by the SQL database
# + relation - If the field is from another entity, the relational metadata associated with it
public type FieldMetadata record {|
    string? columnName = ();
    typedesc 'type;
    boolean autoGenerated = false;
    RelationMetadata? relation = ();
|};

# Represents the metadata associated with a relation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + entityName - The name of the entity represented in the relation  
# + refTable - The name of the SQL table, which contains the referenced column 
# + refField - The name of the field in the `entityName` that is referenced
public type RelationMetadata record {|
    string entityName;
    string refTable;
    string refField;
|};

# Represents the metadata associated with performing an SQL `JOIN` operation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + entity - The name of the entity that is being joined  
# + fieldName - The name of the field in the `entity` that is being joined  
# + refTable - The name of the SQL table to be joined  
# + refFields - The names of the fields to be used in the JOIN `WHERE` operation  
# + joinColumns - The names of the SQL table columns to be used in the JOIN `WHERE` operation    
# + 'type - The type of the relation
public type JoinMetadata record {|
    typedesc<record {}> entity;
    string fieldName;
    string refTable;
    string[] refFields;
    string[] joinColumns;
    JoinType 'type = ONE;
|};

# Represents the type of the relation used in a `JOIN` operation.
# Only used by the generated persist clients and `persist:SQLClient`.
#
# + ONE - The one side of a one-to-one or one-to-many relation
# + MANY - The many side of a one-to-many or many-to-many relation
public enum JoinType {
    ONE,
    MANY
}
