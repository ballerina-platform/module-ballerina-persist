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
import ballerina/sql;

public class PersistStream {
    
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private string[]? fields;
    private string[]? include;
    private typedesc<record{}>[]? typeDescriptions = ();
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), string[]? fields = (), string[]? include = (), any[]? typeDescriptions = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.fields = fields;
        self.include = include;

        if typeDescriptions is any[] {
            typedesc<record{}>[] typeDescriptionsArray = [];
            foreach any typeDescription in typeDescriptions {
                typeDescriptionsArray.push(<typedesc<record {}>>typeDescription);
            }
            self.typeDescriptions = typeDescriptionsArray;
        } 
        
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|anydata value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                anydata|error value = streamValue.value;
                if value is error {
                    return <Error>error(value.message());
                }
                record {|anydata value;|} nextRecord = {value: value};
                if self.include is string[] {
                    check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <string[]> self.fields, <string[]>self.include, <typedesc<record {}>[]>self.typeDescriptions);
                }
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}
