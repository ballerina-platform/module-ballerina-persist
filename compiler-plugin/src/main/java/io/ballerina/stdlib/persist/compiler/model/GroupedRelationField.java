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

import java.util.ArrayList;
import java.util.List;

/**
 * Model class to hold grouped relation field details per type.
 */
public class GroupedRelationField {
    private final String containingEntity;
    private final List<RelationField> fields = new ArrayList<>();

    public GroupedRelationField(String containingEntity) {
        this.containingEntity = containingEntity;
    }

    public void addRelationField(RelationField field) {
        fields.add(field);
    }

    public String getContainingEntity() {
        return containingEntity;
    }

    public List<RelationField> getRelationFields() {
        return fields;
    }
}
