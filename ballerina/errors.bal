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

# Represents an error that occurs when an attempt is to perform an operation, which violates a foreign key constraint.
public type ForeignKeyConstraintViolationError distinct Error;

# Represents an error that occurs when an attempt is made to retrieve a record using a key, which does not exist.
public type InvalidKeyError distinct Error;

# This error is thrown when the user attempts to create a record which already exists in the database.
public type DuplicateKeyError distinct Error;
