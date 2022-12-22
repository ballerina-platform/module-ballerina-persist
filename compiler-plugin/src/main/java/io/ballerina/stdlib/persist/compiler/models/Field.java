/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.persist.compiler.models;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;

/**
 * Model class to represent fields.
 */
public class Field {
    private final String fieldName;
    private final NodeLocation fieldLocation;
    private final AnnotationNode autoIncrement;
    private final AnnotationNode relationAnnotation;
    // Keep a reference to containing entity for easy of processing in relations
    private final String containingEntityName;
    private SeparatedNodeList<Node> keyColumnExpressions;
    private SeparatedNodeList<Node> referenceExpressions;

    private boolean isReadOnly = false;
    private Node type;
    private NodeLocation typeLocation;
    private boolean isValidRelationAttachmentPoint = false;
    private boolean isRelationAttachedToValidEntity = false;
    private boolean isOptional = false;
    private boolean isArrayType = false;

    public Field(String fieldName, NodeLocation fieldLocation, AnnotationNode autoIncrementNode,
                 AnnotationNode relationAnnotation, String containingEntityName) {
        this.fieldName = fieldName;
        this.fieldLocation = fieldLocation;
        this.autoIncrement = autoIncrementNode;
        this.relationAnnotation = relationAnnotation;
        this.containingEntityName = containingEntityName;
    }

    public String getFieldName() {
        return this.fieldName;
    }

    public boolean isReadOnly() {
        return this.isReadOnly;
    }

    public void setReadOnly(boolean readOnly) {
        this.isReadOnly = readOnly;
    }

    public Node getType() {
        return this.type;
    }

    public void setType(Node type) {
        this.type = type;
    }

    public NodeLocation getTypeLocation() {
        return this.typeLocation;
    }

    public void setTypeLocation(NodeLocation typeLocation) {
        this.typeLocation = typeLocation;
    }

    public AnnotationNode getAutoIncrement() {
        return this.autoIncrement;
    }

    public AnnotationNode getRelationAnnotation() {
        return this.relationAnnotation;
    }

    public boolean isValidRelationAttachmentPoint() {
        return isValidRelationAttachmentPoint;
    }

    public void setValidRelationAttachmentPoint(boolean validRelationAttachmentPoint) {
        isValidRelationAttachmentPoint = validRelationAttachmentPoint;
    }

    public boolean isRelationAttachedToValidEntity() {
        return this.isRelationAttachedToValidEntity;
    }

    public void setRelationAttachedToValidEntity(boolean relationAttachedToValidEntity) {
        this.isRelationAttachedToValidEntity = relationAttachedToValidEntity;
    }

    public boolean isOptional() {
        return this.isOptional;
    }

    public void setOptional(boolean optional) {
        this.isOptional = optional;
    }

    public NodeLocation getFieldLocation() {
        return fieldLocation;
    }

    public boolean isArrayType() {
        return isArrayType;
    }

    public void setArrayType(boolean arrayType) {
        isArrayType = arrayType;
    }

    public String getContainingEntityName() {
        return containingEntityName;
    }

    public SeparatedNodeList<Node> getKeyColumnExpressions() {
        return keyColumnExpressions;
    }

    public void setKeyColumnExpressions(SeparatedNodeList<Node> keyColumnExpressions) {
        this.keyColumnExpressions = keyColumnExpressions;
    }

    public SeparatedNodeList<Node> getReferenceExpressions() {
        return referenceExpressions;
    }

    public void setReferenceExpressions(SeparatedNodeList<Node> referenceExpressions) {
        this.referenceExpressions = referenceExpressions;
    }
}
