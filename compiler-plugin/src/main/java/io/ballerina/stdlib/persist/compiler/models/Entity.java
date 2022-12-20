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

import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

/**
 * Process Entity information.
 */
public class Entity {
    private final String entityName;
    private final String module;
    private final Set<String> entityFieldNames;
    private final NodeLocation location;
    private final List<Field> validEntityFields = new ArrayList<>();
    private final HashMap<String, NodeLocation> primaryKeys = new HashMap<>();
    private final List<HashMap<String, NodeLocation>> uniqueConstraints = new ArrayList<>();
    private final List<Diagnostic> diagnosticList = new ArrayList<>();

    public Entity(String entityName, String module, Set<String> entityFieldNames, NodeLocation location) {
        this.entityName = entityName;
        this.module = module;
        this.entityFieldNames = entityFieldNames;
        this.location = location;
    }

    public String getEntityName() {
        return this.entityName;
    }

    public boolean primaryKeysContains(String key) {
        return this.primaryKeys.containsKey(key);
    }

    public void addPrimaryKey(String key, NodeLocation nodeLocation) {
        this.primaryKeys.put(key, nodeLocation);
    }

    public HashMap<String, NodeLocation> getPrimaryKeys() {
        return this.primaryKeys;
    }

    public Set<String> getEntityFieldNames() {
        return this.entityFieldNames;
    }

    public void addUniqueConstraints(HashMap<String, NodeLocation> uniqueConstraint) {
        HashMap<String, NodeLocation> uniqueConstraintCopy = new HashMap<>(uniqueConstraint);
        this.uniqueConstraints.add(uniqueConstraintCopy);
    }

    public List<HashMap<String, NodeLocation>> getUniqueConstraints() {
        return this.uniqueConstraints;
    }

    public void addField(Field field) {
        this.validEntityFields.add(field);
    }

    public List<Field> getValidEntityFields() {
        return this.validEntityFields;
    }

    public String getModule() {
        return this.module;
    }

    public NodeLocation getLocation() {
        return this.location;
    }

    public List<Diagnostic> getDiagnostics() {
        return this.diagnosticList;
    }

    public void addDiagnostic(NodeLocation location, String code, String message, DiagnosticSeverity severity) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(code, message, severity);
        this.diagnosticList.add(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }
}
