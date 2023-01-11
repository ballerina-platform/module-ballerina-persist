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

# Defines the attributes of an entity.
#
# + key - A single field or multiple fields that are used as the key to identify each instance of the entity
# + uniqueConstraints - The set of single or multiple fields that uniquely identify each instance of the entity
public type EntityConfig record {|
    string[] key;
    string[][] uniqueConstraints?;
|};

# The annotation used to indicate a record-type as an `Entity`.
public const annotation EntityConfig Entity on source type;

# Defines the auto-increment field configuration.
#
# + startValue - The starting value of the field
# + increment - A positive integer, which is used as the increment when generating
#               the unique number in the field when a new instance of the entity is created
public type AutoIncrementConfig record {|
    int startValue = 1;
    int increment = 1;
|};

# The annotation used to indicate an auto-increment field.
public const annotation AutoIncrementConfig AutoIncrement on source record field;

# Defines a relationship between two entities.
#
# + name - specify the name of the relationship 
# + fields - a list of fields of the current record 
# + referencedFields - a list of fields of the referenced record 
# + onDelete - enforced referential action on delete 
# + onUpdate - enforced referential action on delete
public type RelationConfig record {|
   string name?;
   string[] fields?;
   string[] referencedFields?;
   ReferenceAction onDelete?;
   ReferenceAction onUpdate?;
|};


# Defines the actions that can be taken when deleting or updating the values of the parent entity.
public enum ReferenceAction {
    RESTRICT,
    CASCADE,
    SET_NULL,
    NO_ACTION,
    SET_DEFAULT
}

# The annotation is used to indicate the associations of an entity. In one-to-one and one-to-many associations, this is
# to be used only in the parent entity (the 'one' side of the association).
public const annotation RelationConfig Relation on source record field;
