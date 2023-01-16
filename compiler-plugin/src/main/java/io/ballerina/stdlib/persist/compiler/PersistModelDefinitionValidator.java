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

import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.BuiltinSimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.EnumDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.OptionalTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
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
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.CIVIL;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.DATE;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.TIME_OF_DAY;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes.UTC;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.BOOLEAN;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.BYTE;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.DECIMAL;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.FLOAT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.INT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.STRING;
import static io.ballerina.stdlib.persist.compiler.Constants.PERSIST_DIRECTORY;
import static io.ballerina.stdlib.persist.compiler.Constants.TIME_MODULE;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_101;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_103;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_110;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_111;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_112;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_113;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_114;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_115;

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
                    this.entities.add(new Entity(entityName, typeDefinitionNode.typeName().location(),
                            ((RecordTypeDescriptorNode) typeDescriptorNode)));
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
            validateIdentifierFieldCount(entity);
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
                if (recordFieldNode.readonlyKeyword().isPresent()) {
                    entity.incrementReadonlyFieldCount();
                }
            } else if (fieldNode instanceof RecordFieldWithDefaultValueNode) {
                if (((RecordFieldWithDefaultValueNode) fieldNode).readonlyKeyword().isPresent()) {
                    entity.incrementReadonlyFieldCount();
                }
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

            Node typeNode = recordFieldNode.typeName();
            Node processedTypeNode = typeNode;
            String typeNamePostfix = "";
            boolean isArrayType = false;
            if (processedTypeNode instanceof OptionalTypeDescriptorNode) {
                processedTypeNode = ((OptionalTypeDescriptorNode) processedTypeNode).typeDescriptor();
                typeNamePostfix = SyntaxKind.QUESTION_MARK_TOKEN.stringValue();
            }
            if (processedTypeNode instanceof ArrayTypeDescriptorNode) {
                isArrayType = true;
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) processedTypeNode);
                processedTypeNode = arrayTypeDescriptorNode.memberTypeDesc();
                typeNamePostfix = SyntaxKind.OPEN_BRACKET_TOKEN.stringValue() +
                        SyntaxKind.CLOSE_BRACKET_TOKEN.stringValue() + typeNamePostfix;
            }

            if (processedTypeNode instanceof BuiltinSimpleNameReferenceNode) {
                String type = ((BuiltinSimpleNameReferenceNode) processedTypeNode).name().text();
                if (isValidSimpleType(type)) {
                    if (isArrayType) {
                        entity.addDiagnostic(PERSIST_115.getCode(), PERSIST_115.getMessage(), PERSIST_115.getSeverity(),
                                processedTypeNode.location());
                    }
                } else if (!(type.equals(BYTE) && isArrayType)) {
                    entity.addDiagnostic(PERSIST_114.getCode(), MessageFormat.format(PERSIST_114.getMessage(),
                                    type + typeNamePostfix), PERSIST_114.getSeverity(),
                                typeNode.location());
                    }
            } else if (processedTypeNode instanceof QualifiedNameReferenceNode) {
                // Support only time constructs
                QualifiedNameReferenceNode qualifiedName = (QualifiedNameReferenceNode) processedTypeNode;
                String modulePrefix = qualifiedName.modulePrefix().text();
                String identifier = qualifiedName.identifier().text();
                if (isValidImportedType(modulePrefix, identifier)) {
                    if (isArrayType) {
                        entity.addDiagnostic(PERSIST_115.getCode(), PERSIST_115.getMessage(), PERSIST_115.getSeverity(),
                                typeNode.location());
                    }
                } else {
                    entity.addDiagnostic(PERSIST_114.getCode(), MessageFormat.format(PERSIST_114.getMessage(),
                                    modulePrefix + ":" + identifier + typeNamePostfix), PERSIST_114.getSeverity(),
                            typeNode.location());
                }
            } else if (processedTypeNode instanceof SimpleNameReferenceNode) {
                String typeName = ((SimpleNameReferenceNode) processedTypeNode).name().text().trim();
                if (this.enums.contains(typeName)) {
                    if (isArrayType) {
                        entity.addDiagnostic(PERSIST_115.getCode(), PERSIST_115.getMessage(), PERSIST_115.getSeverity(),
                                processedTypeNode.location());
                    }
                }
                // todo: Validate relations
            } else {
                //todo: Improve type name in message
                entity.addDiagnostic(PERSIST_114.getCode(), MessageFormat.format(PERSIST_114.getMessage(),
                                processedTypeNode.kind().stringValue() + typeNamePostfix), PERSIST_114.getSeverity(),
                        typeNode.location());
            }
        }
    }

    private boolean isValidSimpleType(String type) {
        switch (type) {
            case INT:
            case BOOLEAN:
            case DECIMAL:
            case FLOAT:
            case STRING:
                return true;
            default:
                return false;
        }
    }

    private boolean isValidImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case DATE:
            case TIME_OF_DAY:
            case UTC:
            case CIVIL:
                return true;
            default:
                return false;
        }
    }

    private void validateIdentifierFieldCount(Entity entity) {
        if (entity.getReadonlyFieldCount() == 0) {
            entity.addDiagnostic(PERSIST_103.getCode(), MessageFormat.format(PERSIST_103.getMessage(),
                            entity.getEntityName()), PERSIST_103.getSeverity(), entity.getEntityNameLocation());
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
