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
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Model class to hold entity properties.
 */
public class Entity {
    private final String entityName;
    private final NodeLocation entityNameLocation;
    private final RecordTypeDescriptorNode typeDescriptorNode;
    private final List<String> identifierFields = new ArrayList<>();
    private final Map<String, NodeLocation> nonRelationFields = new HashMap<>();
    private final List<RelationField> relationFields = new ArrayList<>();
    private final List<Diagnostic> diagnosticList = new ArrayList<>();
    private int readonlyFieldCount = 0;
    private boolean containsRelations = false;

    public Entity(String entityName, NodeLocation entityNameLocation, RecordTypeDescriptorNode typeDescriptorNode) {
        this.entityName = entityName;
        this.entityNameLocation = entityNameLocation;
        this.typeDescriptorNode = typeDescriptorNode;
    }

    public String getEntityName() {
        return entityName;
    }

    public NodeLocation getEntityNameLocation() {
        return entityNameLocation;
    }

    public RecordTypeDescriptorNode getTypeDescriptorNode() {
        return typeDescriptorNode;
    }

    public int getReadonlyFieldCount() {
        return readonlyFieldCount;
    }

    public void incrementReadonlyFieldCount() {
        this.readonlyFieldCount++;
    }

    public List<String> getIdentifierFields() {
        return identifierFields;
    }

    public void addIdentifierField(String fieldName) {
        this.identifierFields.add(fieldName);
    }

    public Map<String, NodeLocation> getNonRelationFields() {
        return nonRelationFields;
    }

    public void addNonRelationField(String fieldName, NodeLocation location) {
        this.nonRelationFields.put(fieldName, location);
    }

    public boolean isContainsRelations() {
        return containsRelations;
    }

    public void setContainsRelations(boolean containsRelations) {
        this.containsRelations = containsRelations;
    }

    public List<RelationField> getRelationFields() {
        return relationFields;
    }

    public void addRelationField(RelationField relationField) {
        this.relationFields.add(relationField);
    }

    public List<Diagnostic> getDiagnostics() {
        return this.diagnosticList;
    }

    public void reportDiagnostic(String code, String message, DiagnosticSeverity severity, NodeLocation location) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, severity);
        this.diagnosticList.add(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

}
