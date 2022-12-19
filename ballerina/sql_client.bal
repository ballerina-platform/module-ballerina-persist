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
import ballerina/regex;

# The client used by the generated persist clients to abstract and 
# execute SQL queries that are required to perform CRUD operations.
public client class SQLClient {

    private final sql:Client dbClient;

    private string entityName;
    private sql:ParameterizedQuery tableName;
    private map<FieldMetadata> fieldMetadata;
    private string[] keyFields;
    private map<JoinMetadata> joinMetadata;

    # Initializes the `SQLClient`.
    #
    # + dbClient - The `sql:Client`, which is used to execute SQL queries
    # + entityName - The name of the entity with which the client performs CRUD operations
    # + tableName - The name of the SQL table, which is mapped to the entity
    # + keyFields - The names of the key fields of the entity
    # + fieldMetadata - The metadata associated with each field of the entity
    # + joinMetadata - The metadata associated with performing SQL `JOIN` operations
    # + return - A `persist:Error` if the client creation fails
    public function init(sql:Client dbClient, string entityName, sql:ParameterizedQuery tableName, string[] keyFields, map<FieldMetadata> fieldMetadata,
            map<JoinMetadata> joinMetadata = {}) returns Error? {
        self.entityName = entityName;
        self.tableName = tableName;
        self.fieldMetadata = fieldMetadata;
        self.keyFields = keyFields;
        self.dbClient = dbClient;
        self.joinMetadata = joinMetadata;
    }

    # Performs an SQL `INSERT` operation to insert a record into a table.
    #
    # + 'object - The record to be inserted into the table
    # + return - An `sql:ExecutionResult` containing the metadata of the query execution
    # or a `persist:Error` if the operation fails
    public isolated function runInsertQuery(record {} 'object) returns sql:ExecutionResult|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, self.tableName, ` (`,
            self.getInsertColumnNames(), ` ) `,
            `VALUES `, self.getInsertQueryParams('object)
        );
        sql:ExecutionResult|sql:Error result = self.dbClient->execute(query);

        if result is sql:Error {
            if result.message().indexOf("Duplicate entry ") != () {
                return <DuplicateKeyError>error(string `A ${self.entityName} entity with the key ${self.getKey('object).toString()} already exists.`);
            }
            return <Error>error(result.message());
        }

        check self.populateJoinTables('object);

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

        foreach string joinKey in self.joinMetadata.keys() {
            JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
            if include.indexOf(joinKey) != () && joinMetadata.'type != MANY {
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey),
                                        ` ON `, check self.getJoinFilters(joinKey, joinMetadata.refColumns, <string[]>joinMetadata.joinColumns));
            }
        }

        query = sql:queryConcat(query, ` WHERE `, check self.getGetKeyWhereClauses(key));
        record {}|sql:Error result = self.dbClient->queryRow(query, rowType);

        if result is sql:NoRowsError {
            return <InvalidKeyError>error(
                string `A record does not exist for '${self.entityName}' for key ${key.toBalString()}.`);
        }

        if result is record {} {
            check self.getManyRelations(result, include);
        }

        if result is sql:Error {
            return <Error>error(result.message());
        }
        return result;
    }

    # Performs an SQL `SELECT` operation to read multiple records from the database.
    #
    # + rowType - The record-type to be retrieved (the entity record-type)
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, string[] include = [])
    returns stream<record {}, sql:Error?>|Error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName)
        );

        string[] joinKeys = self.joinMetadata.keys();
        foreach string joinKey in joinKeys {
            if include.indexOf(joinKey) != () {
                JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey),
                                        ` ON `, check self.getJoinFilters(joinKey, joinMetadata.refColumns, <string[]>joinMetadata.joinColumns));
            }
        }

        stream<record {}, sql:Error?> resultStream = self.dbClient->query(query, rowType);
        return resultStream;
    }

    # Performs an SQL `SELECT` operation to read multiple records from the database when an advanced filter is provided.
    #
    # + filterClause - The filter query to be used in the SQL `WHERE` clauses
    # + rowType - The record type to be retrieved (the record type of the entity)
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runExecuteQuery(sql:ParameterizedQuery filterClause, typedesc<record {}> rowType, string[] include = [])
    returns stream<record {}, sql:Error?>|Error {
        if self.joinMetadata.length() != 0 {
            return <UnsupportedOperationError>error("Advanced queries are not supported for entities with relations.");
        }
        sql:ParameterizedQuery query = sql:queryConcat(`SELECT `, self.getSelectColumnNames(include), ` FROM `,
        self.tableName, ` AS `, stringToParameterizedQuery(self.entityName), filterClause);
        return self.dbClient->query(query, rowType);
    }

    # Performs an SQL `UPDATE` operation to update multiple records in the database.
    #
    # + 'object - the record to be updated
    # + updateAssociations - The associations that should be updated
    # + return - `()` if the operation is performed successfully.
    # A `ForeignKeyConstraintViolationError` if the operation violates a foreign key constraint.
    # A `persist:Error` if the operation fails due to another reason.
    public isolated function runUpdateQuery(record {} 'object, string[] updateAssociations = []) returns ForeignKeyConstraintViolationError|Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`UPDATE `, self.tableName, stringToParameterizedQuery(" " + self.entityName), ` SET`, check self.getSetClauses('object, updateAssociations));
        query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(self.getKey('object)));

        sql:ExecutionResult|sql:Error? e = self.dbClient->execute(query);
        if e is sql:Error {
            if e.message().indexOf("a foreign key constraint fails ") is () {
                return <Error>error(e.message());
            }
            else {
                return <ForeignKeyConstraintViolationError>error(e.message());
            }
        }

        check self.depopulateJoinTables('object, updateAssociations);
        check self.populateJoinTables('object, updateAssociations);
    }

    # Performs an SQL `DELETE` operation to delete a record from the database.
    #
    # + 'object - The record to be deleted
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(record {} 'object) returns Error? {
        sql:ParameterizedQuery query = sql:queryConcat(`DELETE FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));
        query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(self.getKey('object)));
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
    public isolated function getManyRelations(record {} 'object, string[] include) returns Error? {
        foreach string joinKey in self.joinMetadata.keys() {
            sql:ParameterizedQuery query = ``;
            JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);

            if include.indexOf(joinKey) != () && joinMetadata.'type == MANY {
                if joinMetadata.joinTable is () {
                    // 1-m relation
                    map<string> whereFilter = {};
                    foreach int i in 0 ..< joinMetadata.refColumns.length() {
                        whereFilter[joinMetadata.refColumns[i]] = 'object[self.getFieldFromColumn(joinMetadata.joinColumns[i])].toBalString();
                    }

                    query = sql:queryConcat(
                        ` SELECT `, self.getManyRelationColumnNames(joinMetadata.fieldName),
                        ` FROM `, stringToParameterizedQuery(joinMetadata.refTable),
                        ` WHERE`, check self.getWhereClauses(whereFilter, true)
                    );

                } else {
                    // m-n relation
                    string joinTable = <string>joinMetadata.joinTable;
                    string[] joiningRefColumns = <string[]>joinMetadata.joiningRefColumns;
                    string[] joiningJoinColumns = <string[]>joinMetadata.joiningJoinColumns;

                    sql:ParameterizedQuery whereFields = arrayToParameterizedQuery(joinMetadata.refColumns);
                    sql:ParameterizedQuery joinSelectColumns = arrayToParameterizedQuery(joinMetadata.joinColumns);

                    map<string> innerWhereFilter = {};
                    foreach int i in 0 ..< joiningRefColumns.length() {
                        innerWhereFilter[joiningRefColumns[i]] = 'object[self.getFieldFromColumn(joiningJoinColumns[i])].toBalString();
                    }

                    query = sql:queryConcat(
                        ` SELECT`, self.getManyRelationColumnNames(joinMetadata.fieldName),
                        ` FROM `, stringToParameterizedQuery(joinMetadata.refTable),
                        ` WHERE (`, whereFields, `) IN (`,
                            ` SELECT `, joinSelectColumns,
                            ` FROM `, stringToParameterizedQuery(joinTable),
                            ` WHERE `, check self.getWhereClauses(innerWhereFilter, true),
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

    # Closes the underlying `sql:Client`.
    #
    # + return - `()` if the client is closed successfully or a `persist:Error` if the operation fails
    public isolated function close() returns Error? {
        sql:Error? e = self.dbClient.close();
        if e is sql:Error {
            return <Error>error(e.message());
        }
    }

    private isolated function getKey(record {} 'object) returns record {} {
        record {} keyRecord = {};
        foreach string key in self.keyFields {
            keyRecord[key] = 'object[key];
        }
        return keyRecord;
    }

    private isolated function getInsertQueryParams(record {} 'object) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = `(`;
        string[] keys = self.fieldMetadata.keys();
        int columnCount = 0;
        foreach string key in keys {
            if self.fieldMetadata.get(key).autoGenerated || self.fieldMetadata.get(key).columnName is () {
                continue;
            }
            if columnCount > 0 {
                params = sql:queryConcat(params, `,`);
            }

            if key.includes(".") {
                string[] splits = regex:split(key, "\\.");
                string entity = splits[0];
                string fieldName = splits[1];
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
            if self.fieldMetadata.get(key).autoGenerated || self.fieldMetadata.get(key).columnName is () {
                continue;
            }
            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }
            params = sql:queryConcat(params, stringToParameterizedQuery(<string>self.fieldMetadata.get(key).columnName));
            columnCount = columnCount + 1;
        }
        return params;
    }

    private isolated function getSelectColumnNames(string[] include) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        int columnCount = 0;

        foreach string key in self.fieldMetadata.keys() {
            if self.fieldMetadata.get(key).relation is () {
                if columnCount > 0 {
                    params = sql:queryConcat(params, `, `);
                }
                params = sql:queryConcat(params, stringToParameterizedQuery(self.entityName + "." + <string>self.fieldMetadata.get(key).columnName + " AS `" + key + "`"));
                columnCount = columnCount + 1;
            } else if include.indexOf((<RelationMetadata>self.fieldMetadata.get(key).relation).entityName) != () {
                if !key.includes("[]") {
                    string fieldName = regex:split(key, "\\.")[0];
                    if columnCount > 0 {
                        params = sql:queryConcat(params, `, `);
                    }
                    params = sql:queryConcat(params, stringToParameterizedQuery(
                        (<RelationMetadata>self.fieldMetadata.get(key).relation).entityName + "." +
                        (<RelationMetadata>self.fieldMetadata.get(key).relation).refField +
                        " AS `" + fieldName + "." + (<RelationMetadata>self.fieldMetadata.get(key).relation).refField + "`"
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
            int? splitIndex = key.indexOf(prefix + "[].");
            if splitIndex is () {
                continue;
            }
            if columnCount > 0 {
                params = sql:queryConcat(params, `, `);
            }

            string fieldName = key.substring((prefix + "[].").length());
            string columnName = (<RelationMetadata>(<FieldMetadata>self.fieldMetadata[key]).relation).refColumnName;
            params = sql:queryConcat(params, stringToParameterizedQuery(columnName + " AS " + fieldName));
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
                query = sql:queryConcat(query, stringToParameterizedQuery(self.entityName + "."), check self.getFieldParamQuery(keys[i]), ` = ${<sql:Value>filter[keys[i]]}`);
            }
        }
        return query;
    }

    private isolated function getSetClauses(record {} 'object, string[] updateAssociations = []) returns sql:ParameterizedQuery|Error {
        record {} r = flattenRecord('object);
        sql:ParameterizedQuery query = ` `;
        int count = 0;
        foreach string key in r.keys() {

            // Check whether the column can be inserted to
            if !self.fieldMetadata.hasKey(key) || self.fieldMetadata.get(key).columnName == () {
                continue;
            }

            // If the column is associated with a relation, check whether that association should be updated
            if self.fieldMetadata.get(key).relation != () && updateAssociations.indexOf(key) != () {
                continue;
            }

            sql:ParameterizedQuery|InvalidInsertionError|FieldDoesNotExistError fieldName = self.getFieldParamQuery(key);
            if fieldName is sql:ParameterizedQuery {
                if count > 0 {
                    query = sql:queryConcat(query, `, `);
                }
                query = sql:queryConcat(query, fieldName, ` = ${<sql:Value>r[key]}`);
                count = count + 1;
            } else if fieldName is FieldDoesNotExistError {
                return fieldName;
            }
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

    private isolated function getFieldParamQuery(string fieldName) returns sql:ParameterizedQuery|FieldDoesNotExistError|InvalidInsertionError {
        FieldMetadata? fieldMetadata = self.fieldMetadata[fieldName];
        if fieldMetadata is () {
            return <FieldDoesNotExistError>error(
                string `Field '${fieldName}' does not exist in entity '${self.entityName}'.`);
        } else if (<FieldMetadata>fieldMetadata).columnName is () {
            return <InvalidInsertionError>error(
                string `Unable to directly insert into field ${fieldName}`);
        }
        return stringToParameterizedQuery(<string>(<FieldMetadata>fieldMetadata).columnName);
    }

    private isolated function getFieldFromColumn(string columnName) returns string {
        string fieldName = from string key in self.fieldMetadata.keys()
            where (<FieldMetadata>self.fieldMetadata[key]).columnName == columnName
            select key;
        return fieldName;
    }

    private isolated function populateJoinTables(record {} 'object, string[]? updateAssociations = ()) returns Error? {
        foreach string key in self.joinMetadata.keys() {
            if updateAssociations != () && updateAssociations.indexOf(key) is () {
                continue;
            }

            JoinMetadata joinMetadata = self.joinMetadata.get(key);
            string fieldName = joinMetadata.fieldName;

            if joinMetadata.joinTable is string && 'object[fieldName] is record {}[] {
                string joinTable = <string>joinMetadata.joinTable;
                string[] joiningJoinColumns = <string[]>joinMetadata.joiningJoinColumns;
                string[] joinColumns = <string[]>joinMetadata.joinColumns;
                string[] joiningRefColumns = <string[]>joinMetadata.joiningRefColumns;
                string[] refColumns = <string[]>joinMetadata.refColumns;

                record {}[] toBeInserted = <record {}[]>'object[fieldName];
                string[] insertColumns = [...joiningRefColumns, ...joinColumns];
                sql:Value[] lhsColumnsValues = [];
                sql:Value[][] joinTableValues = [];

                foreach string joiningJoinColumn in joiningJoinColumns {
                    foreach string joinKey in self.fieldMetadata.keys() {
                        if self.fieldMetadata.get(joinKey).columnName == joiningJoinColumn {
                            lhsColumnsValues.push(<sql:Value>'object[joinKey]);
                        }
                    }
                }

                foreach record {} row in toBeInserted {
                    sql:Value[] values = [...lhsColumnsValues];
                    foreach string refColumn in refColumns {
                        foreach string refKey in self.fieldMetadata.keys() {
                            if refKey.includes(fieldName + "[]") && (<RelationMetadata>self.fieldMetadata.get(refKey).relation).refColumnName == refColumn {
                                values.push(<sql:Value>row[(<RelationMetadata>self.fieldMetadata.get(refKey).relation).refField]);
                            }
                        }
                    }
                    joinTableValues.push(values);
                }

                sql:ParameterizedQuery[] sqlQueries =
                    from var row in joinTableValues
                select sql:queryConcat(
                        `INSERT INTO `, stringToParameterizedQuery(joinTable),
                        ` (`, arrayToParameterizedQuery(insertColumns), `) `,
                        `VALUES (`, arrayToParameterizedQuery(row, false), `)`
                    );

                sql:ExecutionResult[]|sql:Error result = self.dbClient->batchExecute(sqlQueries);

                if result is sql:Error {
                    return <Error>error(result.message());
                }
            }
        }
    }

    public isolated function depopulateJoinTables(record {} 'object, string[] updateAssociations) returns Error? {
        foreach string key in self.joinMetadata.keys() {
            if updateAssociations.indexOf(key) is () {
                continue;
            }

            JoinMetadata joinMetadata = self.joinMetadata.get(key);
            if joinMetadata.joinTable is string {

                string joinTable = <string>joinMetadata.joinTable;
                string[] joiningJoinColumns = <string[]>joinMetadata.joiningJoinColumns;
                string[] joiningRefColumns = <string[]>joinMetadata.joiningRefColumns;

                map<anydata> whereFilter = {};
                foreach int i in 0 ..< joiningJoinColumns.length() {
                    string columnName = joiningRefColumns[i];
                    string fieldName = self.getFieldFromColumn(joiningJoinColumns[i]);
                    anydata value = 'object[fieldName];
                    whereFilter[columnName] = value;
                }

                sql:ParameterizedQuery query = sql:queryConcat(
                    ` DELETE FROM `, stringToParameterizedQuery(joinTable),
                    ` WHERE `, check self.getWhereClauses(whereFilter, true)
                );
                sql:ExecutionResult|sql:Error result = self.dbClient->execute(query);

                if result is sql:Error {
                    return <Error>error(result.message());
                }
            }
        }
    }

}

# Represents the abstract persist client. This abstract object is used in the generated client.
public type AbstractPersistClient distinct object {
};
