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
import io.ballerina.compiler.syntax.tree.NodeLocation;

import java.util.Collections;
import java.util.List;

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
    private final int arrayStartOffset;
    private final int arrayRangeLength;
    private final String containingEntity;
    private final NodeLocation location;
    private boolean isOwnerIdentifiable = false;
    private String owner = null;
    private RelationType relationType;
    private final List<AnnotationNode> annotations;

    public RelationField(String name, String type, int typeEndOffset, boolean isOptionalType, int nullableStartOffset,
                         boolean isArrayType, int arrayStartOffset, int arrayRangeLength, NodeLocation location,
                         String containingEntity, List<AnnotationNode> annotations) {
        this.name = name;
        this.type = type;
        this.typeEndOffset = typeEndOffset;
        this.isOptionalType = isOptionalType;
        this.nullableStartOffset = nullableStartOffset;
        this.isArrayType = isArrayType;
        this.arrayStartOffset = arrayStartOffset;
        this.arrayRangeLength = arrayRangeLength;
        this.location = location;
        this.containingEntity = containingEntity;
        this.annotations = Collections.unmodifiableList(annotations);
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

    public int getArrayStartOffset() {
        return arrayStartOffset;
    }

    public int getArrayRangeLength() {
        return arrayRangeLength;
    }

    public String getContainingEntity() {
        return containingEntity;
    }

    public NodeLocation getLocation() {
        return location;
    }

    public boolean isOwnerIdentifiable() {
        return isOwnerIdentifiable;
    }

    public void setOwnerIdentifiable(boolean ownerIdentifiable) {
        isOwnerIdentifiable = ownerIdentifiable;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    public RelationType getRelationType() {
        return relationType;
    }

    public void setRelationType(RelationType relationType) {
        this.relationType = relationType;
    }

    public List<AnnotationNode> getAnnotations() {
        return annotations;
    }

}
