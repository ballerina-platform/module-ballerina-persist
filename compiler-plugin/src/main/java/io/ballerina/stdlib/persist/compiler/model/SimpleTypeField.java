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
 * Simple type field model.
 */
public class SimpleTypeField {

    private final String name;
    private final String type;
    private final boolean isValidType;
    private final boolean isNullable;
    private final boolean isArrayType;
    private final NodeLocation nodeLocation;
    private final NodeLocation typeLocation;
    private final List<AnnotationNode> annotations;

    public SimpleTypeField(String name, String type, boolean isValidType, boolean isNullable,
                           boolean isArrayType, NodeLocation location, NodeLocation typeLocation,
                           List<AnnotationNode> annotations) {
        this.name = name;
        this.type = type;
        this.isValidType = isValidType;
        this.isNullable = isNullable;
        this.isArrayType = isArrayType;
        this.nodeLocation = location;
        this.typeLocation = typeLocation;
        this.annotations = Collections.unmodifiableList(annotations);
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public boolean isValidType() {
        return isValidType;
    }

    public boolean isNullable() {
        return isNullable;
    }

    public boolean isArrayType() {
        return isArrayType;
    }

    public NodeLocation getNodeLocation() {
        return nodeLocation;
    }

    public NodeLocation getTypeLocation() {
        return typeLocation;
    }

    public List<AnnotationNode> getAnnotations() {
        return annotations;
    }

}
