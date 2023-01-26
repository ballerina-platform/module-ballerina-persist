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

package io.ballerina.stdlib.persist.compiler.model;

import io.ballerina.compiler.syntax.tree.NodeLocation;

/**
 * Model Class for identifier field.
 */
public class IdentifierField {
    private final String name;
    private boolean isSimpleType = false;
    private boolean isNullable = false;
    private NodeLocation typeLocation;

    public IdentifierField(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public boolean isSimpleType() {
        return isSimpleType;
    }

    public void setSimpleType(boolean simpleType) {
        isSimpleType = simpleType;
    }

    public boolean isNullable() {
        return isNullable;
    }

    public void setNullable(boolean nullable) {
        isNullable = nullable;
    }

    public NodeLocation getTypeLocation() {
        return typeLocation;
    }

    public void setTypeLocation(NodeLocation typeLocation) {
        this.typeLocation = typeLocation;
    }
}
