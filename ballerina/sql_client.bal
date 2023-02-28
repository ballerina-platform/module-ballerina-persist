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
    private map<JoinMetadata> joinMetadata = {};

    # Initializes the `SQLClient`.
    #
    # + dbClient - The `sql:Client`, which is used to execute SQL queries
    # + metadata - Metadata of the entity
    # + return - A `persist:Error` if the client creation fails
    public function init(sql:Client dbClient, Metadata metadata) returns Error? {
        self.entityName = metadata.entityName;
        self.tableName = metadata.tableName;
        self.fieldMetadata = metadata.fieldMetadata;
        self.keyFields = metadata.keyFields;
        self.dbClient = dbClient;
        if metadata.joinMetadata is map<JoinMetadata> {
            self.joinMetadata = <map<JoinMetadata>>metadata.joinMetadata;
        }
    }

    # Performs a batch SQL `INSERT` operation to insert entity instances into a table.
    #
    # + insertRecords - The entity records to be inserted into the table
    # + return - An `sql:ExecutionResult[]` containing the metadata of the query execution
    #            or a `persist:Error` if the operation fails
    public isolated function runBatchInsertQuery(record {}[] insertRecords) returns sql:ExecutionResult[]|Error {
        sql:ParameterizedQuery[] insertQueries = 
            from record {} insertRecord in insertRecords
            select sql:queryConcat(`INSERT INTO `, self.tableName, ` (`, self.getInsertColumnNames(), ` ) `, `VALUES `, self.getInsertQueryParams(insertRecord));
        
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

    # Performs an SQL `SELECT` operation to read a single entity record from the database.
    #
    # + rowType - The type description of the entity to be retrieved
    # + key - The value of the key (to be used as the `WHERE` clauses)
    # + fields - The fields to be retrieved
    # + return - A record in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, anydata key, string[] fields = []) returns record {}|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(fields, []), ` FROM `, self.tableName, ` AS `, stringToParameterizedQuery(self.entityName)
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

    # Performs an SQL `SELECT` operation to read multiple entity records from the database.
    #
    # + rowType - The type description of the entity to be retrieved
    # + fields - The fields to be retrieved
    # + include - The associations to be retrieved
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, string[] fields = [], string[] include = [])
    returns stream<record {}, sql:Error?>|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(fields, include), ` FROM `, self.tableName, ` `, stringToParameterizedQuery(self.entityName)
        );

        string[] joinKeys = self.joinMetadata.keys();
        foreach string joinKey in joinKeys {
            if include.indexOf(joinKey) != () {
                JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
                if joinMetadata.'type == MANY_TO_MANY || joinMetadata.'type == MANY_TO_ONE {
                    continue;
                }
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey),
                                        ` ON `, check self.getJoinFilters(joinKey, joinMetadata.refColumns, <string[]>joinMetadata.joinColumns));
            }
        }

        stream<record {}, sql:Error?> resultStream = self.dbClient->query(query, rowType);
        return resultStream;
    }

    # Performs an SQL `UPDATE` operation to update multiple entity records in the database.
    #
    # + key - the key of the entity
    # + updateRecord - the record to be updated
    # + updateAssociations - The associations that should be updated
    # + return - `()` if the operation is performed successfully.
    # A `ForeignKeyConstraintViolationError` if the operation violates a foreign key constraint.
    # A `persist:Error` if the operation fails due to another reason.
    public isolated function runUpdateQuery(anydata key, record {} updateRecord, string[] updateAssociations = []) returns ForeignKeyConstraintViolationError|Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`UPDATE `, self.tableName, stringToParameterizedQuery(" " + self.entityName), ` SET`, check self.getSetClauses(updateRecord, updateAssociations));
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

    # Performs an SQL `DELETE` operation to delete an entity record from the database.
    #
    # + deleteKey - The key used to delete an entity record
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(anydata deleteKey) returns Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`DELETE FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));
        query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(self.getKey(deleteKey)));
        sql:ExecutionResult|sql:Error e = self.dbClient->execute(query);

        if e is sql:Error {
            return <Error>error(e.message());
        }
    }

        # Retrieves the values of the 'many' side of an association.
    #
    # + 'object - The record to which the retrieved records should be appended
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function getManyRelations(anydata 'object, string[] include) returns Error? {
        if !('object is record {}) {
            return <Error>error("The 'object' parameter should be a record");
        }
        foreach string joinKey in self.joinMetadata.keys() {
            sql:ParameterizedQuery query = ``;
            JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);

            if include.indexOf(joinKey) != () && (joinMetadata.'type == MANY_TO_ONE || joinMetadata.'type == MANY_TO_MANY) {
                if joinMetadata.'type == MANY_TO_ONE {
                    map<string> whereFilter = {};
                    foreach int i in 0 ..< joinMetadata.refColumns.length() {
                        whereFilter[joinMetadata.refColumns[i]] = 'object[check self.getFieldFromColumn(joinMetadata.joinColumns[i])].toBalString();
                    }

                    query = sql:queryConcat(
                        ` SELECT `, self.getManyRelationColumnNames(joinMetadata.fieldName),
                        ` FROM `, stringToParameterizedQuery(joinMetadata.refTable),
                        ` WHERE`, check self.getWhereClauses(whereFilter, true)
                    );
                } else {
                    string joinTable = <string>joinMetadata.joinTable;
                    string[] joiningRefColumns = <string[]>joinMetadata.joiningRefColumns;
                    string[] joiningJoinColumns = <string[]>joinMetadata.joiningJoinColumns;

                    sql:ParameterizedQuery whereFields = arrayToParameterizedQuery(joinMetadata.refColumns);
                    sql:ParameterizedQuery joinSelectColumns = arrayToParameterizedQuery(joinMetadata.joinColumns);

                    map<string> innerWhereFilter = {};
                    foreach int i in 0 ..< joiningRefColumns.length() {
                        innerWhereFilter[joiningRefColumns[i]] = 'object[check self.getFieldFromColumn(joiningJoinColumns[i])].toString();
                    }

                    query = sql:queryConcat(
                        ` SELECT`, self.getManyRelationColumnNames(joinMetadata.fieldName),
                        ` FROM `, stringToParameterizedQuery(joinMetadata.refTable),
                        ` WHERE (`, whereFields, `) IN (`,
                            ` SELECT `, joinSelectColumns,
                            ` FROM `, stringToParameterizedQuery(joinTable),
                            ` WHERE`, check self.getWhereClauses(innerWhereFilter),
                        `)`
                    );
                }

                stream<record {}, sql:Error?> joinStream = self.dbClient->query(query, joinMetadata.entity);
                record {}[]|error arr = from record {} item in joinStream
                    select item;

                if arr is error {
                    return <Error>error(arr.message());
                }
                
                'object[joinMetadata.fieldName] = convertToArray(joinMetadata.entity, arr);
            }
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
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            if !isInsertableField(fieldMetadata) {
                continue;
            }
            if columnCount > 0 {
                params = sql:queryConcat(params, `,`);
            }

            if fieldMetadata is ReferentialFieldMetadata {
                string entity = fieldMetadata.relation.entityName;
                string fieldName = fieldMetadata.relation.refField;
                if 'object[entity] is () {
                    params = sql:queryConcat(params, `NULL`);
                } else {
                    params = sql:queryConcat(params, `${<sql:Value>(<record {}>'object[entity])[fieldName]}`);
                }
            } else {
                params = sql:queryConcat(params, `${<sql:Value>'object[key]}`);
            }
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
            if !isInsertableField(fieldMetadata) {
                continue;
            }
            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }
            params = sql:queryConcat(params, stringToParameterizedQuery((<SimpleFieldMetadata|ReferentialFieldMetadata>fieldMetadata).columnName));
            columnCount = columnCount + 1;
        }
        return params;
    }
    private isolated function getSelectColumnNames(string[] fields, string[] include) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        int columnCount = 0;

        foreach string key in self.fieldMetadata.keys() {
            // TODO: remove empty fields check
            if fields != [] && fields.indexOf(key) == () {
                continue;
            }
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            if fieldMetadata is SimpleFieldMetadata {
                if columnCount > 0 {
                    params = sql:queryConcat(params, `, `);
                }
                params = sql:queryConcat(params, stringToParameterizedQuery(self.entityName + "." + fieldMetadata.columnName + " AS `" + key + "`"));
                columnCount = columnCount + 1;
            } else if include.indexOf(fieldMetadata.relation.entityName) != () {
                if !key.includes("[]") {
                    if columnCount > 0 {
                        params = sql:queryConcat(params, `, `);
                    }
                    params = sql:queryConcat(params, stringToParameterizedQuery(
                        fieldMetadata.relation.entityName + "." + fieldMetadata.relation.refField + 
                        " AS `" + fieldMetadata.relation.entityName + "." + fieldMetadata.relation.refField + "`"
                    ));
                    columnCount = columnCount + 1;
                }
            }
        }
        return params;
    }

    private isolated function getManyRelationColumnNames(string prefix) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        string[] keys = self.fieldMetadata.keys();
        int columnCount = 0;
        foreach string key in keys {
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            if fieldMetadata is SimpleFieldMetadata {
                continue;
            }

            int? splitIndex = key.indexOf(prefix + "[].");
            if splitIndex is () {
                continue;
            }

            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }

            string columnName = fieldMetadata.relation.refField;
            params = sql:queryConcat(params, stringToParameterizedQuery(columnName));
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
                query = sql:queryConcat(query, stringToParameterizedQuery(keys[i] + " = " + filter[keys[i]].toString()));
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

            sql:ParameterizedQuery fieldName = self.getFieldParamQuery(key);
            if count > 0 {
                query = sql:queryConcat(query, `, `);
            }
            query = sql:queryConcat(query, fieldName, ` = ${<sql:Value>'object[key]}`);
            count = count + 1;
        }
        return query;
    }

    private isolated function getJoinFilters(string joinKey, string[] refFields, string[] joinColumns) returns sql:ParameterizedQuery|Error {
        sql:ParameterizedQuery query = ` `;
        foreach int i in 0 ..< refFields.length() {
            if i > 0 {
                query = sql:queryConcat(query, ` AND `);
            }
            sql:ParameterizedQuery filterQuery = stringToParameterizedQuery(joinKey + "." + refFields[i] + " = " + self.entityName + "." + joinColumns[i]);
            query = sql:queryConcat(query, filterQuery);
        }
        return query;
    }

    private isolated function getFieldParamQuery(string fieldName) returns sql:ParameterizedQuery {
        SimpleFieldMetadata|ReferentialFieldMetadata fieldMetadata = <SimpleFieldMetadata|ReferentialFieldMetadata>self.fieldMetadata.get(fieldName);
        return stringToParameterizedQuery(fieldMetadata.columnName);
    }

    private isolated function getFieldFromColumn(string columnName) returns string|FieldDoesNotExistError {
        foreach string key in self.fieldMetadata.keys() {
            FieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            if fieldMetadata is EntityFieldMetadata {
                continue;
            }

            if fieldMetadata.columnName == columnName {
                return key;
            }
        }

        return <FieldDoesNotExistError>error(
            string `A field corresponding to column '${columnName}' does not exist in entity '${self.entityName}'.`);
    }


}

# Represents the abstract persist client. This abstract object is used in the generated client.
public type AbstractPersistClient distinct object {
};
