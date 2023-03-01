/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.persist.compiler.codeaction;

/**
 * Enum class to hold unique code action names.
 */
public enum PersistCodeActionName {

    REMOVE_DIAGNOSTIC_LOCATION("REMOVE_DIAGNOSTIC_LOCATION"),
    REMOVE_TEXT_RANGE("REMOVE_TEXT_RANGE"),
    REMOVE_NIL_TYPE("REMOVE_NIL_TYPE"),

    CHANGE_TO_CLOSED_RECORD("CHANGE_TO_CLOSED_RECORD"),

    ADD_RELATION_FIELD_IN_RELATED_ENTITY("ADD_RELATION_FIELD_IN_RELATED_ENTITY"),

    CHANGE_TYPE_TO_INT("CHANGE_TYPE_TO_INT"),
    CHANGE_TYPE_TO_STRING("CHANGE_TYPE_TO_STRING"),
    CHANGE_TYPE_TO_FLOAT("CHANGE_TYPE_TO_FLOAT"),
    CHANGE_TYPE_TO_BOOLEAN("CHANGE_TYPE_TO_BOOLEAN"),
    CHANGE_TYPE_TO_DECIMAL("CHANGE_TYPE_TO_DECIMAL"),
    CHANGE_TYPE_TO_BYTE_ARRAY("CHANGE_TYPE_TO_BYTE_ARRAY");

    private final String name;

    PersistCodeActionName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
