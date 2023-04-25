// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
# execute API calls that are required to perform CRUD operations.
public client class GoogleSheetsClient {

    private final sheets:Client googleSheetClient;
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
    public function init(sheets:Client googleSheetClient, http:Client httpClient, SheetMetadata sheetMetadata, string spreadsheetId) returns error? {
        self.entityName = sheetMetadata.entityName;
        self.spreadsheetId = spreadsheetId;
        self.tableName = sheetMetadata.tableName;
        self.fieldMetadata = sheetMetadata.fieldMetadata;
        self.range = sheetMetadata.range;
        self.httpClient = httpClient;
        self.keyFields = sheetMetadata.keyFields;
        self.googleSheetClient = googleSheetClient;
        if sheetMetadata.joinMetadata is map<JoinMetadata> {
            self.joinMetadata = <map<JoinMetadata>>sheetMetadata.joinMetadata;
        }
    }

    # Performs an append operation to insert entity instances into a table.
    #
    # + insertRecords - The entity records to be inserted into the table
    # + return - An `sql:ExecutionResult[]` containing the metadata of the query execution
    # or a `persist:Error` if the operation fails
    public isolated function runBatchInsertQuery(record {}[] insertRecords) returns error? {
        string[] fieldMetadataKeys = self.fieldMetadata.keys();
        foreach record {} rowValues in insertRecords {
            string metadataValue = self.generateMetadataValue(self.keyFields, rowValues);
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Sheet sheet = check self.googleSheetClient->getSheetByName(self.spreadsheetId, self.tableName);
            sheets:Row[]|error output = self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (output !is error) {
                if (output.length() > 0) {
                    return <error>error("Error: record already exists. " + rowValues.toString());
                }
            }
            (int|string|decimal)[] values = [];
            foreach string key in fieldMetadataKeys {
                (int|string|decimal) value = check rowValues.get(key).ensureType();
                values.push(value);
            }
            sheets:Row insertedRow = check self.googleSheetClient->appendRowToSheet(self.spreadsheetId, self.tableName, values, self.range, "USER_ENTERED");
            check self.googleSheetClient->setRowMetaData(self.spreadsheetId, sheet.properties.sheetId, insertedRow.rowPosition, "DOCUMENT", self.tableName, metadataValue);
        }
    }

    # Performs an SQL `SELECT` operation to read a single entity record from the database.
    #
    # + rowType - The type description of the entity to be retrieved
    # + rowTypeWithIdFields - The type description of the entity to be retrieved with the key fields included
    # + typeMap - The data types of the record
    # + key - The value of the key (to be used as the `WHERE` clauses)
    # + fields - The fields to be retrieved
    # + include - The relations to be retrieved (SQL `JOINs` to be performed)
    # + typeDescriptions - The type descriptions of the relations to be retrieved
    # + return - A record in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, typedesc<record {}> rowTypeWithIdFields, map<anydata> typeMap, anydata key, string[] fields = [], string[] include = [], typedesc<record {}>[] typeDescriptions = []) returns record {}|error {
        sheets:Sheet sheet = check self.googleSheetClient->getSheetByName(self.spreadsheetId, self.tableName);
        string whereClause = check self.generateWhereClause(key, typeMap);
        string columnIds = check self.generateColumnIds(fields);

        string query = string `select ${columnIds} where ${whereClause}`;
        string encodedQuery = check url:encode(query, "UTF-8");
        http:QueryParams queries = {"gid": sheet.properties.sheetId, "range": self.range, "tq": encodedQuery, "tqx": "out:json"};
        http:Response response = check self.httpClient->/d/[self.spreadsheetId]/gviz/tq(params = queries);
        string|error textResponse = response.getTextPayload();
        record {}|error result;
        if textResponse !is error {
            map<json> payload = check textResponse.substring(47, textResponse.length() - 2).fromJsonStringWithType();
            Table worksheet = check payload["table"].fromJsonWithType();
            string[] columnNames = [];
            record {}[] rowTable = [];
            if (worksheet.rows.length() == 0) {
                return <error>error(string `No record found for the given key: ${key.toString()}`);
            }
            foreach map<json> item in worksheet.cols {
                columnNames.push(item["label"].toString());
            }
            foreach RowValues value in worksheet.rows {
                int i = 0;
                record {} rowArray = {};
                foreach map<json> item in value.c {
                    string dataType = typeMap.get(columnNames[i]).toString();
                    if dataType == "int" {
                        (string|int|decimal) typedValue = check self.dataConverter(item["f"], dataType);
                        rowArray[columnNames[i]] = typedValue;
                    } else {
                        (string|int|decimal) typedValue = check self.dataConverter(item["v"], dataType);
                        rowArray[columnNames[i]] = typedValue;
                    }
                    i = i + 1;
                }
                rowTable.push(rowArray);
            }
            if rowTable.length() == 0 {
                return <error>error(string `No record found for the given key: ${key.toString()}`);
            } else if rowTable.length() > 1 {
                return <error>error("string `Multiple records found for the given key: ${key.toString()}`");
            }
            result = rowTable[0].cloneWithType(rowType);

            if result is error {
                return <error>error(result.message());
            }
            return result;

        } else {
            return <error>error(textResponse.message());
        }
    }

    # + rowType - The type description of the entity to be retrieved
    # + typeMap - The data types of the record
    # + fields - The fields to be retrieved
    # + include - The associations to be retrieved
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, map<anydata> typeMap, string[] fields = [], string[] include = [])
    returns stream<record {}, error?>|error {
        sheets:Sheet sheet = check self.googleSheetClient->getSheetByName(self.spreadsheetId, self.tableName);
        string columnIds = check self.generateColumnIds(fields);
        string query = string `select ${columnIds}`;
        string encodedQuery = check url:encode(query, "UTF-8");
        http:QueryParams queries = {"gid": sheet.properties.sheetId, "range": self.range, "tq": encodedQuery, "tqx": "out:json"};
        http:Response response = check self.httpClient->/d/[self.spreadsheetId]/gviz/tq(params = queries);
        string|error textResponse = response.getTextPayload();
        if (textResponse !is error) {
            map<json> payload = check textResponse.substring(47, textResponse.length() - 2).fromJsonStringWithType();
            Table workSheet = check payload["table"].fromJsonWithType();
            string[] columnNames = [];
            record {}[] rowTable = [];
            foreach map<json> item in workSheet.cols {
                columnNames.push(item["label"].toString());
            }
            foreach RowValues value in workSheet.rows {
                int i = 0;
                record {} rowArray = {};
                foreach map<json> item in value.c {
                    string dataType = typeMap.get(columnNames[i]).toString();
                    if (dataType == "int") {
                        (string|int|decimal) typedValue = check self.dataConverter(item["f"], dataType);
                        rowArray[columnNames[i]] = typedValue;
                    } else {
                        (string|int|decimal) typedValue = check self.dataConverter(item["v"], dataType);
                        rowArray[columnNames[i]] = typedValue;
                    }
                    i = i + 1;
                }
                rowTable.push(rowArray);

            }
            return rowTable.toStream();
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
        sheets:Sheet sheet = check self.googleSheetClient->getSheetByName(self.spreadsheetId, self.tableName);
        (int|string|decimal)[] values = [];
        if (key is string|int|decimal) {
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: key.toString()};
            sheets:Row[] rows = check self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error(string `No element found for given key: ${key.toString()}`);
            } else if rows.length() > 1 {
                return <error>error(string `Multiple elements found for given key: ${key.toString()}`);
            }
            foreach string entityKey in entityKeys {
                if !updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) != ()) {
                    values.push(key);
                } else if !updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) == ()) {
                    int? indexOfKey = self.fieldMetadata.keys().indexOf(entityKey, 0);
                    if (indexOfKey !is ()) {
                        values.push(rows[0].values[indexOfKey]);
                    }
                } else {
                    (int|string|decimal) value = check updateRecord.get(entityKey).ensureType();
                    values.push(value);
                }
            }
            check self.googleSheetClient->updateRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter, values, "USER_ENTERED");
        } else if (key is map<anydata>) {
            string metadataValue = self.generateMetadataValue(self.keyFields, key);
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Row[] rows = check self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for update");
            }

            foreach string entityKey in entityKeys {
                if (!updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) != ())) {
                    (int|string|decimal) value = check key.get(entityKey).ensureType();
                    values.push(value);
                } else if !updateRecord.hasKey(entityKey) && (self.keyFields.indexOf(entityKey) == ()) {
                    int? indexOfKey = self.fieldMetadata.keys().indexOf(entityKey, 0);
                    if (indexOfKey !is ()) {
                        values.push(rows[0].values[indexOfKey]);
                    }
                }else {
                    (int|string|decimal) value = check updateRecord.get(entityKey).ensureType();
                    values.push(value);
                }
            }
            check self.googleSheetClient->updateRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter, values, "USER_ENTERED");

        }
    }

    # Performs an SQL `DELETE` operation to delete an entity record from the database.
    #
    # + deleteKey - The key used to delete an entity record
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(anydata deleteKey) returns error? {
        sheets:Sheet sheet = check self.googleSheetClient->getSheetByName(self.spreadsheetId, self.tableName);
        if (deleteKey is string|int|decimal) {
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: deleteKey.toString()};
            sheets:Row[] rows = check self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for delete");
            }
            check self.googleSheetClient->deleteRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
        } else if (deleteKey is map<anydata>) {
            string metadataValue = self.generateMetadataValue(self.keyFields, deleteKey);
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:Row[] rows = check self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);
            if (rows.length() == 0) {
                return <error>error("no element found for update");
            }
            check self.googleSheetClient->deleteRowByDataFilter(self.spreadsheetId, sheet.properties.sheetId, filter);

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

    private isolated function generateMetadataValue(string[] keyFields, record{}|map<anydata> rowValues) returns string {
        string metadataValue = "";
        foreach string key in keyFields {
            if (metadataValue != "") {
                metadataValue += ":";
            }
            metadataValue += rowValues[key].toString();
        }
        return metadataValue;
    }

    private isolated function generateWhereClause(anydata key, map<anydata> typeMap) returns string|error {
        string whereClause = "";
        if (key is map<any>) {
            foreach string primaryKey in key.keys() {
                string? columnId = self.fieldMetadata.get(primaryKey)["columnId"];
                if (columnId !is ()) {
                    string keyValue = key.get(primaryKey).toString();
                    if (whereClause != "") {
                        whereClause += " and ";
                    }
                    string dataType = typeMap.get(primaryKey).toString();
                    if (dataType == "string") {
                        string condition = string `${columnId} = '${keyValue}'`;
                        whereClause += condition;
                    } else {
                        string condition = string `${columnId} = ${keyValue}`;
                        whereClause += condition;
                    }
                } else {
                    return <error>error(string `ColumnId for the field : ${primaryKey} cannot be found.`);
                }
            }
        } else {
            string? columnId = self.fieldMetadata.get(self.keyFields[0])["columnId"];
            if (columnId !is ()) {
                string dataType = typeMap.get(self.keyFields[0]).toString();
                if (dataType == "string") {
                    whereClause = string `${columnId} = '${key.toString()}'`;
                } else {
                    whereClause = string `${columnId} = ${key.toString()}`;
                }

            } else {
                return <error>error(string `ColumnId for the field : ${self.keyFields[0]} cannot be found.`);
            }
        }
        return whereClause;

    }

    private isolated function generateColumnIds(string[] fields) returns string|error {
        string columnIds = "";
        foreach string fieldMetadataKey in fields {
            if self.fieldMetadata.hasKey(fieldMetadataKey) == false {
                return <error>error("Error: no such a key:" + fieldMetadataKey);
            }
            SheetFieldMetadata fieldMetadata = self.fieldMetadata.get(fieldMetadataKey);
            if (columnIds != "") {
                columnIds += ", ";
            }
            columnIds += fieldMetadata.columnId;
        }
        return columnIds;
    }

}
