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

# The client used by the generated persist clients to abstract and 
# execute SQL queries that are required to perform CRUD operations.
public client class SQLClient {

    private final sql:Client dbClient;

    private string entityName;
    private sql:ParameterizedQuery tableName;
    private map<FieldMetadata> fieldMetadata;
    private string[] keyFields;

    # Initializes the `SQLClient`.
    #
    # + dbClient - The `sql:Client`, which is used to execute SQL queries
    # + entityName - The name of the entity with which the client performs CRUD operations
    # + tableName - The name of the SQL table, which is mapped to the entity
    # + keyFields - The names of the key fields of the entity
    # + fieldMetadata - The metadata associated with each field of the entity
    # + joinMetadata - The metadata associated with performing SQL `JOIN` operations
    # + return - A `persist:Error` if the client creation fails
    public function init(sql:Client dbClient, Metadata metadata) returns Error? {
        self.entityName = metadata.entityName;
        self.tableName = metadata.tableName;
        self.fieldMetadata = metadata.fieldMetadata;
        self.keyFields = metadata.keyFields;
        self.dbClient = dbClient;
    }

    # Performs a batch SQL `INSERT` operation to insert records into a table.
    #
    # + objects - The records to be inserted into the table
    # + return - An `sql:ExecutionResult[]` containing the metadata of the query execution
    #            or a `persist:Error` if the operation fails
    public isolated function runBatchInsertQuery(record {}[] objects) returns sql:ExecutionResult[]|Error {
        sql:ParameterizedQuery[] insertQueries = 
            from record {} 'object in objects
            select sql:queryConcat(`INSERT INTO `, self.tableName, ` (`, self.getInsertColumnNames(), ` ) `, `VALUES `, self.getInsertQueryParams('object));
        
        sql:ExecutionResult[]|sql:Error result = self.dbClient->batchExecute(insertQueries);

        if result is sql:Error {
            if result.message().indexOf("Duplicate entry ") != () {
                string duplicateKey = check getKeyFromDuplicateKeyErrorMessage(result.message());
                return <DuplicateKeyError>error(string `A ${self.entityName} entity with the key '${duplicateKey}' already exists.`);
            }

            return <Error>error(result.message());
        }

        return result;
    }

    # Performs an SQL `SELECT` operation to read a single record from the database.
    #
    # + rowType - The record-type to be retrieved (the record type of the entity)    
    # + key - The value of the key (to be used as the `WHERE` clauses)
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + return - A record in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, anydata key, string[] include = []) returns record {}|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, ` AS `, stringToParameterizedQuery(self.entityName)
        );

        query = sql:queryConcat(query, ` WHERE `, check self.getGetKeyWhereClauses(key));
        record {}|sql:Error result = self.dbClient->queryRow(query, rowType);

        if result is sql:NoRowsError {
            return <InvalidKeyError>error(
                string `A record does not exist for '${self.entityName}' for key ${key.toBalString()}.`);
        }

        if result is sql:Error {
            return <Error>error(result.message());
        }
        return result;
    }

    # Performs an SQL `SELECT` operation to read multiple records from the database.
    #
    # + rowType - The record-type to be retrieved (the record type of the entity)    
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, string[] include = [])
    returns stream<record {}, sql:Error?>|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, ` `, stringToParameterizedQuery(self.entityName)
        );

        stream<record {}, sql:Error?> resultStream = self.dbClient->query(query, rowType);
        return resultStream;
    }

    # Performs an SQL `UPDATE` operation to update multiple records in the database.
    #
    # + key - the key of the entity
    # + 'object - the record to be updated
    # + updateAssociations - The associations that should be updated
    # + return - `()` if the operation is performed successfully.
    # A `ForeignKeyConstraintViolationError` if the operation violates a foreign key constraint.
    # A `persist:Error` if the operation fails due to another reason.
    public isolated function runUpdateQuery(anydata key, record {} 'object, string[] updateAssociations = []) returns ForeignKeyConstraintViolationError|Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`UPDATE `, self.tableName, stringToParameterizedQuery(" " + self.entityName), ` SET`, check self.getSetClauses('object, updateAssociations));
        query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(self.getKey(key)));

        sql:ExecutionResult|sql:Error? e = self.dbClient->execute(query);
        if e is sql:Error {
            if e.message().indexOf("a foreign key constraint fails ") is () {
                return <Error>error(e.message());
            }
            else {
                return <ForeignKeyConstraintViolationError>error(e.message());
            }
        }
    }

    # Performs an SQL `DELETE` operation to delete a record from the database.
    #
    # + 'object - The record to be deleted
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(anydata 'object) returns Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`DELETE FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));
        query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(self.getKey('object)));
        sql:ExecutionResult|sql:Error e = self.dbClient->execute(query);

        if e is sql:Error {
            return <Error>error(e.message());
        }
    }

    private isolated function getKey(anydata|record {} 'object) returns record {} {
        record {} keyRecord = {};
        
        if 'object is record {} {
            foreach string key in self.keyFields {
                keyRecord[key] = 'object[key];
            }
        } else {
            keyRecord[self.keyFields[0]] = 'object;
        }
        return keyRecord;
    }

    private isolated function getInsertQueryParams(record {} 'object) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = `(`;
        int columnCount = 0;
        foreach string key in self.fieldMetadata.keys() {
            if columnCount > 0 {
                params = sql:queryConcat(params, `,`);
            }
            params = sql:queryConcat(params, `${<sql:Value>'object[key]}`);
            columnCount = columnCount + 1;
        }
        params = sql:queryConcat(params, `)`);
        return params;
    }

    private isolated function getInsertColumnNames() returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        string[] keys = self.fieldMetadata.keys();
        int columnCount = 0;
        foreach string key in keys {
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);

            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }

            params = sql:queryConcat(params, stringToParameterizedQuery(fieldMetadata.columnName));
            columnCount = columnCount + 1;
        }
        return params;
    }

    private isolated function getSelectColumnNames(string[] include) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        int columnCount = 0;

        foreach string key in self.fieldMetadata.keys() {
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }
            params = sql:queryConcat(params, stringToParameterizedQuery(self.entityName + "." + fieldMetadata.columnName + " AS `" + key + "`"));
            columnCount = columnCount + 1;
        }
        return params;
    }

    private isolated function getGetKeyWhereClauses(anydata key) returns sql:ParameterizedQuery|Error {
        map<anydata> filter = {};

        if key is record {} {
            filter = key;
        } else {
            filter[self.keyFields[0]] = key;
        }

        return check self.getWhereClauses(filter);
    }

    private isolated function getWhereClauses(map<anydata> filter, boolean ignoreFieldCheck = false) returns sql:ParameterizedQuery|Error {
        sql:ParameterizedQuery query = ` `;

        string[] keys = filter.keys();
        foreach int i in 0 ..< keys.length() {
            if i > 0 {
                query = sql:queryConcat(query, ` AND `);
            }
            if ignoreFieldCheck {
                query = sql:queryConcat(query, stringToParameterizedQuery(keys[i]), ` = ${<sql:Value>filter[keys[i]]}`);
            } else {
                query = sql:queryConcat(query, stringToParameterizedQuery(self.entityName + "."), self.getFieldParamQuery(keys[i]), ` = ${<sql:Value>filter[keys[i]]}`);
            }
        }
        return query;
    }

    private isolated function getSetClauses(record {} 'object, string[] updateAssociations = []) returns sql:ParameterizedQuery|Error {
        sql:ParameterizedQuery query = ` `;
        int count = 0;
        foreach string key in 'object.keys() {
            if !self.fieldMetadata.hasKey(key) {
                continue;
            }

            sql:ParameterizedQuery|InvalidInsertionError fieldName = self.getFieldParamQuery(key);
            if fieldName is sql:ParameterizedQuery {
                if count > 0 {
                    query = sql:queryConcat(query, `, `);
                }
                query = sql:queryConcat(query, fieldName, ` = ${<sql:Value>'object[key]}`);
                count = count + 1;
            }
        }
        return query;
    }

    private isolated function getFieldParamQuery(string fieldName) returns sql:ParameterizedQuery {
        FieldMetadata fieldMetadata = self.fieldMetadata.get(fieldName);
        return stringToParameterizedQuery(fieldMetadata.columnName);
    }

}

# Represents the abstract persist client. This abstract object is used in the generated client.
public type AbstractPersistClient distinct object {
};
