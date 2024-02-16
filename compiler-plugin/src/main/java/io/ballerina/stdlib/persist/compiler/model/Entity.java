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
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Model class to hold entity properties.
 */
public class Entity {
    private final String entityName;
    private final NodeLocation entityNameLocation;
    private final RecordTypeDescriptorNode typeDescriptorNode;
    private final List<IdentityField> identityFields = new ArrayList<>();
    private final List<SimpleTypeField> nonRelationFields = new ArrayList<>();
    private final HashMap<String, RelationField> relationFields = new HashMap<>();
    private final HashMap<String, GroupedRelationField> groupedRelationFields = new HashMap<>();
    private final List<Diagnostic> diagnosticList = new ArrayList<>();
    private boolean containsRelations = false;
    private NodeList<AnnotationNode> annotations;

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

    public List<String> getIdentityFieldNames() {
        return identityFields.stream().map(IdentityField::getName).collect(Collectors.toList());
    }

    public List<IdentityField> getIdentityFields() {
        return identityFields;
    }

    public void addIdentityField(IdentityField field) {
        this.identityFields.add(field);
    }

    public List<SimpleTypeField> getNonRelationFields() {
        return nonRelationFields;
    }

    public void addNonRelationField(SimpleTypeField field) {
        this.nonRelationFields.add(field);
    }

    public boolean isContainsRelations() {
        return containsRelations;
    }

    public void setContainsRelations(boolean containsRelations) {
        this.containsRelations = containsRelations;
    }

    public HashMap<String, RelationField> getRelationFields() {
        return relationFields;
    }

    public HashMap<String, GroupedRelationField> getGroupedRelationFields() {
        return groupedRelationFields;
    }

    public void addRelationField(RelationField relationField) {
        if (this.relationFields.containsKey(relationField.getType())) {
            RelationField existingRelation = this.relationFields.remove(relationField.getType());
            this.groupedRelationFields.compute(relationField.getType(), (key, value) -> {
                if (value == null) {
                    value = new GroupedRelationField(this.entityName);
                    value.addRelationField(existingRelation);
                }
                value.addRelationField(relationField);
                return value;
            });
        } else if (this.getGroupedRelationFields().containsKey(relationField.getType())) {
            this.getGroupedRelationFields().computeIfPresent(relationField.getType(), (key, value) -> {
                value.addRelationField(relationField);
                return value;
            });
        } else {
            this.relationFields.put(relationField.getType(), relationField);
        }
    }

    public List<Diagnostic> getDiagnostics() {
        return this.diagnosticList;
    }

    public void reportDiagnostic(String code, String message, DiagnosticSeverity severity, NodeLocation location) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, severity);
        this.diagnosticList.add(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public void reportDiagnostic(String code, String message, DiagnosticSeverity severity, NodeLocation location,
                                 List<DiagnosticProperty<?>> diagnosticProperties) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, severity);
        this.diagnosticList.add(DiagnosticFactory.createDiagnostic(diagnosticInfo, location, diagnosticProperties));
    }
    public void setAnnotations(NodeList<AnnotationNode> annotations) {
        this.annotations = annotations;
    }
    public NodeList<AnnotationNode> getAnnotations() {
        return annotations;
    }
}
