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

/**
 * Model class to represent fields.
 */
public class Field {
    private final String fieldName;
    private final AnnotationNode autoIncrement;
    private final AnnotationNode relationAnnotation;
    private boolean isRelationAttachedToValidEntity;

    public Field(String fieldName, AnnotationNode autoIncrementNode, AnnotationNode relationAnnotation) {
        this.fieldName = fieldName;
        this.autoIncrement = autoIncrementNode;
        this.relationAnnotation = relationAnnotation;
        this.isRelationAttachedToValidEntity = false;
    }

    public String getFieldName() {
        return fieldName;
    }

    public AnnotationNode getAutoIncrement() {
        return autoIncrement;
    }

    public AnnotationNode getRelationAnnotation() {
        return relationAnnotation;
    }

    public boolean isRelationAttachedToValidEntity() {
        return isRelationAttachedToValidEntity;
    }

    public void setRelationAttachedToValidEntity(boolean relationAttachedToValidEntity) {
        this.isRelationAttachedToValidEntity = relationAttachedToValidEntity;
    }
}
