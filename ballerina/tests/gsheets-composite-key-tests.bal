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

GoogleSheetsRainierClient rainierClient = check new ();

@test:Config {
    groups: ["composite-key", "google-sheets"]
}
function gsheetsCompositeKeyCreateTest() returns error? {
    [string, string][] ids = check rainierClient->/orderitems.post([orderItem1, orderItem2]);
    test:assertEquals(ids, [[orderItem1.orderId, orderItem1.itemId], [orderItem2.orderId, orderItem2.itemId]]);

    OrderItem orderItemRetrieved = check rainierClient->/orderitems/[orderItem1.orderId]/[orderItem1.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItem1);

    orderItemRetrieved = check rainierClient->/orderitems/[orderItem2.orderId]/[orderItem2.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItem2);
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCmpositeKeyCreateTestNegative() returns error? {
    

    [string, string][]|error ids = rainierClient->/orderitems.post([orderItem1]);
    if ids is DuplicateKeyError {
        test:assertEquals(ids.message(), "Duplicate key: [\"order-1\",\"item-1\"]");
    } else {
        test:assertFail("DuplicateKeyError expected");
    }
    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCompositeKeyReadManyTest() returns error? {
    

    stream<OrderItem, error?> orderItemStream = rainierClient->/orderitems.get();
    OrderItem[] orderitem = check from OrderItem orderItem in orderItemStream
        select orderItem;

    test:assertEquals(orderitem, [orderItem1, orderItem2]);
    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCompositeKeyReadOneTest() returns error? {
    
    OrderItem orderItem = check rainierClient->/orderitems/[orderItem1.orderId]/[orderItem1.itemId].get();
    test:assertEquals(orderItem, orderItem1);
    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCompositeKeyReadOneTest2() returns error? {
    
    OrderItem orderItem = check rainierClient->/orderitems/[orderItem1.orderId]/[orderItem1.itemId].get();
    test:assertEquals(orderItem, orderItem1);
    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCompositeKeyReadOneTestNegative1() returns error? {
    
    OrderItem|error orderItem = rainierClient->/orderitems/["invalid-order-id"]/[orderItem1.itemId].get();

    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "Invalid key: {\"orderId\":\"invalid-order-id\",\"itemId\":\"item-1\"}");
    } else {
        test:assertFail("Error expected.");
    }

    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest]
}
function gsheetsCompositeKeyReadOneTestNegative2() returns error? {
    
    OrderItem|error orderItem = rainierClient->/orderitems/[orderItem1.orderId]/["invalid-item-id"].get();

    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "Invalid key: {\"orderId\":\"order-1\",\"itemId\":\"invalid-item-id\"}");
    } else {
        test:assertFail("Error expected.");
    }

    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest, gsheetsCompositeKeyReadOneTest, gsheetsCompositeKeyReadManyTest, gsheetsCompositeKeyReadOneTest2]
}
function gsheetsCompositeKeyUpdateTest() returns error? {
    

    OrderItem orderItem = check rainierClient->/orderitems/[orderItem2.orderId]/[orderItem2.itemId].put({
        quantity: orderItem2Updated.quantity,
        notes: orderItem2Updated.notes
    });
    test:assertEquals(orderItem, orderItem2Updated);

    orderItem = check rainierClient->/orderitems/[orderItem2.orderId]/[orderItem2.itemId].get();
    test:assertEquals(orderItem, orderItem2Updated);

    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyCreateTest, gsheetsCompositeKeyReadOneTest, gsheetsCompositeKeyReadManyTest, gsheetsCompositeKeyReadOneTest2]
}
function gsheetsCompositeKeyUpdateTestNegative() returns error? {
    

    OrderItem|error orderItem = rainierClient->/orderitems/[orderItem1.orderId]/[orderItem2.itemId].put({
        quantity: 239,
        notes: "updated notes"
    });
    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "Not found: [\"order-1\",\"item-2\"]");
    } else {
        test:assertFail("Error expected.");
    }

    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyUpdateTest]
}
function gsheetsCompositeKeyDeleteTest() returns error? {
    OrderItem orderItem = check rainierClient->/orderitems/[orderItem2.orderId]/[orderItem2.itemId].delete();
    test:assertEquals(orderItem, orderItem2Updated);

    OrderItem|error orderItemRetrieved = rainierClient->/orderitems/[orderItem2.orderId]/[orderItem2.itemId].get();
    test:assertTrue(orderItemRetrieved is InvalidKeyError);

    
}

@test:Config {
    groups: ["composite-key", "google-sheets"],
    dependsOn: [gsheetsCompositeKeyDeleteTest]
}
function gsheetsCompositeKeyDeleteTestNegative() returns error? {
    

    OrderItem|error orderItem = rainierClient->/orderitems/["invalid-order-id"]/[orderItem2.itemId].delete();
    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "Invalid key: {\"orderId\":\"invalid-order-id\",\"itemId\":\"item-2\"}");
    } else {
        test:assertFail("Error expected.");
    }

    
}
