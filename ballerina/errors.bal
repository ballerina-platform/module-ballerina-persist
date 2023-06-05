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

# Defines the generic error type for the `persist` module.
public type Error distinct error;

# Represents an error that occurs when an attempt is made to perform an operation, which violates a foreign key constraint.
public type ConstraintViolationError distinct Error;

# Represents an error that occurs when an attempt is made to retrieve a record using a non-existing key.
public type NotFoundError distinct Error;

# Represents an error that occurs when the user attempts to create a record which already exists in the database.
public type AlreadyExistsError distinct Error;

# Generates a new `persist:NotFoundError` with the given parameters.
#
# + entity - The name of the entity  
# + key - The key of the record
# + return - The generated `persist:NotFoundError`
public isolated function getNotFoundError(string entity, anydata key) returns NotFoundError {
    string message;
    if key is record {} {
        message = string `A record with the key '${key.toBalString()}' does not exist for the entity '${entity}'.`;
    } else {
        message = string `A record with the key '${key.toString()}' does not exist for the entity '${entity}'.`;
    }
    return error NotFoundError(message);
}

# Generates a new `persist:AlreadyExistsError` with the given parameters.
#
# + entity - The name of the entity  
# + key - The key of the record
# + return - The generated `persist:AlreadyExistsError`
public isolated function getAlreadyExistsError(string entity, anydata key) returns AlreadyExistsError {
    string message;
    if key is record {} {
        message = string `A record with the key '${key.toBalString()}' already exists for the entity '${entity}'.`;
    } else {
        message = string `A record with the key '${key.toString()}' already exists for the entity '${entity}'.`;
    }
    return error AlreadyExistsError(message);
}
