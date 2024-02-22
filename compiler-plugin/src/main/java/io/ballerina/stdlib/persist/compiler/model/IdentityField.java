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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeLocation;

/**
 * Model Class for identity field.
 */
public class IdentityField {
    private final String name;
    private String type;
    private int readonlyTextRangeStartOffset = 0;
    private boolean isNullable = false;
    private int nullableStartOffset = 0;
    private boolean isValidType = false;
    private NodeLocation typeLocation;

    private NodeList<AnnotationNode> annotations;

    public IdentityField(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public int getReadonlyTextRangeStartOffset() {
        return readonlyTextRangeStartOffset;
    }

    public void setReadonlyTextRangeStartOffset(int readonlyTextRangeStartOffset) {
        this.readonlyTextRangeStartOffset = readonlyTextRangeStartOffset;
    }

    public boolean isValidType() {
        return isValidType;
    }

    public void setValidType(boolean validType) {
        isValidType = validType;
    }

    public boolean isNullable() {
        return isNullable;
    }

    public void setNullable(boolean nullable) {
        isNullable = nullable;
    }

    public int getNullableStartOffset() {
        return nullableStartOffset;
    }

    public void setNullableStartOffset(int nullableStartOffset) {
        this.nullableStartOffset = nullableStartOffset;
    }

    public NodeLocation getTypeLocation() {
        return typeLocation;
    }

    public void setTypeLocation(NodeLocation typeLocation) {
        this.typeLocation = typeLocation;
    }

    public NodeList<AnnotationNode> getAnnotations() {
        return annotations;
    }

    public void setAnnotations(NodeList<AnnotationNode> annotations) {
        this.annotations = annotations;
    }
}
