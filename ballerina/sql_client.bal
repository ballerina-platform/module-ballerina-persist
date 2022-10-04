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

public client class SQLClient {

    private final sql:Client dbClient;

    private string entityName;
    private sql:ParameterizedQuery tableName;
    private map<FieldMetadata> fieldMetadata;
    private string[] keyFields;
    private map<JoinMetadata> joinMetadata;

    public function init(sql:Client dbClient, string entityName, sql:ParameterizedQuery tableName, string[] keyFields, map<FieldMetadata> fieldMetadata,
                        map<JoinMetadata> joinMetadata = {}) returns error? {
        self.entityName = entityName;
        self.tableName = tableName;
        self.fieldMetadata = fieldMetadata;
        self.keyFields = keyFields;
        self.dbClient = dbClient;
        self.joinMetadata = joinMetadata;
    }

    public isolated function runInsertQuery(record {} 'object) returns sql:ExecutionResult|error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, self.tableName, ` (`,
            self.getInsertColumnNames(), ` ) `,
            `VALUES `, self.getInsertQueryParams('object)
        );
        return check self.dbClient->execute(query);
    }

    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, anydata key, string[] include = []) returns record {}|error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, ` AS `, stringToParameterizedQuery(self.entityName)
        );

        foreach string joinKey in self.joinMetadata.keys() {
            JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
            if include.indexOf(joinKey) != () {
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey), 
                                        ` ON `, check self.getJoinFilters(joinKey, joinMetadata.refFields, <string[]>joinMetadata.joinColumns));
            }
        }

        query = sql:queryConcat(query, ` WHERE `, check self.getGetKeyWhereClauses(key));
        record {}|error result = self.dbClient->queryRow(query, rowType);

        if result is sql:NoRowsError {
            return <InvalidKeyError>error(
                string `A record does not exist for '${self.entityName}' for key ${key.toBalString()}.`);
        }

        if result is record {} {
            check self.getManyRelations(result, include);
        }

        return result;
    }

    public isolated function runReadQuery(typedesc<record {}> rowType, map<anydata>? filter, string[] include = [])
    returns stream<record {}, sql:Error?>|error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName)
        );

        string[] joinKeys = self.joinMetadata.keys();
        foreach string joinKey in joinKeys {
            if include.indexOf(joinKey) != () {
                JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey),
                                        ` ON `, check self.getJoinFilters(joinKey, joinMetadata.refFields, <string[]>joinMetadata.joinColumns));
            }
        }

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE `, check self.getWhereClauses(filter));
        }

        stream<record {}, sql:Error?> resultStream = self.dbClient->query(query, rowType);
        return resultStream;
    }

    public isolated function runExecuteQuery(sql:ParameterizedQuery filterClause, typedesc<record {}> rowType, string[] include = [])
    returns stream<record {}, sql:Error?>|error {
        sql:ParameterizedQuery query = sql:queryConcat(`SELECT `, self.getSelectColumnNames(include), ` FROM `,
        self.tableName, ` AS `, stringToParameterizedQuery(self.entityName), filterClause);
        return self.dbClient->query(query, rowType);
    }

    public isolated function runUpdateQuery(record {} 'object, map<anydata>? filter) returns ForeignKeyConstraintViolationError|error? {
        sql:ParameterizedQuery query = sql:queryConcat(`UPDATE `, self.tableName, stringToParameterizedQuery(" " + self.entityName), ` SET`, check self.getSetClauses('object));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        sql:ExecutionResult|sql:Error? e = self.dbClient->execute(query);
        if e is sql:Error {
            if e.message().indexOf("a foreign key constraint fails ") is () {
                return e;
            }
            else {
                return <ForeignKeyConstraintViolationError>error(e.message());
            }
        }
    }

    public isolated function runDeleteQuery(map<anydata>? filter) returns error? {
        sql:ParameterizedQuery query = sql:queryConcat(`DELETE FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        _ = check self.dbClient->execute(query);
    }

    public isolated function checkExists(map<anydata>? filter) returns error? {
        sql:ParameterizedQuery query = sql:queryConcat(`SELECT * FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        _ = check self.dbClient->execute(query);
    }

    public isolated function getManyRelations(record {} result, string[] include) returns error? {
        foreach string joinKey in self.joinMetadata.keys() {
            sql:ParameterizedQuery query = ``;
            JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
            if include.indexOf(joinKey) != () && joinMetadata.'type == MANY {
                query = sql:queryConcat(`SELECT `, self.getManyRelationColumnNames(joinMetadata.fieldName),
                                        ` FROM `, stringToParameterizedQuery(joinMetadata.refTable),
                                        ` WHERE `, stringToParameterizedQuery(joinMetadata.refFields[0]), ` = `, stringToParameterizedQuery(result["id"].toBalString()));

                stream<record {}, sql:Error?> joinStream = self.dbClient->query(query, joinMetadata.entity);
                record {}[] arr = [];
                check from record {} item in joinStream
                    do {
                        arr.push(check item.cloneWithType(joinMetadata.entity));
                    };
                result[joinMetadata.fieldName] = convertToArray(joinMetadata.entity, arr);
            }
        }
    }


    public isolated function close() returns error? {
        return self.dbClient.close();
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
                int splitPosition = <int>key.indexOf(".", 0);
                string entity = key.substring(0, splitPosition);
                string fieldName = key.substring(splitPosition + 1, key.length());
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
                params = sql:queryConcat(params, stringToParameterizedQuery(self.entityName + "." + <string>self.fieldMetadata.get(key).columnName + " AS `" + <string>self.fieldMetadata.get(key).columnName + "`"));
                columnCount = columnCount + 1;
            } else if include.indexOf((<RelationMetadata>self.fieldMetadata.get(key).relation).entityName) != () {
                if !key.includes("[]") {
                    if columnCount > 0 {
                        params = sql:queryConcat(params, `, `);
                    }
                    params = sql:queryConcat(params, stringToParameterizedQuery(
                        (<RelationMetadata>self.fieldMetadata.get(key).relation).entityName + "." +
                        (<RelationMetadata>self.fieldMetadata.get(key).relation).refField +
                        " AS `" + (<RelationMetadata>self.fieldMetadata.get(key).relation).entityName + "." + (<RelationMetadata>self.fieldMetadata.get(key).relation).refField + "`"
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
            string columnName = (<RelationMetadata>(<FieldMetadata>self.fieldMetadata[key]).relation).refField;
            params = sql:queryConcat(params, stringToParameterizedQuery(columnName + " AS " + fieldName));
            columnCount = columnCount + 1;
        }
        return params;
    }

    private isolated function getGetKeyWhereClauses(anydata key) returns sql:ParameterizedQuery|error {
        map<anydata> filter = {};

        if key is record {} {
            filter = key;
        } else {
            filter[self.keyFields[0]] = key;
        }

        return check self.getWhereClauses(filter);
    }

    private isolated function getWhereClauses(map<anydata> filter) returns sql:ParameterizedQuery|error {
        sql:ParameterizedQuery query = ` `;

        string[] keys = filter.keys();
        foreach int i in 0 ..< keys.length() {
            if i > 0 {
                query = sql:queryConcat(query, ` AND `);
            }
            query = sql:queryConcat(query, stringToParameterizedQuery(self.entityName + "."), check self.getFieldParamQuery(keys[i]), ` = ${<sql:Value>filter[keys[i]]}`);
        }
        return query;
    }

    private isolated function getSetClauses(record {} 'object) returns sql:ParameterizedQuery|error {
        record {} r = flattenRecord('object);
        sql:ParameterizedQuery query = ` `;
        int count = 0;
        foreach string key in r.keys() {
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

    private isolated function getJoinFilters(string joinKey, string[] refFields, string[] joinColumns) returns sql:ParameterizedQuery|error {
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
}
