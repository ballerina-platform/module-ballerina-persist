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

    public function init(string entityName, sql:ParameterizedQuery tableName, map<FieldMetadata> fieldMetadata, string[] keyFields,
                         sql:Client dbClient, map<JoinMetadata> joinMetadata = {}) returns error? {
        self.entityName = entityName;
        self.tableName = tableName;
        self.fieldMetadata = fieldMetadata;
        self.keyFields = keyFields;
        self.dbClient = dbClient;
        self.joinMetadata = joinMetadata;
    }

    public function runInsertQuery(record {} 'object) returns sql:ExecutionResult|error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `INSERT INTO `, self.tableName, ` (`,
            self.getInsertColumnNames(true), ` ) `,
            `VALUES `, self.getInsertQueryParams('object)
        );
        return check self.dbClient->execute(query);
    }

    public function runReadByKeyQuery(typedesc<record {}> t, string[] include = [], anydata... keys) returns record {}|error {
        sql:ParameterizedQuery query = sql:queryConcat(
            `SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, ` AS `, stringToParameterizedQuery(self.entityName)
        );

        string[] joinKeys = self.joinMetadata.keys();
        foreach string joinKey in joinKeys {
            if include.indexOf(joinKey) != () {
                JoinMetadata joinMetadata = self.joinMetadata.get(joinKey);
                query = sql:queryConcat(query, ` LEFT JOIN `, stringToParameterizedQuery(joinMetadata.refTable + " " + joinKey), ` ON `, stringToParameterizedQuery(joinKey + "." + joinMetadata.refFields[0]), ` = `, stringToParameterizedQuery(self.entityName + "." + (<string[]>joinMetadata.joinColumns)[0]));
            }
        }

        query = sql:queryConcat(query, ` WHERE `, check self.getGetKeyWhereClauses(keys));
        record {}|error result = self.dbClient->queryRow(query, t);
        if result is sql:NoRowsError {
            if keys.length() > 1 {
                return <InvalidKey>error("A record does not exist for '" + self.entityName + "' for key " + keys.toBalString() + ".");
            }
            return <InvalidKey>error("A record does not exist for '" + self.entityName + "' for key " + keys[0].toBalString() + ".");
        }
        return result;
    }

    public function runReadQuery(typedesc<record {}> t, map<anydata>? filter, string[] include = []) returns stream<record {}, sql:Error?>|error {
        sql:ParameterizedQuery query = sql:queryConcat(`SELECT `, self.getSelectColumnNames(include), ` FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE `, check self.getWhereClauses(filter));
        }

        stream<record {}, sql:Error?> resultStream = self.dbClient->query(query, t);
        return resultStream;
    }

    public function runUpdateQuery(record {} 'object, map<anydata>? filter) returns error? {
        sql:ParameterizedQuery query = sql:queryConcat(`UPDATE `, self.tableName, stringToParameterizedQuery(" " + self.entityName), ` SET`, check self.getSetClauses('object));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        _ = check self.dbClient->execute(query);
    }

    public function runDeleteQuery(map<anydata>? filter) returns error? {
        sql:ParameterizedQuery query = sql:queryConcat(`DELETE FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        _ = check self.dbClient->execute(query);
    }

    public function checkExists(map<anydata>? filter) returns error? {
        sql:ParameterizedQuery query = sql:queryConcat(`SELECT * FROM `, self.tableName, stringToParameterizedQuery(" " + self.entityName));

        if !(filter is ()) {
            query = sql:queryConcat(query, ` WHERE`, check self.getWhereClauses(filter));
        }

        _ = check self.dbClient->execute(query);
    }

    private function getInsertQueryParams(record {} 'object) returns sql:ParameterizedQuery {
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
                string[] x = [key.substring(0, splitPosition), key.substring(splitPosition+1, key.length())];
                if 'object[x[0]] is () {
                    params = sql:queryConcat(params, `NULL`);
                } else {
                    params = sql:queryConcat(params, `${<sql:Value>(<record {}>'object[x[0]])[x[1]]}`);
                }
            } else {
                params = sql:queryConcat(params, `${<sql:Value>'object[key]}`);
            }
            columnCount = columnCount + 1;
        }
        params = sql:queryConcat(params, `)`);
        return params;
    }

    private function getInsertColumnNames(boolean skipAutogenerated = false) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        string[] keys = self.fieldMetadata.keys();
        int columnCount = 0;
        foreach string key in keys {
            if self.fieldMetadata.get(key).autoGenerated && skipAutogenerated || self.fieldMetadata.get(key).columnName is () {
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

    private function getSelectColumnNames(string[] include) returns sql:ParameterizedQuery {
        sql:ParameterizedQuery params = ` `;
        string[] keys = self.fieldMetadata.keys();
        int columnCount = 0;
        foreach string key in keys {
            if self.fieldMetadata.get(key).relation is () {
                if columnCount > 0 {
                    params = sql:queryConcat(params, `, `);
                }
                params = sql:queryConcat(params, stringToParameterizedQuery(self.entityName + "." + <string>self.fieldMetadata.get(key).columnName + " AS `" + <string>self.fieldMetadata.get(key).columnName + "`"));
                columnCount = columnCount + 1;
            } else if include.indexOf((<RelationMetadata>self.fieldMetadata.get(key).relation).entityName) != () {
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
        return params;
    }

    private function getGetKeyWhereClauses(anydata... keys) returns sql:ParameterizedQuery|error {
        keys = <anydata[]>keys[0];
        map<anydata> filter = {};
        foreach int i in 0 ..< keys.length() {
            filter[self.keyFields[i]] = keys[i];
        }
        return check self.getWhereClauses(filter);
    }

    function getWhereClauses(map<anydata> filter) returns sql:ParameterizedQuery|error {
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

    function getSetClauses(record {} 'object) returns sql:ParameterizedQuery|error {
        sql:ParameterizedQuery query = ` `;
        string[] keys = 'object.keys();
        foreach int i in 0 ..< keys.length() {
            if i > 0 {
                query = sql:queryConcat(query, `, `);
            }
            query = sql:queryConcat(query, check self.getFieldParamQuery(keys[i]), ` = ${<sql:Value>'object[keys[i]]}`);
        }
        return query;
    }

    function getFieldParamQuery(string fieldName) returns sql:ParameterizedQuery|FieldDoesNotExist {
        FieldMetadata? fieldMetadata = self.fieldMetadata[fieldName];
        if fieldMetadata is () || (<FieldMetadata>fieldMetadata).columnName is () {
            return <FieldDoesNotExist>error("Field '" + fieldName + "' does not exist in entity '" + self.entityName + "'.");
        }
        return stringToParameterizedQuery(<string>fieldMetadata.columnName);
    }

    public function close() returns error? {
        return self.dbClient.close();
    }
}
