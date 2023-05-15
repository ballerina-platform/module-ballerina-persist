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

public client class InMemoryClient {

    private string[] keyFields;
    private isolated function (string[]) returns stream<record {}, Error?> query;
    private isolated function (anydata) returns record {}|InvalidKeyError queryOne;
    private map<isolated function (record {}, string[]) returns record {}[]> associationsMethods;

    public function init(TableMetadata metadata) returns Error? {
        self.keyFields = metadata.keyFields;
        self.query = metadata.query;
        self.queryOne = metadata.queryOne;
        self.associationsMethods = metadata.associationsMethods;
    }

    public isolated function runReadQuery(string[] fields = [])
    returns stream<record {}, Error?> {
        return self.query(self.addKeyFields(fields));
    }

    public isolated function runReadByKeyQuery(typedesc<record {}> rowType, anydata key, string[] fields = [], string[] include = [], typedesc<record {}>[] typeDescriptions = []) returns record {}|Error {
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

    public isolated function getManyRelations(record {} 'object, string[] fields, string[] include, typedesc<record {}>[] typeDescriptions) returns Error? {
        foreach int i in 0 ..< include.length() {
            string entity = include[i];
            string[] relationFields = from string 'field in fields
                where 'field.startsWith(entity + "[].")
                select 'field.substring(entity.length() + 3, 'field.length());

            if relationFields.length() is 0 {
                continue;
            }

            function (record {}, string[]) returns record {}[] associationsMethod = self.associationsMethods.get(entity);
            record {}[] relations = associationsMethod('object, relationFields);
            'object[entity] = relations;
        }
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

    public isolated function getKeyFields() returns string[] {
        return self.keyFields;
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

    private isolated function removeUnwantedFields(record {} 'object, string[] fields) {
        foreach string keyField in self.keyFields {
            if fields.indexOf(keyField) is () {
                _ = 'object.remove(keyField);
            }
        }
    }

}
