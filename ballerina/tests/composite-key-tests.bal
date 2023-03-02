// Copyright (c) 2023 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;

OrderItem orderItem1 = {
    orderId: "order-1",
    itemId: "item-1",
    quantity: 5,
    notes: "none"
};

OrderItem orderItem2 = {
    orderId: "order-2",
    itemId: "item-2",
    quantity: 10,
    notes: "more"
};

OrderItem orderItem2Updated = {
    orderId: "order-2",
    itemId: "item-2",
    quantity: 20,
    notes: "more than more"
};

@test:Config {
    groups: ["composite-key"]
}
function compositeKeyCreateTest() returns error? {
    RainierClient rainierClient = check new ();

    [string, string][] ids = check rainierClient->/orderitem.post([orderItem1, orderItem2]);
    test:assertEquals(ids, [[orderItem1.orderId, orderItem1.itemId], [orderItem2.orderId, orderItem2.itemId]]);

    OrderItem orderItemRetrieved = check rainierClient->/orderitem/[orderItem1.orderId]/[orderItem1.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItem1);

    orderItemRetrieved = check rainierClient->/orderitem/[orderItem2.orderId]/[orderItem2.itemId].get();
    test:assertEquals(orderItemRetrieved, orderItem2);

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    [string, string][]|error ids = rainierClient->/orderitem.post([orderItem1]);
    if ids is DuplicateKeyError {
        test:assertEquals(ids.message(), "A OrderItem entity with the key 'order-1-item-1' already exists.");
    } else {
        test:assertFail("DuplicateKeyError expected");
    }

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<OrderItem, error?> orderItemStream = rainierClient->/orderitem.get();
    OrderItem[] orderitem = check from OrderItem orderItem in orderItemStream
        select orderItem;
    
    test:assertEquals(orderitem, [orderItem1, orderItem2]);
    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyReadOneTest() returns error? {
    RainierClient rainierClient = check new ();
    OrderItem orderItem = check rainierClient->/orderitem/[orderItem1.orderId]/[orderItem1.itemId].get();    
    test:assertEquals(orderItem, orderItem1);
    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key2"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyReadOneTest2() returns error? {
    RainierClient rainierClient = check new ();
    OrderItem orderItem = check rainierClient->/orderitemd/[orderItem1.orderId]/[orderItem1.itemId].get();    
    test:assertEquals(orderItem, orderItem1);
    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyReadOneTestNegative1() returns error? {
    RainierClient rainierClient = check new ();
    OrderItem|error orderItem = rainierClient->/orderitem/["invalid-order-id"]/[orderItem1.itemId].get();

    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "A record does not exist for 'OrderItem' for key {\"orderId\":\"invalid-order-id\",\"itemId\":\"item-1\"}.");
    } else {
        test:assertFail("Error expected.");
    }

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest]
}
function compositeKeyReadOneTestNegative2() returns error? {
    RainierClient rainierClient = check new ();
    OrderItem|error orderItem = rainierClient->/orderitem/[orderItem1.orderId]/["invalid-item-id"].get();

    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "A record does not exist for 'OrderItem' for key {\"orderId\":\"order-1\",\"itemId\":\"invalid-item-id\"}.");
    } else {
        test:assertFail("Error expected.");
    }

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest, compositeKeyReadOneTest, compositeKeyReadManyTest, compositeKeyReadOneTest2]
}
function compositeKeyUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    OrderItem orderItem = check rainierClient->/orderitem/[orderItem2.orderId]/[orderItem2.itemId].put({
        quantity: orderItem2Updated.quantity,
        notes: orderItem2Updated.notes
    });
    test:assertEquals(orderItem, orderItem2Updated);

    orderItem = check rainierClient->/orderitem/[orderItem2.orderId]/[orderItem2.itemId].get();    
    test:assertEquals(orderItem, orderItem2Updated);

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyCreateTest, compositeKeyReadOneTest, compositeKeyReadManyTest, compositeKeyReadOneTest2]
}
function compositeKeyUpdateTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    OrderItem|error orderItem = rainierClient->/orderitem/[orderItem1.orderId]/[orderItem2.itemId].put({
        quantity: 239,
        notes: "updated notes"
    });
    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "A record does not exist for 'OrderItem' for key {\"orderId\":\"order-1\",\"itemId\":\"item-2\"}.");
    } else {
        test:assertFail("Error expected.");
    }

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyUpdateTest]
}
function compositeKeyDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    OrderItem orderItem = check rainierClient->/orderitem/[orderItem2.orderId]/[orderItem2.itemId].delete();
    test:assertEquals(orderItem, orderItem2Updated);

    OrderItem|error orderItemRetrieved =  rainierClient->/orderitem/[orderItem2.orderId]/[orderItem2.itemId].get();    
    test:assertTrue(orderItemRetrieved is InvalidKeyError);

    check rainierClient.close();
}

@test:Config {
    groups: ["composite-key"],
    dependsOn: [compositeKeyUpdateTest]
}
function compositeKeyDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    OrderItem|error orderItem = rainierClient->/orderitem/["invalid-order-id"]/[orderItem2.itemId].delete();
    if orderItem is InvalidKeyError {
        test:assertEquals(orderItem.message(), "A record does not exist for 'OrderItem' for key {\"orderId\":\"invalid-order-id\",\"itemId\":\"item-2\"}.");
    } else {
        test:assertFail("Error expected.");
    }

    check rainierClient.close();
}
