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

import ballerinax/googleapis.sheets;
import ballerina/url;
import ballerina/http;

type Table record {
    map<json>[] cols;
    RowValues[] rows;
    int parsedNumHeaders;
};

type RowValues record {
    map<json>[] c;
};

# The client used by the generated persist clients to abstract and
# execute SQL queries that are required to perform CRUD operations.
public client class GoogleSheetsClient {

    private final sheets:Client dbClient;
    private final http:Client httpClient;
    private string spreadsheetId;
    private string entityName;
    private string tableName;
    private string range;
    private map<SheetFieldMetadata> fieldMetadata;
    private string[] keyFields;
    private map<JoinMetadata> joinMetadata = {};

    # Initializes the `GSheetClient`.
    #
    # + GSheetClient - The `sheets:Client`, which is used to execute google sheets operations
    # + httpClient - The `http:Client`, which is used to execute http requests
    # + metadata - Metadata of the entity
    # + spreadsheetId - Id of the spreadsheet
    # + return - A `persist:Error` if the client creation fails
    public function init(sheets:Client GSheetClient, http:Client httpClient, SheetMetadata metadata, string spreadsheetId) returns error? {
        self.entityName = metadata.entityName;
        self.spreadsheetId = spreadsheetId;
        self.tableName = metadata.tableName;
        self.fieldMetadata = metadata.fieldMetadata;
        self.range = metadata.range;
        self.httpClient = httpClient;
        self.keyFields = metadata.keyFields;
        self.dbClient = GSheetClient;
        if metadata.joinMetadata is map<JoinMetadata> {
            self.joinMetadata = <map<JoinMetadata>>metadata.joinMetadata;
        }
    }

    # Performs an append operation to insert entity instances into a table.
    #
    # + insertRecords - The entity records to be inserted into the table
    # + return - An `sql:ExecutionResult[]` containing the metadata of the query execution
    # or a `persist:Error` if the operation fails
    public isolated function runBatchInsertQuery(record {}[] insertRecords) returns error? {
        string[] keys = self.fieldMetadata.keys();
        foreach record {} item in insertRecords {
            string metadataValue = "";
            foreach string key in self.keyFields {
                if (metadataValue != "") {
                    metadataValue += ":";
                }
                metadataValue += item[key].toString();
            }
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Sheet sheet = check self.dbClient->getSheetByName(self.spreadsheetId, self.tableName);
            sheets:Row[]|error output = self.dbClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (output !is error) {
                if (output.length() > 0) {
                    return <error>error("already exists");
                }
            }
            (int|string|decimal)[] values = [];
            foreach string key in keys {
                (int|string|decimal) value = check item.get(key).ensureType();
                values.push(value);
            }
            sheets:Row insertedRow = check self.dbClient->appendRowToSheet(self.spreadsheetId, self.tableName, values, self.range, "USER_ENTERED");
            check self.dbClient->setRowMetaData(self.spreadsheetId, sheet.properties.sheetId, insertedRow.rowPosition, "DOCUMENT", self.tableName, metadataValue);
        }
    }

    # Performs an SQL `SELECT` operation to read a single entity record from the database.
    #
    # + rowType - The type description of the entity to be retrieved
    # + rowTypeWithIdFields - The type description of the entity to be retrieved with the key fields included
    # + key - The value of the key (to be used as the `WHERE` clauses)
    # + fields - The fields to be retrieved
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + typeDescriptions - The type descriptions of the relations to be retrieved
    # + return - A record in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, typedesc<record {}> rowTypeWithIdFields, anydata key, string[] fields = [], string[] include = [], typedesc<record {}>[] typeDescriptions = []) returns record {}|error {
        sheets:Sheet sheet = check self.dbClient->getSheetByName(self.spreadsheetId, self.tableName);
        string whereClause = "";
        if (key is map<any>) {
            foreach string primaryKey in key.keys() {
                string? columnId = self.fieldMetadata.get(primaryKey)["columnId"];
                if (columnId !is ()) {
                    if (whereClause != "") {
                        whereClause += " and ";
                    }
                    whereClause += columnId;
                    whereClause += " = ";
                    whereClause += "'" + key.get(primaryKey).toString() + "'";
                }
            }
        } else {
            string? columnId = self.fieldMetadata.get(self.keyFields[0])["columnId"];
            if (columnId !is ()) {
                whereClause = self.keyFields[0] + " = " + "'" + key.toString() + "'";
            }
        }
        string query = "";
        // if (include.length() == 0) {
        //     foreach string fieldMetadataKey in self.fieldMetadata.keys() {
        //         SheetFieldMetadata fieldMetadata = self.fieldMetadata.get(fieldMetadataKey);
        //         if (fieldMetadata is SimpleSheetFieldMetadata) {
        //             if (query != "") {
        //                 query += ", ";
        //             }
        //             query += fieldMetadata.columnId;
        //         }
        //     }
        // } else if (include.length() > 0) {
        foreach string fieldMetadataKey in fields {
            if (self.fieldMetadata.hasKey(fieldMetadataKey) == false) {
                return <error>error("no such a key:" + fieldMetadataKey);
            }
            SheetFieldMetadata fieldMetadata = self.fieldMetadata.get(fieldMetadataKey);
            // if (fieldMetadata is SimpleSheetFieldMetadata) {
            if (query != "") {
                query += ", ";
            }
            query += fieldMetadata.columnId;
            // }
        }
        //}
        query = "select " + query + " where " + whereClause;
        string encodedQuery = check url:encode(query, "UTF-8");
        http:QueryParams queries = {"gid": sheet.properties.sheetId, "range": self.range, "tq": encodedQuery, "tqx": "out:json"};
        http:Response response = check self.httpClient->/d/[self.spreadsheetId]/gviz/tq(params = queries);
        string|error textResponse = response.getTextPayload();
        record {}|error result;
        if (textResponse !is error) {
            map<json> payload = check textResponse.substring(47, textResponse.length() - 2).fromJsonStringWithType();
            Table worksheet = check payload["table"].fromJsonWithType();
            string[] columnNames = [];
            record {}[] output = [];
            if (worksheet.rows.length() == 0) {
                return <error>error("no record");
            }
            foreach map<json> item in worksheet.cols {
                columnNames.push(item["label"].toString());
            }
            foreach RowValues value in worksheet.rows {
                int i = 0;
                record {} temp = {};
                foreach map<json> item in value.c {
                    string dataType = self.fieldMetadata.get(columnNames[i]).get("dataType");
                    if (dataType == "int") {
                        (string|int|decimal) typedValue = check self.dataConverter(item["f"], dataType);
                        temp[columnNames[i]] = typedValue;
                    } else {
                        (string|int|decimal) typedValue = check self.dataConverter(item["v"], dataType);
                        temp[columnNames[i]] = typedValue;
                    }
                    i = i + 1;

                }
                output.push(temp);
            }
            if (output.length() == 0) {
                return <error>error("no record");
            } else if (output.length() > 1) {
                return <error>error("error");
            }
            result = output[0].cloneWithType(rowType);

            if result is error {
                return <Error>error(result.message());
            }
            return result;

        } else {
            return <error>error(textResponse.message());
        }
    }

    # + rowType - The type description of the entity to be retrieved
    # + fields - The fields to be retrieved
    # + include - The associations to be retrieved
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, string[] fields = [], string[] include = [])
    returns stream<record {}, error?>|error {
        sheets:Sheet sheet = check self.dbClient->getSheetByName(self.spreadsheetId, self.tableName);
        string query = "";
        // if (include.length() == 0) {
        //     foreach string key in self.fieldMetadata.keys() {
        //         SheetFieldMetadata fieldMetadata = self.fieldMetadata.get(key);
        //         if (fieldMetadata is SimpleSheetFieldMetadata) {
        //             if (query != "") {
        //                 query += ", ";
        //             }
        //             query += fieldMetadata.columnId;
        //         }
        //     }
        // } else if (include.length() > 0) {
        foreach string key in fields {
            if (self.fieldMetadata.hasKey(key) == false) {
                return <error>error("no such a key:" + key);
            }
            SheetFieldMetadata fieldMetadata = self.fieldMetadata.get(key);
            // if (fieldMetadata is SimpleSheetFieldMetadata) {
                if (query != "") {
                    query += ", ";
                }
                query += fieldMetadata.columnId;
            }
        // }
        // }
        query = "select " + query;
        string encodedQuery = check url:encode(query, "UTF-8");
        http:QueryParams queries = {"gid": sheet.properties.sheetId, "range": self.range, "tq": encodedQuery, "tqx": "out:json"};
        http:Response response = check self.httpClient->/d/[self.spreadsheetId]/gviz/tq(params = queries);
        string|error textResponse = response.getTextPayload();
        if (textResponse !is error) {
            map<json> payload = check textResponse.substring(47, textResponse.length() - 2).fromJsonStringWithType();
            Table workSheet = check payload["table"].fromJsonWithType();
            string[] columnNames = [];
            record {}[] output = [];
            foreach map<json> item in workSheet.cols {
                columnNames.push(item["label"].toString());
            }
            foreach RowValues value in workSheet.rows {
                int i = 0;
                record {} temp = {};
                foreach map<json> item in value.c {
                    string dataType = self.fieldMetadata.get(columnNames[i]).get("dataType");
                    if (dataType == "int") {
                        (string|int|decimal) typedValue = check self.dataConverter(item["f"], dataType);
                        temp[columnNames[i]] = typedValue;
                    } else {
                        (string|int|decimal) typedValue = check self.dataConverter(item["v"], dataType);
                        temp[columnNames[i]] = typedValue;
                    }
                    i = i + 1;
                }
                output.push(temp);

            }
            return output.toStream();
        } else {
            return <error>error(textResponse.message());
        }
    }

    # Performs an SQL `UPDATE` operation to update multiple entity records in the database.
    #
    # + key - the key of the entity
    # + updateRecord - the record to be updated
    # + return - `()` if the operation is performed successfully.
    # A `ForeignKeyConstraintViolationError` if the operation violates a foreign key constraint.
    # A `persist:Error` if the operation fails due to another reason.
    public isolated function runUpdateQuery(anydata key, record {} updateRecord) returns error? {
        string[] entityKeys = self.fieldMetadata.keys();
        sheets:Sheet sheet = check self.dbClient->getSheetByName(self.spreadsheetId, self.tableName);
        (int|string|decimal)[] values = [];
        if (key is string) {
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: <string>key};
            sheets:Row[] rows = check self.dbClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for update");
            }
            foreach string entityKey in entityKeys {
                if (!updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) != ())) {
                    values.push(key);
                } else {
                    (int|string|decimal) value = check updateRecord.get(key).ensureType();
                    values.push(value);
                }
            }
            check self.dbClient->updateRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter, values, "USER_ENTERED");
        } else if (key is map<anydata>) {
            string metadataValue = "";
            foreach string entityKey in self.keyFields {
                if (metadataValue != "") {
                    metadataValue += ":";
                }
                metadataValue += key.get(entityKey).toString();
            }
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Row[] rows = check self.dbClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for update");
            }

            foreach string entityKey in entityKeys {
                if (!updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) != ())) {
                    (int|string|decimal) value = check key.get(entityKey).ensureType();
                    values.push(value);
                } else {
                    (int|string|decimal) value = check updateRecord.get(entityKey).ensureType();
                    values.push(value);
                }
            }
            check self.dbClient->updateRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter, values, "USER_ENTERED");

        }
    }

    # Performs an SQL `DELETE` operation to delete an entity record from the database.
    #
    # + deleteKey - The key used to delete an entity record
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(anydata deleteKey) returns error? {
        sheets:Sheet sheet = check self.dbClient->getSheetByName(self.spreadsheetId, self.tableName);
        if (deleteKey is string) {
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: <string>deleteKey};
            sheets:Row[] rows = check self.dbClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for delete");
            }
            check self.dbClient->deleteRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
        } else if (deleteKey is map<anydata>) {
            string metadataValue = "";
            foreach string entityKey in self.keyFields {
                if (metadataValue != "") {
                    metadataValue += ":";
                }
                metadataValue += deleteKey.get(entityKey).toString();
            }
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Row[] rows = check self.dbClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for update");
            }
            check self.dbClient->deleteRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);

        }
    }

    public isolated function getKeyFields() returns string[] {
        return self.keyFields;
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

    private isolated function dataConverter(json value, string dataType) returns int|string|decimal|error {
        if (dataType == "int") {
            return int:fromString(value.toString());
        } else if (dataType == "string") {
            return value.toString();
        } else if (dataType == "decimal") {
            return decimal:fromString(value.toString());
        } else {
            return <error>error("unsupported data format");
        }
    }

}
