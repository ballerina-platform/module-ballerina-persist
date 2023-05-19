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
import ballerina/time;

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
public isolated client class GoogleSheetsClient {

    private final sheets:Client googleSheetClient;
    private final http:Client httpClient;
    private final string spreadsheetId;
    private final int sheetId;
    private final string entityName;
    private final string tableName;
    private final string range;
    private final map<SheetFieldMetadata> & readonly fieldMetadata;
    private final map<string> & readonly dataTypes;
    private final string[] & readonly keyFields;
    private isolated function (string[]) returns stream<record {}, Error?>|Error query;
    private isolated function (anydata) returns record {}|NotFoundError queryOne;
    private final (map<isolated function (record {}, string[]) returns record {}[]|Error>) & readonly associationsMethods;

    # Initializes the `GSheetClient`.
    #
    # + googleSheetClient - The `sheets:Client`, which is used to execute google sheets operations
    # + httpClient - The `http:Client`, which is used to execute http requests
    # + sheetMetadata - Metadata of the entity
    # + spreadsheetId - Id of the spreadsheet
    # + sheetId - Id of the sheet
    # + return - A `persist:Error` if the client creation fails
    public isolated function init(sheets:Client googleSheetClient, http:Client httpClient, SheetMetadata & readonly sheetMetadata, string & readonly spreadsheetId, int & readonly sheetId) returns Error? {
        self.entityName = sheetMetadata.entityName;
        self.spreadsheetId = spreadsheetId;
        self.tableName = sheetMetadata.tableName;
        self.fieldMetadata = sheetMetadata.fieldMetadata;
        self.range = sheetMetadata.range;
        self.httpClient = httpClient;
        self.keyFields = sheetMetadata.keyFields;
        self.googleSheetClient = googleSheetClient;
        self.dataTypes = sheetMetadata.dataTypes;
        self.query = sheetMetadata.query;
        self.queryOne = sheetMetadata.queryOne;
        self.associationsMethods = sheetMetadata.associationsMethods;
        self.sheetId = sheetId;
    }

    # Performs an append operation to insert entity instances into a table.
    #
    # + insertRecords - The entity records to be inserted into the table
    # + return - Error on failure, or `()` on success
    public isolated function runBatchInsertQuery(record {}[] insertRecords) returns Error? {
        string[] fieldMetadataKeys = self.fieldMetadata.keys();
        foreach record {} rowValues in insertRecords {
            string metadataValue = self.generateMetadataValue(self.keyFields, rowValues);
            sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
            sheets:ValueRange[]|error output = self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, self.sheetId, filter);
            if output is error {
                return <Error>error(output.message());
            }
            if output.length() > 0 {
                return <AlreadyExistsError>error(string `Duplicate key: ${self.generateKeyArrayString(self.keyFields, rowValues)}`);
            }
            SheetBasicType[] values = [];
            foreach string key in fieldMetadataKeys {
                string dataType = self.dataTypes.get(key).toString();
                if dataType == "time:Date" || dataType == "time:TimeOfDay" ||dataType == "time:Civil" || dataType == "time:Utc" {
                    SheetTimeType|error timeValue = rowValues.get(key).ensureType();
                    if timeValue is error {
                        return <Error> error(timeValue.message());
                    }
                    string|error value = self.timeToString(timeValue);
                    if value is error {
                        return <Error> error(value.message());
                    }
                    values.push(value);
                } else {
                    SheetBasicType|error value = rowValues.get(key).ensureType();
                    if value is error {
                        return <Error> error(value.message());
                    }
                    values.push(value);
                }
            }
            string[] splitedRange = re `:`.split(self.range);
            sheets:A1Range a1Range = {sheetName: self.tableName, startIndex: splitedRange[0], endIndex: splitedRange[1]};
            sheets:ValueRange|error insertedRow = self.googleSheetClient->appendValue(self.spreadsheetId, values, a1Range, "USER_ENTERED");
            if insertedRow is error {
                return <Error> error (insertedRow.message());
            }
            error? response = self.googleSheetClient->setRowMetaData(self.spreadsheetId, self.sheetId, insertedRow.rowPosition, "DOCUMENT", self.tableName, metadataValue);
            if response is error {
                return <Error> error (response.message());
            }
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
    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, typedesc<record {}> rowTypeWithIdFields, map<anydata> typeMap, anydata key, string[] fields = [], string[] include = [], typedesc<record {}>[] typeDescriptions = []) returns record {}|Error {
        record {} 'object = check self.queryOne(key);
        'object = filterRecord('object, self.addKeyFields(fields));
        check self.getManyRelations('object, fields, include, typeDescriptions);
        self.removeUnwantedFields('object, fields);
        do {
            return check 'object.cloneWithType(rowType);
        } on fail error e {
            return <Error>e;
        }
    }

    # + rowType - The type description of the entity to be retrieved
    # + typeMap - The data types of the record
    # + fields - The fields to be retrieved
    # + include - The associations to be retrieved
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function runReadQuery(typedesc<record {}> rowType, map<anydata> typeMap, string[] fields = [], string[] include = [])
    returns stream<record {}, error?>|Error {
        return self.query(self.addKeyFields(fields));
    }

    # + rowType - The type description of the entity to be retrieved
    # + typeMap - The data types of the record
    # + fields - The fields to be retrieved
    # + include - The associations to be retrieved
    # + return - A stream of records in the `rowType` type or a `persist:Error` if the operation fails
    public isolated function readTableAsStream(typedesc<record {}> rowType, map<anydata> typeMap, string[] fields = [], string[] include = []) returns stream<record {}, Error?>|Error {
        string query = "select *";
        string|error encodedQuery = url:encode(query, "UTF-8");
        if encodedQuery is error {
            return <Error>error(encodedQuery.message());
        }
        http:QueryParams queries = {"gid": self.sheetId, "range": self.range, "tq": <string>encodedQuery, "tqx": "out:csv"};
        http:Response|error response = self.httpClient->/d/[self.spreadsheetId]/gviz/tq(params = queries);
        if response is error {
            return <Error>error(response.message());
        }
        string|error textResponse = response.getTextPayload();
        if textResponse !is error {
            string[] responseRows = re `\n`.split(textResponse);
            record {}[] rowTable = [];
            if responseRows.length() == 0 {
                return <Error>error("Error: the spreadsheet is not initialised correctly.");
            } else if responseRows.length() == 1 {
                return rowTable.toStream();
            }
            string[] columnNames = re `,`.split(responseRows[0]);
            foreach string rowString in responseRows.slice(1) {
                int i = 0;
                record {} rowArray = {};
                string[] rowValues = re `,`.split(rowString);
                foreach string rowValue in rowValues {
                    string columnName = re `"`.replaceAll(columnNames[i], "");
                    string value = re `"`.replaceAll(rowValue, "");
                    string dataType = self.dataTypes.get(columnName).toString();
                    if dataType == "time:Date" || dataType == "time:TimeOfDay" ||dataType == "time:Civil" || dataType == "time:Utc" {
                        SheetFieldType|error typedValue = self.dataConverter(value, dataType);
                        if typedValue is error {
                            return <Error>error(typedValue.message());
                        } else if typedValue is time:Civil {
                            rowArray[columnName] = <time:Civil>typedValue;
                        } else if typedValue is time:Date {
                            rowArray[columnName] = <time:Date>typedValue;
                        } else if typedValue is time:TimeOfDay {
                            rowArray[columnName] = <time:TimeOfDay>typedValue;
                        } else if typedValue is time:Utc {
                            rowArray[columnName] = <time:Utc>typedValue;
                        }
                    } else {
                        SheetFieldType|error typedValue = self.dataConverter(value, dataType);
                        if typedValue is error {
                            return <Error>error(typedValue.message());
                        }
                        rowArray[columnName] = typedValue;
                    }
                    i = i + 1;
                }
                rowTable.push(rowArray);
            }
            return rowTable.toStream();
        } else {
            return <Error>error(textResponse.message());
        }
    }

    # Performs an SQL `UPDATE` operation to update multiple entity records in the database.
    #
    # + key - the key of the entity
    # + updateRecord - the record to be updated
    # + return - `()` if the operation is performed successfully.
    # A `ForeignKeyViolationError` if the operation violates a foreign key constraint.
    # A `persist:Error` if the operation fails due to another reason.
    public isolated function runUpdateQuery(anydata key, record {} updateRecord) returns Error? {
        string[] entityKeys = self.fieldMetadata.keys();
        SheetBasicType[] values = [];
        string metadataValue;
        if key is map<anydata> {
            metadataValue = self.generateMetadataValue(self.keyFields, key);
        } else {
            metadataValue = key.toString();
        }
        sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
        sheets:ValueRange[]|error rows = self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, self.sheetId, filter);
        if rows is error {
            return <Error>error(rows.message());
        }
        if rows.length() == 0 {
            if key is map<anydata> {
                return <NotFoundError>error(string `Not found: ${self.generateKeyArrayString(self.keyFields, key)}`);
            } else {
                return <NotFoundError>error(string `Not found: ${key.toString()}`);
            }
        } else if rows.length() > 1 {
            return <Error>error(string `Multiple elements found for given key: ${key.toString()}`);
        }
        foreach string entityKey in entityKeys {
            if !updateRecord.hasKey(entityKey) && self.keyFields.indexOf(entityKey) != () {
                if key is map<anydata> {
                    (int|string|decimal)|error value = key.get(entityKey).ensureType();
                    if value is error {
                        return <Error>error(value.message());
                    }
                    values.push(value);
                } else if (key is int|string|decimal|float) {
                    values.push(key);
                }
            } else if !updateRecord.hasKey(entityKey) && self.keyFields.indexOf(entityKey) == () {
                int indexOfKey = <int>self.fieldMetadata.keys().indexOf(entityKey, 0);
                string dataType = self.dataTypes.get(entityKey).toString();
                if dataType == "boolean" || dataType == "int" || dataType == "float" || dataType == "decimal" {
                    SheetNumericType|error value = self.valuesFromString(rows[0].values[indexOfKey].toString(), dataType);
                    if value is error {
                        return <Error>error(value.message());
                    }
                    values.push(value);
                } else {
                    values.push(rows[0].values[indexOfKey]);
                }
            } else {
                SheetBasicType|error value;
                string dataType = self.dataTypes.get(entityKey).toString();
                if dataType == "time:Date" || dataType == "time:TimeOfDay" || dataType == "time:Civil" || dataType == "time:Utc" {
                    SheetTimeType|error timeValue = updateRecord.get(entityKey).ensureType();
                    if timeValue is error {
                        return <Error>error(timeValue.message());
                    }
                    value = self.timeToString(timeValue);
                    if value is error {
                        return <Error>error(value.message());
                    }
                    values.push(value);
                } else {
                    value = updateRecord.get(entityKey).ensureType();
                    if value is error {
                        return <Error>error(value.message());
                    }
                    values.push(value);
                }
            }
        }
        error? response = self.googleSheetClient->updateRowByDataFilter(self.spreadsheetId, self.sheetId, filter, values, "USER_ENTERED");
        if response is error {
            return <Error>error(response.message());
        }
    }

    # Performs an SQL `DELETE` operation to delete an entity record from the database.
    #
    # + deleteKey - The key used to delete an entity record
    # + return - `()` if the operation is performed successfully or a `persist:Error` if the operation fails
    public isolated function runDeleteQuery(anydata deleteKey) returns Error? {
        string metadataValue;
        if deleteKey is map<anydata> {
            metadataValue = self.generateMetadataValue(self.keyFields, deleteKey);
        } else {
            metadataValue = deleteKey.toString();
        }
        sheets:DeveloperMetadataLookupFilter filter = {locationType: "ROW", metadataKey: self.tableName, metadataValue: metadataValue};
        sheets:ValueRange[]|error rows = self.googleSheetClient->getRowByDataFilter(self.spreadsheetId, self.sheetId, filter);
        if rows is error {
            if (deleteKey is map<anydata>) {
                return <Error>error(string `Not found: ${self.generateKeyArrayString(self.keyFields, deleteKey)}`);
            } else {
                return <Error>error(string `Not found: ${deleteKey.toString()}`);
            }
        }
        if rows.length() == 0 {
            return <Error>error("no element found for delete");
        }
        error? response = self.googleSheetClient->deleteRowByDataFilter(self.spreadsheetId, self.sheetId, filter);
        if response is error {
            return <Error>error(response.message());
        }
    }

    public isolated function getKeyFields() returns string[] {
        return self.keyFields;
    }

    public isolated function getManyRelations(record {} 'object, string[] fields, string[] include, typedesc<record {}>[] typeDescriptions) returns Error? {
        foreach int i in 0 ..< include.length() {
            string entity = include[i];
            string[] relationFields = from string 'field in fields
                where 'field.startsWith(entity + "[].")
                select 'field.substring(entity.length() + 3, 'field.length());
            if relationFields.length() is 0 {
                continue;
            }
            isolated function (record {}, string[]) returns record {}[]|error associationsMethod = self.associationsMethods.get(entity);
            record {}[]|error relations = associationsMethod('object, relationFields);
            if relations is error {
                return <Error>error("unsupported data format");
            }
            'object[entity] = relations;
        }
    }

    public isolated function addKeyFields(string[] fields) returns string[] {
        string[] updatedFields = fields.clone();
        foreach string key in self.keyFields {
            if updatedFields.indexOf(key) is () {
                updatedFields.push(key);
            }
        }
        return updatedFields;
    }

    private isolated function dataConverter(json value, string dataType) returns SheetFieldType|error {
        if dataType == "int" {
            return int:fromString(value.toString());
        } else if dataType == "time:Date" || dataType == "time:TimeOfDay" ||dataType == "time:Civil" || dataType == "time:Utc" {
            return self.stringToTime(value.toString(), dataType);
        } else if dataType == "string" {
            return value.toString();
        } else if dataType == "decimal" {
            return decimal:fromString(value.toString());
        } else if dataType == "float" {
            return float:fromString(value.toString());
        } else if dataType == "boolean" {
            if value.toString() == "TRUE" {
                return true;
            } else {
                return false;
            } 
        } else {
            return <error>error("unsupported data format");
        }
    }

    private isolated function generateMetadataValue(string[] keyFields, map<anydata> rowValues) returns string {
        string metadataValue = "";
        foreach string key in keyFields {
            if metadataValue != "" {
                metadataValue += ":";
            }
            metadataValue += rowValues[key].toString();
        }
        return metadataValue;
    }

    private isolated function generateKeyArrayString(string[] keyFields, map<anydata> rowValues) returns string {
        string metadataValue = "";
        foreach string key in keyFields {
            if metadataValue != "" {
                metadataValue += ",";
            }
            metadataValue += string `"${rowValues[key].toString()}"`;
        }
        return string `[${metadataValue}]`;
    }

    public isolated function getKey(anydata|record {} 'object) returns anydata|record {} {
        record {} keyRecord = {};

        if self.keyFields.length() == 1 && 'object is record {} {
            return 'object[self.keyFields[0]];
        }

        if 'object is record {} {
            foreach string key in self.keyFields {
                keyRecord[key] = 'object[key];
            }
        } else {
            keyRecord[self.keyFields[0]] = 'object;
        }
        return keyRecord;
    }

    private isolated function removeUnwantedFields(record {} 'object, string[] fields) {
        foreach string keyField in self.keyFields {
            if fields.indexOf(keyField) is () {
                _ = 'object.remove(keyField);
            }
        }
    }

    private isolated function timeToString(SheetTimeType timeValue) returns string|error {

        if timeValue is time:Civil {
            return time:civilToString(timeValue);
        }
        
        if timeValue is time:Utc {
            return time:utcToString(timeValue);
        }

        if timeValue is time:Date {
            return string `${timeValue.day}-${timeValue.month}-${timeValue.year}`;
        }

        if timeValue is time:TimeOfDay {
            return string `${timeValue.hour}-${timeValue.minute}-${(timeValue.second).toString()}`;
        }

        return <Error>error("Error: unsupported time format");

    }

    private isolated function valuesFromString(string value, string dataType) returns SheetNumericType|error {

        match dataType {
            "int" => {
                return int:fromString(value);
            }
            "boolean" => {
                if value == "TRUE" {
                    return true;
                } else {
                    return false;
                }
            }
            "decimal" => {
                return decimal:fromString(value);
            }
            _ => {
                return float:fromString(value.toString());
            }
        }
    }

    private isolated function stringToTime(string timeValue, string dataType) returns SheetTimeType|error {
        if dataType == "time:TimeOfDay" {
            string[] timeValues =  re `-`.split(timeValue);
            time:TimeOfDay output = {hour: check int:fromString(timeValues[0]), minute: check int:fromString(timeValues[1]), second: check decimal:fromString(timeValues[2])};
            return output;
        } else if dataType == "time:Date" {
            string[] timeValues =  re `-`.split(timeValue);
            time:Date output = {day: check int:fromString(timeValues[0]), month: check int:fromString(timeValues[1]), year: check int:fromString(timeValues[2])};
            return output;
        } else if dataType == "time:Civil" {
            return time:civilFromString(timeValue);
        } else if dataType == "time:Utc" {
            return time:utcFromString(timeValue);
        } else {
            return <error>error("Error: unsupported time format");
        }
    }

}
