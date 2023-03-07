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
 * Model class to hold relation field details.
 */
public class RelationField {
    private final String name;
    private final String type;
    private final int typeEndOffset;
    private final boolean isOptionalType;
    private final int nullableStartOffset;
    private final boolean isArrayType;
    private final String containingEntity;
    private final NodeLocation location;

    public RelationField(String name, String type, int typeEndOffset, boolean isOptionalType, int nullableStartOffset,
                         boolean isArrayType, NodeLocation location, String containingEntity) {
        this.name = name;
        this.type = type;
        this.typeEndOffset = typeEndOffset;
        this.isOptionalType = isOptionalType;
        this.nullableStartOffset = nullableStartOffset;
        this.isArrayType = isArrayType;
        this.location = location;
        this.containingEntity = containingEntity;
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public int getTypeEndOffset() {
        return typeEndOffset;
    }

    public boolean isOptionalType() {
        return isOptionalType;
    }

    public int getNullableStartOffset() {
        return nullableStartOffset;
    }

    public boolean isArrayType() {
        return isArrayType;
    }

    public String getContainingEntity() {
        return containingEntity;
    }

    public NodeLocation getLocation() {
        return location;
    }
}
