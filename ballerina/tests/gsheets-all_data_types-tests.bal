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

import ballerina/test;

//GoogleSheetsRainierClientAllDataType rainierClientAllDataType =  check new (); // Uncomment for local testing

@test:Config {
    groups: ["composite-key", "google-sheets"],
    enable: false
}
function gsheetsAllDataTypeCreateTest() returns error? {
    GoogleSheetsRainierClientAllDataType rainierClientAllDataType =  check new ();
    [string, string][] ids = check rainierClientAllDataType->/orderitemextendeds.post([orderItemExtended1, orderItemExtended2]);
    test:assertEquals(ids, [[orderItemExtended1.orderId, orderItemExtended1.itemId], [orderItemExtended2.orderId, orderItemExtended2.itemId]]);

    OrderItemExtended orderItemRetrieved = check rainierClientAllDataType->/orderitemextendeds/[orderItemExtended1.orderId]/[orderItemExtended1.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItemExtendedRetrieved);

    orderItemRetrieved = check rainierClientAllDataType->/orderitemextendeds/[orderItemExtended2.orderId]/[orderItemExtended2.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItemExtended2Retrieved);
}


@test:Config {
    groups: ["all-types", "google-sheets"],
    dependsOn: [gsheetsAllDataTypeCreateTest],
    enable: false
}
function gsheetsAllTypesReadManyTest() returns error? {
    GoogleSheetsRainierClientAllDataType rainierClientAllDataType =  check new ();
    stream<OrderItemExtended, error?> orderItemStream = rainierClientAllDataType->/orderitemextendeds.get();
    OrderItemExtended[] orderitem = check from OrderItemExtended orderItem in orderItemStream
        select orderItem;

    test:assertEquals(orderitem, [orderItemExtendedRetrieved, orderItemExtended2Retrieved]);
}

@test:Config {
    groups: ["all-types", "google-sheets"],
    dependsOn: [gsheetsAllDataTypeCreateTest],
    enable: false
}
function gsheetsAllDataTypeUpdateTest() returns error? {
    GoogleSheetsRainierClientAllDataType rainierClientAllDataType =  check new ();
    OrderItemExtended orderItemRetrieved = check rainierClientAllDataType->/orderitemextendeds/[orderItemExtended2.orderId]/[orderItemExtended2.itemId].put({
        arivalTimeCivil : orderItemExtended3.arivalTimeCivil,
        paid: orderItemExtended3.paid
    });
    test:assertEquals(orderItemRetrieved, orderItemExtended3Retrieved);

    orderItemRetrieved = check rainierClientAllDataType->/orderitemextendeds/[orderItemExtended2.orderId]/[orderItemExtended2.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItemExtended3Retrieved);
}