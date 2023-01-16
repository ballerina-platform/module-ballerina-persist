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

package io.ballerina.stdlib.persist.compiler;

import io.ballerina.compiler.syntax.tree.EnumDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.projects.ProjectKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.projects.util.ProjectConstants;
import io.ballerina.stdlib.persist.compiler.model.Entity;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.io.File;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.persist.compiler.Constants.PERSIST_DIRECTORY;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_101;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_110;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_111;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_112;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_113;

/**
 * Persist model definition validator.
 */
public class PersistModelDefinitionValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final List<String> enums = new ArrayList<>();
    private final List<Entity> entities = new ArrayList<>();

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (!isPersistModelDefinitionDocument(ctx)) {
            return;
        }

        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }

        ModulePartNode rootNode = (ModulePartNode) ctx.node();
        for (ModuleMemberDeclarationNode member : rootNode.members()) {
            if (member instanceof EnumDeclarationNode) {
                this.enums.add(((EnumDeclarationNode) member).identifier().text().trim());
                continue;
            }
            if (member instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) member;
                TypeDescriptorNode typeDescriptorNode = (TypeDescriptorNode) typeDefinitionNode.typeDescriptor();
                if (typeDescriptorNode instanceof RecordTypeDescriptorNode) {
                    String entityName = typeDefinitionNode.typeName().text().trim();
                    this.entities.add(new Entity(entityName, ((RecordTypeDescriptorNode) typeDescriptorNode)));
                    continue;
                }
            }
            ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                    new DiagnosticInfo(PERSIST_101.getCode(), PERSIST_101.getMessage(), PERSIST_101.getSeverity()),
                    member.location()));
        }

        for (Entity entity : this.entities) {
            validateEntityRecordProperties(entity);
            validateEntityFields(entity);
            entity.getDiagnostics().forEach((ctx::reportDiagnostic));
        }
    }

    private void validateEntityRecordProperties(Entity entity) {
        // Check whether the entity is a closed record
        RecordTypeDescriptorNode recordTypeDescriptorNode = entity.getTypeDescriptorNode();
        if (recordTypeDescriptorNode.bodyStartDelimiter().kind() != SyntaxKind.OPEN_BRACE_PIPE_TOKEN) {
            entity.addDiagnostic(PERSIST_102.getCode(), PERSIST_102.getMessage(), PERSIST_102.getSeverity(),
                    recordTypeDescriptorNode.location());
        }
    }

    private void validateEntityFields(Entity entity) {
        // Check whether the entity has rest field initialization
        RecordTypeDescriptorNode typeDescriptorNode = entity.getTypeDescriptorNode();
        if (typeDescriptorNode.recordRestDescriptor().isPresent()) {
            entity.addDiagnostic(PERSIST_110.getCode(), PERSIST_110.getMessage(), PERSIST_110.getSeverity(),
                    typeDescriptorNode.recordRestDescriptor().get().location());
        }

        NodeList<Node> fields = typeDescriptorNode.fields();
        for (Node fieldNode : fields) {
            RecordFieldNode recordFieldNode;
            if (fieldNode instanceof RecordFieldNode) {
                recordFieldNode = (RecordFieldNode) fieldNode;
            } else if (fieldNode instanceof RecordFieldWithDefaultValueNode) {
                entity.addDiagnostic(PERSIST_111.getCode(), PERSIST_111.getMessage(), PERSIST_111.getSeverity(),
                        fieldNode.location());
                continue;
            } else {
                // Inherited Field
                entity.addDiagnostic(PERSIST_112.getCode(), PERSIST_112.getMessage(), PERSIST_112.getSeverity(),
                        fieldNode.location());
                continue;
            }

            // Check if optional field
            if (recordFieldNode.questionMarkToken().isPresent()) {
                entity.addDiagnostic(PERSIST_113.getCode(), PERSIST_113.getMessage(), PERSIST_113.getSeverity(),
                        recordFieldNode.location());
            }
        }
    }

    private boolean isPersistModelDefinitionDocument(SyntaxNodeAnalysisContext ctx) {
        try {
            if (ctx.currentPackage().project().kind().equals(ProjectKind.SINGLE_FILE_PROJECT)) {
                Path balFilePath = ctx.currentPackage().project().sourceRoot().toAbsolutePath();
                Path balFileContainingFolder = balFilePath.getParent();
                if (balFileContainingFolder != null && balFileContainingFolder.endsWith(PERSIST_DIRECTORY)) {
                    Path balProjectDir = balFileContainingFolder.getParent();
                    if (balProjectDir != null) {
                        File balProject = balProjectDir.toFile();
                        if (balProject.isDirectory()) {
                            File tomlFile = balProjectDir.resolve(ProjectConstants.BALLERINA_TOML).toFile();
                            return tomlFile.exists();
                        }
                    }
                }
            }
        } catch (UnsupportedOperationException e) {
            //todo log properly This is to identify any issues in resolving path
        }
        return false;
    }
}
