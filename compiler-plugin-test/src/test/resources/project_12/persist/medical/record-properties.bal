// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.org)
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

import ballerina/persist as _;
import ballerina/time;

public enum EnumType {
    TYPE_1,
    TYPE_2
}

public type MedicalNeed record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    EnumType enumType;
|};

public type MedicalNeed2 record {
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
};
