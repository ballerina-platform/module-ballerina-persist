/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.BuiltinSimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.EnumDeclarationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.ImportDeclarationNode;
import io.ballerina.compiler.syntax.tree.ImportOrgNameNode;
import io.ballerina.compiler.syntax.tree.ImportPrefixNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.compiler.syntax.tree.OptionalTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeCastExpressionNode;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.compiler.syntax.tree.UnaryExpressionNode;
import io.ballerina.compiler.syntax.tree.UnionTypeDescriptorNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.persist.compiler.Constants.Annotations;
import io.ballerina.stdlib.persist.compiler.Constants.EntityAnnotation;
import io.ballerina.stdlib.persist.compiler.models.Entity;
import io.ballerina.stdlib.persist.compiler.models.Field;
import io.ballerina.tools.diagnostics.Location;
import org.ballerinalang.model.tree.expressions.ListConstructorExprNode;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;

/**
 * PersistRecordAnalyzer.
 */
public class PersistRecordValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final List<List<String>> uniqueConstraints;
    private final HashMap<String, String> tableNames;
    private final HashMap<String, Entity> entities;
    private boolean isCompilationErrorChecked = false;

    public PersistRecordValidator() {
        this.uniqueConstraints = new ArrayList<>();
        this.tableNames = new HashMap<>();
        this.entities = new HashMap<>();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {

        if (!this.isCompilationErrorChecked) {
            this.isCompilationErrorChecked = true;
            if (Utils.hasCompilationErrors(ctx)) {
                return;
            }
        }

        ModuleId moduleId = ctx.moduleId();
        Module currentModule = ctx.currentPackage().module(moduleId);
        String moduleName = currentModule.moduleName().toString().trim();
        String packageName = ctx.currentPackage().packageName().toString().trim();
        // No need to perform analysis for entities inside clients submodule
        // todo: Remove after https://github.com/ballerina-platform/ballerina-standard-library/issues/3784
        if (moduleName.equals(packageName.concat(".clients"))) {
            return;
        }

        Node node = ctx.node();
        if (node instanceof EnumDeclarationNode) {
            Optional<MetadataNode> metadata = ((EnumDeclarationNode) node).metadata();
            if (metadata.isPresent()) {
                NodeList<AnnotationNode> annotations = metadata.get().annotations();
                if (getEntityAnnotation(annotations).isPresent()) {
                    Utils.reportDiagnostic(ctx, node.location(), DiagnosticsCodes.PERSIST_128.getCode(),
                            DiagnosticsCodes.PERSIST_128.getMessage(), DiagnosticsCodes.PERSIST_128.getSeverity());
                }
            }
            return;
        }

        if (node instanceof TypeCastExpressionNode) {
            NodeList<AnnotationNode> annotations = ((TypeCastExpressionNode) node).typeCastParam().annotations();
            if (getEntityAnnotation(annotations).isPresent()) {
                Utils.reportDiagnostic(ctx, node.location(), DiagnosticsCodes.PERSIST_128.getCode(),
                        DiagnosticsCodes.PERSIST_128.getMessage(), DiagnosticsCodes.PERSIST_128.getSeverity());
            }
            return;
        }

        TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) ctx.node();
        Node typeDescriptorNode = typeDefinitionNode.typeDescriptor();
        if (!(typeDescriptorNode instanceof RecordTypeDescriptorNode)) {
            Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
            if (metadata.isPresent()) {
                if (getEntityAnnotation(metadata.get().annotations()).isPresent()) {
                    Utils.reportDiagnostic(ctx, node.location(), DiagnosticsCodes.PERSIST_128.getCode(),
                            DiagnosticsCodes.PERSIST_128.getMessage(), DiagnosticsCodes.PERSIST_128.getSeverity());
                }
            }
            return;
        }

        Optional<Symbol> symbol = ctx.semanticModel().symbol(typeDefinitionNode);
        if (symbol.isEmpty()) {
            return;
        }
        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) symbol.get();
        RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
        Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
        if (metadata.isPresent()) {
            Optional<AnnotationNode> entityAnnotation = getEntityAnnotation(metadata.get().annotations());
            if (entityAnnotation.isPresent()) {
                String entityName = typeDefinitionNode.typeName().text().trim();
                Entity entity = new Entity(entityName, moduleName, recordTypeSymbol.fieldDescriptors().keySet());
                entity.setEntityNameLocation(typeDefinitionNode.typeName().location());

                // Remove after entities are validated to be in one module
                // todo: Remove after https://github.com/ballerina-platform/ballerina-standard-library/issues/3810
                if (isDuplicateEntity(entity, typeDefinitionNode)) {
                    entity.getDiagnostics().forEach((ctx::reportDiagnostic));
                    // Stop processing duplicated entities
                    return;
                }

                // Can remove this after generated folder design change
                // todo: Remove after https://github.com/ballerina-platform/ballerina-standard-library/issues/3784
                if (typeDefinitionNode.visibilityQualifier().isEmpty()) {
                    entity.addDiagnostic(typeDefinitionNode.location(), DiagnosticsCodes.PERSIST_111.getCode(),
                            DiagnosticsCodes.PERSIST_111.getMessage(), DiagnosticsCodes.PERSIST_111.getSeverity());
                }

                validateRecordProperties(entity, ((RecordTypeDescriptorNode) typeDescriptorNode));

                validateEntityAnnotation(entity, entityAnnotation.get());

                validateEntityFields(entity, ((RecordTypeDescriptorNode) typeDescriptorNode).fields(), currentModule);
                validateAutoIncrementAnnotation(entity);

                validateRecordFieldsAnnotation(entity, ctx, typeDescriptorNode,
                        ((ModulePartNode) ctx.syntaxTree().rootNode()).members());
                validFieldTypeAndRelation((RecordTypeDescriptorNode) typeDescriptorNode, typeDefinitionNode,
                            ctx, symbol.get());
                entity.getDiagnostics().forEach((ctx::reportDiagnostic));
                this.entities.put(entity.getEntityName(), entity);
            } else {
                checkForFieldAnnotations(ctx, (RecordTypeDescriptorNode) typeDescriptorNode);
            }
        } else {
            checkForFieldAnnotations(ctx, (RecordTypeDescriptorNode) typeDescriptorNode);
        }

        this.uniqueConstraints.clear();
    }

    private Optional<AnnotationNode> getEntityAnnotation(NodeList<AnnotationNode> annotations) {
        for (AnnotationNode annotation : annotations) {
            if (annotation.annotReference().toSourceCode().trim().equals(Annotations.ENTITY)) {
                return Optional.of(annotation);
            }
        }
        return Optional.empty();
    }

    private boolean isDuplicateEntity(Entity entity, TypeDefinitionNode typeDefinitionNode) {
        if (this.entities.containsKey(entity.getEntityName())) {
            String initialModule = this.entities.get(entity.getEntityName()).getModule();
            entity.addDiagnostic(typeDefinitionNode.typeName().location(), DiagnosticsCodes.PERSIST_119.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_119.getMessage(), initialModule),
                    DiagnosticsCodes.PERSIST_119.getSeverity());
            return true;
        }
        return false;
    }

    private void validateRecordProperties(Entity entity, RecordTypeDescriptorNode recordTypeDescriptorNode) {
        // Check whether the entity is a closed record
        if (recordTypeDescriptorNode.bodyStartDelimiter().kind() != SyntaxKind.OPEN_BRACE_PIPE_TOKEN) {
            String recordName = entity.getEntityName();
            entity.addDiagnostic(recordTypeDescriptorNode.location(), DiagnosticsCodes.PERSIST_124.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_124.getMessage(), recordName),
                    DiagnosticsCodes.PERSIST_124.getSeverity());
        }
        // Check whether the entity has rest field initialization
        if (recordTypeDescriptorNode.recordRestDescriptor().isPresent()) {
            entity.addDiagnostic(recordTypeDescriptorNode.location(), DiagnosticsCodes.PERSIST_130.getCode(),
                    DiagnosticsCodes.PERSIST_130.getMessage(), DiagnosticsCodes.PERSIST_130.getSeverity());
        }
    }

    private void validateEntityAnnotation(Entity entity, AnnotationNode annotationNode) {
        Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                annotationNode.annotValue();
        if (mappingConstructorExpressionNode.isPresent()) {
            SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().fields();
            boolean isKeyFieldFound = false;
            for (MappingFieldNode fieldNode : fields) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) fieldNode;
                // If field is given as token( key: ) or string ("key": )
                String fieldName = getAnnotationFieldName(specificFieldNode);

                @SuppressWarnings("OptionalGetWithoutIsPresent")
                ExpressionNode specificFieldValue = specificFieldNode.valueExpr().get();
                switch (fieldName) {
                    case EntityAnnotation.KEY:
                        validateEntityKeyField(entity, specificFieldValue);
                        break;
                    case EntityAnnotation.UNIQUE_CONSTRAINTS:
                        validateUniqueConstraintField(entity, specificFieldValue);
                        break;
                    case EntityAnnotation.TABLE_NAME:
                        //todo: Remove with V2
                        isKeyFieldFound = true;
                        if (specificFieldValue instanceof BasicLiteralNode) {
                            String tableName = Utils.eliminateDoubleQuotes(
                                    ((BasicLiteralNode) specificFieldValue).literalToken().text().trim());
                            entity.setTableName(tableName);
                            entity.setTableNameExpressionLocation(specificFieldValue.location());
                        } else {
                            entity.addDiagnostic(specificFieldValue.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                                    MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                            EntityAnnotation.TABLE_NAME), DiagnosticsCodes.PERSIST_127.getSeverity());
                        }
                        break;
                    default:
                        // Unreachable code as type descriptor is a closed record.
                        throw new RuntimeException("Unsupported @persist:Entity annotation field, " + fieldName);
                }

            }
            if (!isKeyFieldFound) {
                entity.setTableName(entity.getEntityName());
                entity.setTableNameExpressionLocation(entity.getEntityNameLocation());
            }
        }
        if (entity.getTableName() != null) {
            validateTableName(entity, entity.getTableNameExpressionLocation());
        }
    }

    private String getAnnotationFieldName(SpecificFieldNode specificFieldNode) {
        String fieldName;
        if (specificFieldNode.fieldName() instanceof IdentifierToken) {
            fieldName = ((IdentifierToken) specificFieldNode.fieldName()).text().trim();
        } else {
            fieldName = Utils.eliminateDoubleQuotes(
                    ((BasicLiteralNode) specificFieldNode.fieldName()).literalToken().text().trim());
        }
        return fieldName;
    }

    private void validateEntityKeyField(Entity entity, ExpressionNode specificFieldValue) {
        if (specificFieldValue instanceof ListConstructorExpressionNode) {
            ListConstructorExpressionNode listConstructorExpressionNode =
                    (ListConstructorExpressionNode) specificFieldValue;
            SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();

            if (expressions.isEmpty()) {
                entity.addDiagnostic(listConstructorExpressionNode.location(),
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(), EntityAnnotation.KEY),
                        DiagnosticsCodes.PERSIST_123.getSeverity());
                return;
            }
            for (Node expression : expressions) {
                if (expression instanceof BasicLiteralNode) {
                    String key = Utils.eliminateDoubleQuotes(
                            ((BasicLiteralNode) expression).literalToken().text().trim());
                    // todo: Add testcase to see if the validation continues after empty value
                    if (key.isEmpty()) {
                        entity.addDiagnostic(expression.location(),
                                DiagnosticsCodes.PERSIST_123.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(), EntityAnnotation.KEY),
                                DiagnosticsCodes.PERSIST_123.getSeverity());
                        continue;
                    }
                    if (!entity.primaryKeysContains(key)) {
                        entity.addPrimaryKey(key, expression.location());
                    } else {
                        entity.addDiagnostic(expression.location(),
                                DiagnosticsCodes.PERSIST_131.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_131.getMessage(),
                                        EntityAnnotation.KEY), DiagnosticsCodes.PERSIST_131.getSeverity());
                    }
                } else {
                    entity.addDiagnostic(expression.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(), EntityAnnotation.KEY),
                            DiagnosticsCodes.PERSIST_127.getSeverity());
                }
            }
            entity.getPrimaryKeys().forEach((key, location) -> validateConstraintFieldNames(entity, key, location));
        } else {
            entity.addDiagnostic(specificFieldValue.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(), EntityAnnotation.KEY),
                    DiagnosticsCodes.PERSIST_127.getSeverity());
        }
    }

    private void validateUniqueConstraintField(Entity entity, ExpressionNode specificFieldValue) {
        if (specificFieldValue instanceof ListConstructorExpressionNode) {
            ListConstructorExpressionNode listConstructorExpressionNode =
                    (ListConstructorExpressionNode) specificFieldValue;
            SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
            if (expressions.isEmpty()) {
                entity.addDiagnostic(listConstructorExpressionNode.location(),
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(),
                                EntityAnnotation.UNIQUE_CONSTRAINTS), DiagnosticsCodes.PERSIST_123.getSeverity());
                return;
            }
            for (Node expression : expressions) {
                if (expression instanceof ListConstructorExpressionNode) {
                    SeparatedNodeList<Node> uniqueConstraintNodes =
                            ((ListConstructorExpressionNode) expression).expressions();
                    HashMap<String, NodeLocation> uniqueConstraints = new HashMap<>();
                    if (uniqueConstraintNodes.isEmpty()) {
                        entity.addDiagnostic(expression.location(),
                                DiagnosticsCodes.PERSIST_123.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(),
                                        EntityAnnotation.UNIQUE_CONSTRAINTS),
                                DiagnosticsCodes.PERSIST_123.getSeverity());
                        continue;
                    }
                    for (Node constraintNode : uniqueConstraintNodes) {
                        if (constraintNode instanceof BasicLiteralNode) {
                            String key = Utils.eliminateDoubleQuotes(
                                    ((BasicLiteralNode) constraintNode).literalToken().text().trim());
                            if (key.isEmpty()) {
                                entity.addDiagnostic(constraintNode.location(),
                                        DiagnosticsCodes.PERSIST_123.getCode(),
                                        MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(),
                                                EntityAnnotation.UNIQUE_CONSTRAINTS),
                                        DiagnosticsCodes.PERSIST_123.getSeverity());
                                continue;
                            }
                            if (!uniqueConstraints.containsKey(key)) {
                                uniqueConstraints.put(key, expression.location());
                            } else {
                                entity.addDiagnostic(constraintNode.location(),
                                        DiagnosticsCodes.PERSIST_131.getCode(),
                                        MessageFormat.format(DiagnosticsCodes.PERSIST_131.getMessage(),
                                                EntityAnnotation.UNIQUE_CONSTRAINTS),
                                        DiagnosticsCodes.PERSIST_131.getSeverity());
                            }
                        } else {
                            entity.addDiagnostic(constraintNode.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                                    MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                            EntityAnnotation.UNIQUE_CONSTRAINTS),
                                    DiagnosticsCodes.PERSIST_127.getSeverity());
                        }
                    }
                    uniqueConstraints.forEach((key, location) -> validateConstraintFieldNames(entity, key, location));
                    entity.addUniqueConstraints(uniqueConstraints);
                    // todo: Remove once relations processed
                    this.uniqueConstraints.add(new ArrayList<>(uniqueConstraints.keySet()));
                    uniqueConstraints.clear();
                } else {
                    entity.addDiagnostic(expression.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                    EntityAnnotation.UNIQUE_CONSTRAINTS), DiagnosticsCodes.PERSIST_127.getSeverity());
                }
            }
        } else {
            entity.addDiagnostic(specificFieldValue.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                            EntityAnnotation.UNIQUE_CONSTRAINTS), DiagnosticsCodes.PERSIST_127.getSeverity());
        }
    }

    private void validateTableName(Entity entity, NodeLocation location) {
        if (this.tableNames.containsKey(entity.getTableName())) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_113.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_113.getMessage(),
                            this.tableNames.get(entity.getTableName())),
                    DiagnosticsCodes.PERSIST_113.getSeverity());
        } else {
            this.tableNames.put(entity.getTableName(), entity.getModule());
        }
    }

    private void validateEntityFields(Entity entity, NodeList<Node> fields, Module currentModule) {
        for (Node fieldNode : fields) {
            Field field;
            Node typeNode;
            if (fieldNode instanceof RecordFieldNode) {
                RecordFieldNode recordFieldNode = (RecordFieldNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                String fieldName = recordFieldNode.fieldName().text().trim();
                typeNode = recordFieldNode.typeName();
                field = getField(fieldName, metadataNode);
                field.setReadOnly(recordFieldNode.readonlyKeyword().isPresent());
                if (recordFieldNode.questionMarkToken().isPresent()) {
                    field.setOptional(true);
                }
            } else if (fieldNode instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                String fieldName = recordFieldNode.fieldName().text().trim();
                typeNode = recordFieldNode.typeName();
                field = getField(fieldName, metadataNode);
                field.setReadOnly(recordFieldNode.readonlyKeyword().isPresent());
            } else {
                // Inherited Field
                entity.addDiagnostic(fieldNode.location(), DiagnosticsCodes.PERSIST_129.getCode(),
                        DiagnosticsCodes.PERSIST_129.getMessage(), DiagnosticsCodes.PERSIST_129.getSeverity());
                continue;
            }
            field.setType(typeNode);
            field.setTypeLocation(typeNode.location());

            boolean isArrayType = false;
            if (typeNode instanceof OptionalTypeDescriptorNode) {
                typeNode = ((OptionalTypeDescriptorNode) typeNode).typeDescriptor();
            }
            if (typeNode instanceof ArrayTypeDescriptorNode) {
                isArrayType = true;
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) typeNode);
                typeNode = arrayTypeDescriptorNode.memberTypeDesc();
            }

            if (typeNode instanceof BuiltinSimpleNameReferenceNode) {
                if (isArrayType) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_120.getCode(),
                            DiagnosticsCodes.PERSIST_120.getMessage(), DiagnosticsCodes.PERSIST_120.getSeverity());
                    continue;
                }
                String type = ((BuiltinSimpleNameReferenceNode) typeNode).name().text();
                if (!isValidSimpleType(type)) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), type),
                            DiagnosticsCodes.PERSIST_121.getSeverity());
                    continue;
                } else if (field.isOptional()) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_104.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_104.getMessage(), field.getFieldName()),
                            DiagnosticsCodes.PERSIST_104.getSeverity());
                    continue;
                }
            } else if (typeNode instanceof QualifiedNameReferenceNode) {
                // Support only time constructs
                // Removed support to imported Entities, as these will  be redundant in V2
                String qualifiedType = typeNode.toSourceCode().trim();
                if (!isValidImportedType(qualifiedType)) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), qualifiedType),
                            DiagnosticsCodes.PERSIST_121.getSeverity());
                    continue;
                } else if (field.isOptional()) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_104.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_104.getMessage(), field.getFieldName()),
                            DiagnosticsCodes.PERSIST_104.getSeverity());
                    continue;
                }
            } else if (typeNode instanceof SimpleNameReferenceNode) {
                // Verify these are fields annotated with @Relation
                String attachedEntity = ((SimpleNameReferenceNode) typeNode).name().text();
                if (field.getRelationAnnotation() != null) {
                    if (this.entities.containsKey(field.getFieldName())) {
                        field.setRelationAttachedToValidEntity(true);
                    } else {
                        // Have to check all entities present in this module
                        validateAttachmentType(entity, field, attachedEntity, typeNode.location(),
                                currentModule);
                    }
                } else {
                    TypeDefinitionNode typeDefinitionNode = getAttachmentEntity(attachedEntity, currentModule);
                    if (typeDefinitionNode != null &&
                            !hasAttachedEntityFieldRelationAnnotation(typeDefinitionNode, entity.getEntityName())) {
                        entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_133.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_133.getMessage(), field.getFieldName()),
                                DiagnosticsCodes.PERSIST_133.getSeverity());
                        continue;
                    }
                }
            } else if (typeNode instanceof UnionTypeDescriptorNode) {
                // All other types are invalid.
                entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_101.getCode(),
                        DiagnosticsCodes.PERSIST_101.getMessage(),
                        DiagnosticsCodes.PERSIST_101.getSeverity());
                continue;
            } else if (typeNode instanceof RecordTypeDescriptorNode) {
                entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), "in-line record"),
                        DiagnosticsCodes.PERSIST_121.getSeverity());
                continue;
            } else {
                entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), typeNode.kind().name()),
                        DiagnosticsCodes.PERSIST_121.getSeverity());
                continue;
            }
            entity.addField(field);
        }
    }

    private void validateAttachmentType(Entity entity, Field field, String referencedRecordName,
                                        NodeLocation location, Module currentModule) {
        TypeDefinitionNode typeDefinitionNode = getAttachmentEntity(referencedRecordName, currentModule);
        if (typeDefinitionNode == null) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_115.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_115.getMessage(), referencedRecordName),
                    DiagnosticsCodes.PERSIST_115.getSeverity());
            field.setRelationAttachedToValidEntity(false);
        } else {
            Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
            if (metadata.isEmpty()) {
                entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_132.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_132.getMessage(), referencedRecordName),
                        DiagnosticsCodes.PERSIST_132.getSeverity());
                field.setRelationAttachedToValidEntity(false);
            } else {
                if (getEntityAnnotation(metadata.get().annotations()).isEmpty()) {
                    entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_132.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_132.getMessage(), referencedRecordName),
                            DiagnosticsCodes.PERSIST_132.getSeverity());
                    field.setRelationAttachedToValidEntity(false);
                } else {
                    field.setRelationAttachedToValidEntity(true);
                }
            }
        }
    }

    private TypeDefinitionNode getAttachmentEntity(String referencedRecordName, Module currentModule) {
        for (DocumentId documentId : currentModule.documentIds()) {
            Document document = currentModule.document(documentId);
            NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) document.syntaxTree().rootNode()).
                    members();
            for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                if (!(memberNode instanceof TypeDefinitionNode)) {
                    continue;
                }
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (!(typeDescriptor instanceof RecordTypeDescriptorNode)) {
                    continue;
                }
                if (typeDefinitionNode.typeName().text().equals(referencedRecordName)) {
                    return typeDefinitionNode;
                }
            }
        }
        return null;
    }

    private boolean hasAttachedEntityFieldRelationAnnotation(TypeDefinitionNode typeDefinitionNode,
                                                             String entityName) {
        for (Node fieldNode : ((RecordTypeDescriptorNode) typeDefinitionNode.typeDescriptor()).fields()) {
            Node typeNode;
            Field field;
            if (fieldNode instanceof RecordFieldNode) {
                RecordFieldNode recordFieldNode = (RecordFieldNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                field = getField(recordFieldNode.fieldName().text().trim(), metadataNode);
                typeNode = recordFieldNode.typeName();
            } else {
                RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                field = getField(recordFieldNode.fieldName().text().trim(), metadataNode);
                typeNode = recordFieldNode.typeName();
            }
            if (typeNode instanceof OptionalTypeDescriptorNode) {
                typeNode = ((OptionalTypeDescriptorNode) typeNode).typeDescriptor();
            }
            if (typeNode instanceof ArrayTypeDescriptorNode) {
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) typeNode);
                typeNode = arrayTypeDescriptorNode.memberTypeDesc();
            }
            if (typeNode instanceof SimpleNameReferenceNode) {
                if (((SimpleNameReferenceNode) typeNode).name().text().trim().equals(entityName)) {
                    if (field.getRelationAnnotation() != null) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private Field getField(String fieldName, Optional<MetadataNode> metadataNode) {
        AnnotationNode autoIncrementNode = null;
        AnnotationNode relationNode = null;
        if (metadataNode.isPresent()) {
            NodeList<AnnotationNode> annotations = metadataNode.get().annotations();
            for (AnnotationNode annotation : annotations) {
                String annotationName = annotation.annotReference().toSourceCode().trim();
                if (annotationName.equals(Annotations.AUTO_INCREMENT)) {
                    autoIncrementNode = annotation;
                } else if (annotationName.equals(Annotations.RELATION)) {
                    relationNode = annotation;
                }
            }
        }
        return new Field(fieldName, autoIncrementNode, relationNode);
    }

    private void validateAutoIncrementAnnotation(Entity entity) {
        for (Field validEntityField : entity.getValidEntityFields()) {
            AnnotationNode autoIncrement = validEntityField.getAutoIncrement();
            if (autoIncrement == null) {
                continue;
            }
            // todo verify if we need multiple autoincrement check
            if (!entity.getPrimaryKeys().isEmpty() &&
                    entity.getPrimaryKeys().containsKey(validEntityField.getFieldName())) {
                if (!validEntityField.isReadOnly()) {
                    entity.addDiagnostic(validEntityField.getTypeLocation(), DiagnosticsCodes.PERSIST_106.getCode(),
                            DiagnosticsCodes.PERSIST_106.getMessage(), DiagnosticsCodes.PERSIST_106.getSeverity());
                }
                Node fieldType = validEntityField.getType();
                if (!(fieldType instanceof BuiltinSimpleNameReferenceNode)) {
                    entity.addDiagnostic(fieldType.location(), DiagnosticsCodes.PERSIST_105.getCode(),
                            DiagnosticsCodes.PERSIST_105.getMessage(),
                            DiagnosticsCodes.PERSIST_105.getSeverity());
                } else if (!((BuiltinSimpleNameReferenceNode) fieldType).name().text()
                        .equals(Constants.BallerinaTypes.INT)) {
                    entity.addDiagnostic(fieldType.location(), DiagnosticsCodes.PERSIST_105.getCode(),
                            DiagnosticsCodes.PERSIST_105.getMessage(),
                            DiagnosticsCodes.PERSIST_105.getSeverity());
                }
            } else {
                entity.addDiagnostic(autoIncrement.location(), DiagnosticsCodes.PERSIST_108.getCode(),
                        DiagnosticsCodes.PERSIST_108.getMessage(), DiagnosticsCodes.PERSIST_108.getSeverity());
            }
            if (autoIncrement.annotValue().isPresent()) {
                SeparatedNodeList<MappingFieldNode> fields = autoIncrement.annotValue().get().fields();
                for (MappingFieldNode fieldNode : fields) {
                    SpecificFieldNode specificFieldNode = (SpecificFieldNode) fieldNode;
                    // If field is given as token( key: ) or string ("key": )
                    String fieldName = getAnnotationFieldName(specificFieldNode);

                    @SuppressWarnings("OptionalGetWithoutIsPresent")
                    ExpressionNode specificFieldValue = specificFieldNode.valueExpr().get();
                    if ((!(specificFieldValue instanceof BasicLiteralNode) &&
                            !(specificFieldValue instanceof UnaryExpressionNode))) {
                        entity.addDiagnostic(specificFieldValue.location(),
                                DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                        specificFieldNode.fieldName()), DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                    if (fieldName.equals(Constants.INCREMENT)) {
                        if (specificFieldValue instanceof UnaryExpressionNode) {
                            entity.addDiagnostic(specificFieldValue.location(),
                                    DiagnosticsCodes.PERSIST_103.getCode(),
                                    DiagnosticsCodes.PERSIST_103.getMessage(),
                                    DiagnosticsCodes.PERSIST_103.getSeverity());
                        } else {
                            if (!specificFieldNode.toSourceCode().trim().equals(Constants.ONE)) {
                                entity.addDiagnostic(specificFieldNode.location(),
                                        DiagnosticsCodes.PERSIST_112.getCode(),
                                        DiagnosticsCodes.PERSIST_112.getMessage(),
                                        DiagnosticsCodes.PERSIST_112.getSeverity());
                            }
                        }
                    }
                }
            }
        }
    }

    private void validateRecordFieldsAnnotation(Entity entity, SyntaxNodeAnalysisContext ctx, Node recordNode,
                                                NodeList<ModuleMemberDeclarationNode> memberNodes) {
        RecordTypeDescriptorNode recordTypeDescriptorNode = (RecordTypeDescriptorNode) recordNode;
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotationFields(ctx, node,
                        fieldNode.typeName().toSourceCode().trim(), memberNodes));
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateAnnotationFields(ctx, node,
                        fieldNode.typeName().toSourceCode().trim(), memberNodes));
            }
        }
    }

    private void checkForFieldAnnotations(SyntaxNodeAnalysisContext ctx,
                                          RecordTypeDescriptorNode recordTypeDescriptorNode) {
        NodeList<Node> fields = recordTypeDescriptorNode.fields();
        for (Node field : fields) {
            if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateFieldAnnotation(ctx, node));
            } else if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                Optional<MetadataNode> metadataNode = fieldNode.metadata();
                metadataNode.ifPresent(node -> validateFieldAnnotation(ctx, node));
            }
        }
    }

    private void validateFieldAnnotation(SyntaxNodeAnalysisContext ctx, MetadataNode metadataNode) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            String annotationName = annotation.annotReference().toSourceCode().trim();
            if (annotationName.equals(Annotations.AUTO_INCREMENT)) {
                Utils.reportDiagnostic(ctx, annotation.location(), DiagnosticsCodes.PERSIST_126.getCode(),
                        DiagnosticsCodes.PERSIST_126.getMessage(), DiagnosticsCodes.PERSIST_126.getSeverity());
            } else if (annotation.annotReference().toSourceCode().trim().equals(Annotations.RELATION)) {
                Utils.reportDiagnostic(ctx, annotation.location(), DiagnosticsCodes.PERSIST_125.getCode(),
                        DiagnosticsCodes.PERSIST_125.getMessage(), DiagnosticsCodes.PERSIST_125.getSeverity());
            }
        }
    }

    private void validateAnnotationFields(SyntaxNodeAnalysisContext ctx, MetadataNode metadataNode,
                                          String fieldType, NodeList<ModuleMemberDeclarationNode> memberNodes) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode = annotation.annotValue();
            if (annotation.annotReference().toSourceCode().trim().equals(Annotations.RELATION)) {
                if (mappingConstructorExpressionNode.isPresent()) {
                    SeparatedNodeList<MappingFieldNode> annotationFields =
                            mappingConstructorExpressionNode.get().fields();
                    validateRelationAnnotation(ctx, annotationFields, memberNodes, fieldType);
                }
            }
        }
    }

    private void validateConstraintFieldNames(Entity entity, String value, NodeLocation location) {
        if (!entity.getEntityFieldNames().contains(value)) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_102.getCode(),
                    DiagnosticsCodes.PERSIST_102.getMessage(), DiagnosticsCodes.PERSIST_102.getSeverity());
        }
    }

    private void validateRelationAnnotation(SyntaxNodeAnalysisContext ctx,
                                            SeparatedNodeList<MappingFieldNode> annotationFields,
                                            NodeList<ModuleMemberDeclarationNode> memberNodes, String filedType) {
        int noOfForeignKeys = 0;
        int noOfReferences = 0;
        Location location = null;
        for (MappingFieldNode annotationField : annotationFields) {
            SpecificFieldNode annotationFieldNode = (SpecificFieldNode) annotationField;
            String key = annotationFieldNode.fieldName().toSourceCode().trim().replaceAll(
                    Constants.UNNECESSARY_CHARS_REGEX, "");
            if (key.equals(Constants.KEY_COLUMNS) || key.equals(Constants.REFERENCE)) {
                Optional<ExpressionNode> expressionNode = annotationFieldNode.valueExpr();
                if (expressionNode.isPresent()) {
                    ExpressionNode valueNode = expressionNode.get();
                    if (valueNode instanceof ListConstructorExpressionNode) {
                        ListConstructorExpressionNode listConstructorExpressionNode =
                                (ListConstructorExpressionNode) valueNode;
                        SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                        if (key.equals(Constants.KEY_COLUMNS)) {
                            noOfForeignKeys = expressions.size();
                            location = valueNode.location();
                        } else {
                            for (Node expression : expressions) {
                                noOfReferences = expressions.size();
                                location = valueNode.location();
                                validateRelationAnnotationReference(ctx, memberNodes, filedType,
                                        ((BasicLiteralNode) expression).literalToken().text().trim(), valueNode);
                            }
                        }
                    } else {
                        Utils.reportDiagnostic(ctx, annotationField.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(), key),
                                DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                }
            } else if (key.equals(Constants.ON_DELETE) || key.equals(Constants.ON_UPDATE)) {
                Optional<ExpressionNode> expressionNode = annotationFieldNode.valueExpr();
                if (expressionNode.isPresent()) {
                    ExpressionNode valueNode = expressionNode.get();
                    if (!(valueNode instanceof QualifiedNameReferenceNode) &&
                            !(valueNode instanceof BasicLiteralNode)) {
                        Utils.reportDiagnostic(ctx, annotationField.location(), DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(), key),
                                DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                }
            }
        }
        // todo If foreign keys or references have one value and one of these is missing in the config,
        //  the missing key has to be inferred from that entity.
        // todo if foreign keys and references miss, both keys have to be inferred from those entity.
        if ((noOfForeignKeys > 1 || noOfReferences > 1) && (noOfForeignKeys != noOfReferences)) {
            Utils.reportDiagnostic(ctx, location, DiagnosticsCodes.PERSIST_109.getCode(),
                    DiagnosticsCodes.PERSIST_109.getMessage(),
                    DiagnosticsCodes.PERSIST_109.getSeverity());
        }
    }

    private void validateRelationAnnotationReference(SyntaxNodeAnalysisContext ctx,
                                                     NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                     String filedType, String value, ExpressionNode valueNode) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                Optional<Symbol> symbol = ctx.semanticModel().symbol(memberNode);
                if (symbol.isPresent()) {
                    Symbol memberNodeSymbol = symbol.get();
                    Optional<String> name = memberNodeSymbol.getName();
                    if (name.isPresent() && name.get().trim().equals(filedType)) {
                        TypeDefinitionSymbol typeDefinitionSymbol = (TypeDefinitionSymbol) memberNodeSymbol;
                        RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDefinitionSymbol.typeDescriptor();
                        if (!recordTypeSymbol.fieldDescriptors().containsKey(value.substring(1, value.length() - 1))) {
                            Utils.reportDiagnostic(ctx, valueNode.location(),
                                    DiagnosticsCodes.PERSIST_102.getCode(), DiagnosticsCodes.PERSIST_102.getMessage(),
                                    DiagnosticsCodes.PERSIST_102.getSeverity());
                        }
                    }
                }
            }
        }
    }

    private void validFieldTypeAndRelation(RecordTypeDescriptorNode recordNode,
                                           TypeDefinitionNode typeDefinitionNode,
                                           SyntaxNodeAnalysisContext ctx, Symbol symbol) {
        String recordName = typeDefinitionNode.typeName().text();
        NodeList<Node> fields = recordNode.fields();
        String type;
        Node typeNode;
        Optional<MetadataNode> metadata;
        TypeDefinitionNode referenceRecord = null;
        for (Node field : fields) {
            String tableAssociationType = "";
            boolean isArrayType = false;
            boolean isUserDefinedType = false;
            String hasRelationAnnotation = Constants.FALSE;
            if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                typeNode = fieldNode.typeName();
                metadata = fieldNode.metadata();
            } else if (field instanceof RecordFieldNode) {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                typeNode = fieldNode.typeName();
                metadata = fieldNode.metadata();
            } else {
                continue;
            }
            if (typeNode instanceof OptionalTypeDescriptorNode) {
                typeNode = ((OptionalTypeDescriptorNode) typeNode).typeDescriptor();
            }
            if (typeNode instanceof ArrayTypeDescriptorNode) {
                isArrayType = true;
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) typeNode);
                typeNode = arrayTypeDescriptorNode.memberTypeDesc();
            }
            if (typeNode instanceof QualifiedNameReferenceNode) {
                QualifiedNameReferenceNode qualifiedNameReferenceNode = (QualifiedNameReferenceNode) typeNode;
                type = qualifiedNameReferenceNode.identifier().text();
                String nodeType = qualifiedNameReferenceNode.modulePrefix().text().trim();
                if (!nodeType.isEmpty()) {
                    NodeList<ImportDeclarationNode> imports = ((ModulePartNode) ctx.syntaxTree().rootNode()).imports();
                    for (int i = 0; i < imports.size(); i++) {
                        ImportDeclarationNode importDeclarationNode = imports.get(i);
                        SeparatedNodeList<IdentifierToken> moduleNames = importDeclarationNode.moduleName();
                        if (isNodeType(importDeclarationNode, nodeType, moduleNames)) {
                            if (hasValidModuleName(moduleNames, symbol) &&
                                    hasValidOrgName(importDeclarationNode, symbol)) {
                                isUserDefinedType = true;
                                Object[] properties = checkRelationShip(recordName, type, ctx);
                                if (isArrayType && properties.length == 5) {
                                    Utils.reportDiagnostic(ctx, field.location(),
                                            DiagnosticsCodes.PERSIST_115.getCode(),
                                            MessageFormat.format(DiagnosticsCodes.PERSIST_115.getMessage(), type),
                                            DiagnosticsCodes.PERSIST_115.getSeverity());
                                } else {
                                    tableAssociationType = properties[1].toString();
                                    hasRelationAnnotation = properties[2].toString();
                                    referenceRecord = (TypeDefinitionNode) properties[3];
                                    if (isArrayType) {
                                        if (!tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                                            Utils.reportDiagnostic(ctx, field.location(),
                                                    DiagnosticsCodes.PERSIST_114.getCode(),
                                                    DiagnosticsCodes.PERSIST_114.getMessage(),
                                                    DiagnosticsCodes.PERSIST_114.getSeverity());
                                        }
                                    }
                                    break;
                                }
                            } else {
                                if (isArrayType) {
                                    Utils.reportDiagnostic(ctx, typeNode.location(),
                                            DiagnosticsCodes.PERSIST_120.getCode(),
                                            DiagnosticsCodes.PERSIST_120.getMessage(),
                                            DiagnosticsCodes.PERSIST_120.getSeverity());
                                }
                                validateType(ctx, typeNode, qualifiedNameReferenceNode.toString().trim());
                                break;
                            }
                        }
                    }
                } else {
                    validateType(ctx, typeNode, type);
                }
            } else if (typeNode instanceof SimpleNameReferenceNode) {
                isUserDefinedType = true;
                type = ((SimpleNameReferenceNode) typeNode).name().text();
                Object[] properties = checkRelationShip(recordName, type, ctx);
                if (isArrayType && properties.length == 5) {
                    Utils.reportDiagnostic(ctx, field.location(),
                            DiagnosticsCodes.PERSIST_115.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_115.getMessage(), type),
                            DiagnosticsCodes.PERSIST_115.getSeverity());
                }
                tableAssociationType = properties[1].toString();
                hasRelationAnnotation = properties[2].toString();
                referenceRecord = (TypeDefinitionNode) properties[3];
                if (isArrayType) {
                    if (!tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                        Utils.reportDiagnostic(ctx, field.location(),
                                DiagnosticsCodes.PERSIST_114.getCode(),
                                DiagnosticsCodes.PERSIST_114.getMessage(),
                                DiagnosticsCodes.PERSIST_114.getSeverity());
                    }
                }
            } else if (typeNode instanceof RecordTypeDescriptorNode) {
                Utils.reportDiagnostic(ctx, typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), "in-line record"),
                        DiagnosticsCodes.PERSIST_121.getSeverity());
            } else {
                if (isArrayType) {
                    Utils.reportDiagnostic(ctx, typeNode.location(), DiagnosticsCodes.PERSIST_120.getCode(),
                            DiagnosticsCodes.PERSIST_120.getMessage(), DiagnosticsCodes.PERSIST_120.getSeverity());
                }
                // todo: Temporary check before refactoring
                if (typeNode instanceof BuiltinSimpleNameReferenceNode) {
                    validateType(ctx, typeNode, ((BuiltinSimpleNameReferenceNode) typeNode).name().text());
                }
            }
            if (metadata.isPresent()) {
                for (AnnotationNode annotationNode : metadata.get().annotations()) {
                    String annotationName = annotationNode.annotReference().toSourceCode().trim();
                    if (annotationName.equals(Annotations.RELATION)) {
                        if (hasRelationAnnotation.equals(Constants.TRUE)) {
                            Utils.reportDiagnostic(ctx, annotationNode.location(),
                                    DiagnosticsCodes.PERSIST_116.getCode(), DiagnosticsCodes.PERSIST_116.getMessage(),
                                    DiagnosticsCodes.PERSIST_116.getSeverity());
                        }
                        if (isArrayType) {
                            if (tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                                Utils.reportDiagnostic(ctx, annotationNode.location(),
                                        DiagnosticsCodes.PERSIST_118.getCode(),
                                        DiagnosticsCodes.PERSIST_118.getMessage(),
                                        DiagnosticsCodes.PERSIST_118.getSeverity());
                            } else if (!isUserDefinedType) {
                                Utils.reportDiagnostic(ctx, annotationNode.location(),
                                        DiagnosticsCodes.PERSIST_117.getCode(),
                                        DiagnosticsCodes.PERSIST_117.getMessage(),
                                        DiagnosticsCodes.PERSIST_117.getSeverity());
                            }
                        } else if (!isUserDefinedType) {
                            Utils.reportDiagnostic(ctx, annotationNode.location(),
                                    DiagnosticsCodes.PERSIST_117.getCode(),
                                    DiagnosticsCodes.PERSIST_117.getMessage(),
                                    DiagnosticsCodes.PERSIST_117.getSeverity());
                        } else {
                            processRelationAnnotation(ctx, annotationNode, referenceRecord);
                        }
                    }
                }
            }
        }
    }

    private boolean hasValidOrgName(ImportDeclarationNode importDeclarationNode, Symbol symbol) {
        Optional<ModuleSymbol> module = symbol.getModule();
        if (module.isPresent()) {
            Optional<ImportOrgNameNode> orgName = importDeclarationNode.orgName();
            return importDeclarationNode.orgName().isEmpty() || (orgName.isPresent() && module.get().id().orgName().
                    trim().equals(orgName.get().orgName().text().trim()));
        }
        return false;
    }

    private boolean hasValidModuleName(SeparatedNodeList<IdentifierToken> moduleNames, Symbol symbol) {
        Optional<ModuleSymbol> module = symbol.getModule();
        if (module.isPresent()) {
            Optional<String> moduleName = module.get().getName();
            return moduleName.isEmpty() || moduleName.get().trim().startsWith(moduleNames.get(0).text().trim());
        }
        return false;
    }

    private boolean isNodeType(ImportDeclarationNode importDeclarationNode, String nodeType,
                               SeparatedNodeList<IdentifierToken> moduleNames) {
        Optional<ImportPrefixNode> prefixNode = importDeclarationNode.prefix();
        return moduleNames.get(moduleNames.size() - 1).toString().trim().equals(nodeType) ||
                ((prefixNode.isPresent() && prefixNode.get().prefix().text().trim().
                        equals(nodeType)));
    }

    private Object[] checkRelationShip(String recordName, String referenceRecordName,
                                       SyntaxNodeAnalysisContext ctx) {
        TypeDefinitionNode referenceRecord = null;
        for (Module module : ctx.currentPackage().modules()) {
            for (DocumentId documentId : module.documentIds()) {
                Document document = module.document(documentId);
                NodeList<ModuleMemberDeclarationNode> memberNodes = ((ModulePartNode) document.syntaxTree().rootNode()).
                        members();
                for (ModuleMemberDeclarationNode memberNode : memberNodes) {
                    if (!(memberNode instanceof TypeDefinitionNode)) {
                        continue;
                    }
                    TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                    Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                    if (!(typeDescriptor instanceof RecordTypeDescriptorNode)) {
                        continue;
                    }
                    RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
                    if (!typeDefinitionNode.typeName().text().equals(referenceRecordName)) {
                        continue;
                    }
                    referenceRecord = typeDefinitionNode;
                    Optional<MetadataNode> entityMetadata = typeDefinitionNode.metadata();
                    if (entityMetadata.isPresent()) {
                        NodeList<AnnotationNode> annotations = entityMetadata.get().annotations();
                        for (AnnotationNode annotation : annotations) {
                            if (!annotation.annotReference().toSourceCode().trim()
                                    .equals(Annotations.ENTITY)) {
                                continue;
                            }
                            Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                                    annotation.annotValue();
                            if (mappingConstructorExpressionNode.isPresent()) {
                                SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().
                                        fields();
                                for (MappingFieldNode mappingFieldNode : fields) {
                                    SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                                    String name = fieldNode.fieldName().toSourceCode().trim().
                                            replaceAll(Constants.UNNECESSARY_CHARS_REGEX, "");
                                    Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                                    if (expressionNode.isPresent()) {
                                        if (name.equals(Constants.TABLE_NAME)) {
                                            referenceRecordName = Utils.eliminateDoubleQuotes(expressionNode.get().
                                                    toSourceCode().trim());
                                        }
                                    }
                                }
                            }
                        }
                    }
                    for (Node recordField : recordTypeDescriptor.fields()) {
                        String fieldType;
                        String relationAnnotation = "false";
                        if (recordField instanceof RecordFieldNode) {
                            RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                            fieldType = recordFieldNode.typeName().toSourceCode().trim();
                            Optional<MetadataNode> metaData = recordFieldNode.metadata();
                            if (metaData.isPresent()) {
                                relationAnnotation = checkRelationAnnotation(metaData.get());
                            }
                        } else {
                            RecordFieldWithDefaultValueNode recordFieldNode =
                                    (RecordFieldWithDefaultValueNode) recordField;
                            fieldType = recordFieldNode.typeName().toSourceCode().trim();
                            Optional<MetadataNode> metaData = recordFieldNode.metadata();
                            if (metaData.isPresent()) {
                                relationAnnotation = checkRelationAnnotation(metaData.get());
                            }
                        }
                        if (fieldType.contains(recordName)) {
                            if (fieldType.endsWith("]")) {
                                return new Object[]{referenceRecordName, Constants.ONE_TO_MANY, relationAnnotation,
                                        referenceRecord};
                            } else {
                                return new Object[]{referenceRecordName, Constants.ONE_TO_ONE, relationAnnotation,
                                        referenceRecord};
                            }
                        }
                    }
                }
            }
        }
        return new Object[]{referenceRecordName, Constants.ONE_TO_ONE, Constants.FALSE, referenceRecord,
                "Field does not exist"};
    }

    private String checkRelationAnnotation(MetadataNode metadataNode) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            if (annotation.annotReference().toSourceCode().trim().equals(Annotations.RELATION)) {
                return Constants.TRUE;
            }
        }
        return Constants.FALSE;
    }

    private void processRelationAnnotation(SyntaxNodeAnalysisContext ctx, AnnotationNode annotationNode,
                                           TypeDefinitionNode referenceRecord) {
        ListConstructorExpressionNode reference = null;
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.REFERENCE)) {
                    Optional<ExpressionNode> node = specificFieldNode.valueExpr();
                    if (node.isPresent()) {
                        if (node.get() instanceof ListConstructorExprNode) {
                            reference = (ListConstructorExpressionNode) node.get();
                        }
                    }
                }
            }
            if (reference != null && reference.expressions().size() != 0) {
                String referenceKey = Utils.eliminateDoubleQuotes(reference.expressions().get(0).toSourceCode().trim());
                getForeignKeyType(ctx, referenceRecord, referenceKey);
            } else {
                getReferenceKeyAndType(ctx, referenceRecord);
            }
        }
        getReferenceKeyAndType(ctx, referenceRecord);
    }

    private void getReferenceKeyAndType(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode referenceRecord) {
        List<String> primaryKeys = new ArrayList<>();
        Optional<MetadataNode> metadata = referenceRecord.metadata();
        if (metadata.isPresent()) {
            for (AnnotationNode annotation : metadata.get().annotations()) {
                if (!(annotation.annotReference().toSourceCode().trim().equals(Annotations.ENTITY))) {
                    continue;
                }
                Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode = annotation.annotValue();
                if (mappingConstructorExpressionNode.isEmpty()) {
                    continue;
                }
                SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().fields();
                for (MappingFieldNode mappingFieldNode : fields) {
                    SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                    Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                    if (!(expressionNode.isPresent() && !fieldNode.fieldName().toSourceCode().trim().
                            equals(Constants.TABLE_NAME))) {
                        continue;
                    }
                    ListConstructorExpressionNode listConstructorExpressionNode =
                            (ListConstructorExpressionNode) expressionNode.get();
                    SeparatedNodeList<Node> expressions = listConstructorExpressionNode.
                            expressions();
                    for (Node expression : expressions) {
                        if (expression instanceof BasicLiteralNode) {
                            primaryKeys.add(Utils.
                                    eliminateDoubleQuotes(
                                            expression.toSourceCode().trim()));
                        } else if (expression instanceof ListConstructorExpressionNode) {
                            listConstructorExpressionNode =
                                    (ListConstructorExpressionNode) expression;
                            SeparatedNodeList<Node> exps = listConstructorExpressionNode.
                                    expressions();
                            List<String> uniqueConstraint = new ArrayList<>();
                            for (Node exp : exps) {
                                if (exp instanceof BasicLiteralNode) {
                                    uniqueConstraint.add(Utils.eliminateDoubleQuotes(exp.toSourceCode().trim()));
                                }
                            }
                            this.uniqueConstraints.add(uniqueConstraint);
                        } else {
                            Utils.reportDiagnostic(ctx, expression.location(),
                                    DiagnosticsCodes.PERSIST_127.getCode(),
                                    MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                            EntityAnnotation.UNIQUE_CONSTRAINTS),
                                    DiagnosticsCodes.PERSIST_127.getSeverity());
                        }
                    }
                }
            }
        }

        if (primaryKeys.size() > 0) {
            if (primaryKeys.size() == 1) {
                getInfoFromSinglePrimary(ctx, referenceRecord, primaryKeys);
            } else {
                Utils.reportDiagnostic(ctx, referenceRecord.location(),
                        DiagnosticsCodes.PERSIST_122.getCode(),
                        DiagnosticsCodes.PERSIST_122.getMessage(),
                        DiagnosticsCodes.PERSIST_122.getSeverity());
            }
        } else {
            Utils.reportDiagnostic(ctx, referenceRecord.location(),
                    DiagnosticsCodes.PERSIST_123.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_123.getMessage(), EntityAnnotation.KEY),
                    DiagnosticsCodes.PERSIST_123.getSeverity());
        }
    }

    private void getInfoFromSinglePrimary(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode referenceRecord,
                                          List<String> primaryKeys) {
        String referenceKey = Constants.EMPTY;
        if (primaryKeys.size() == 1) {
            referenceKey = primaryKeys.get(0);
        }
        Optional<MetadataNode> entityMetadata = referenceRecord.metadata();
        RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) referenceRecord.typeDescriptor();
        if (entityMetadata.isPresent()) {
            for (Node recordField : recordTypeDescriptor.fields()) {
                if (referenceKey.isEmpty()) {
                    continue;
                }
                if (recordField instanceof RecordFieldNode) {
                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        validateType(ctx, recordFieldNode, recordFieldNode.typeName().toSourceCode().trim());
                    }
                } else {
                    RecordFieldWithDefaultValueNode recordFieldNode =
                            (RecordFieldWithDefaultValueNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        validateType(ctx, recordFieldNode, recordFieldNode.typeName().toSourceCode().trim());
                    }
                }
            }
        }
    }

    private void getForeignKeyType(SyntaxNodeAnalysisContext ctx, TypeDefinitionNode referenceRecord,
                                   String referenceKey) {
        Node typeDescriptor = referenceRecord.typeDescriptor();
        RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
        Optional<MetadataNode> entityMetadata = referenceRecord.metadata();
        if (entityMetadata.isPresent()) {
            for (Node recordField : recordTypeDescriptor.fields()) {
                if (recordField instanceof RecordFieldNode) {
                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        validateType(ctx, recordField, recordFieldNode.typeName().toSourceCode().trim());
                    }
                } else {
                    RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        validateType(ctx, recordField, recordFieldNode.typeName().toSourceCode().trim());
                    }
                }
            }
        }
    }

    private boolean isValidSimpleType(String type) {
        switch (type) {
            case Constants.BallerinaTypes.INT:
            case Constants.BallerinaTypes.BOOLEAN:
            case Constants.BallerinaTypes.DECIMAL:
            case Constants.BallerinaTypes.FLOAT:
            case Constants.BallerinaTypes.DATE:
            case Constants.BallerinaTypes.STRING:
            case Constants.BallerinaTypes.BYTE:
                return true;
            default:
                return false;
        }
    }

    private boolean isValidImportedType(String type) {
        switch (type) {
            case Constants.BallerinaTypes.TIME_OF_DAY:
            case Constants.BallerinaTypes.UTC:
            case Constants.BallerinaTypes.CIVIL:
                return true;
            default:
                return false;
        }
    }

    private void validateType(SyntaxNodeAnalysisContext ctx, Node node, String type) {
        switch (type) {
            case Constants.BallerinaTypes.INT:
            case Constants.BallerinaTypes.BOOLEAN:
            case Constants.BallerinaTypes.DECIMAL:
            case Constants.BallerinaTypes.FLOAT:
            case Constants.BallerinaTypes.DATE:
            case Constants.BallerinaTypes.TIME_OF_DAY:
            case Constants.BallerinaTypes.UTC:
            case Constants.BallerinaTypes.CIVIL:
            case Constants.BallerinaTypes.STRING:
                break;
            default:
                Utils.reportDiagnostic(ctx, node.location(),
                        DiagnosticsCodes.PERSIST_121.getCode(),
                        MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), type),
                        DiagnosticsCodes.PERSIST_121.getSeverity());
        }
    }
}
