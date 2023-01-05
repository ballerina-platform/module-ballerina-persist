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
import io.ballerina.stdlib.persist.compiler.Constants.BallerinaTimeTypes;
import io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes;
import io.ballerina.stdlib.persist.compiler.Constants.EntityAnnotation;
import io.ballerina.stdlib.persist.compiler.Constants.RelationAnnotation;
import io.ballerina.stdlib.persist.compiler.models.Entity;
import io.ballerina.stdlib.persist.compiler.models.Field;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;

/**
 * PersistRecordAnalyzer.
 */
public class PersistRecordValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final HashMap<String, Entity> entities;
    private final HashMap<String, List<Field>> deferredRelationKeyEntities;
    private boolean isEntitiesInMultipleModules = false;
    private String initialModuleContainingEntity = "";

    public PersistRecordValidator() {
        this.entities = new HashMap<>();
        this.deferredRelationKeyEntities = new HashMap<>();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {

        if (Utils.hasCompilationErrors(ctx)) {
            return;
        }

        ModuleId moduleId = ctx.moduleId();
        Module currentModule = ctx.currentPackage().module(moduleId);
        String moduleName = currentModule.moduleName().toString().trim();

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
                Entity entity = new Entity(entityName, moduleName, recordTypeSymbol.fieldDescriptors().keySet(),
                        typeDefinitionNode.location());

                validateRecordProperties(entity, ((RecordTypeDescriptorNode) typeDescriptorNode));
                validateEntityAnnotation(entity, entityAnnotation.get());
                validateEntityFields(entity, ((RecordTypeDescriptorNode) typeDescriptorNode).fields(), currentModule);
                validateAutoIncrementAnnotation(entity);
                validateRelationAnnotation(entity);
                if (this.deferredRelationKeyEntities.containsKey(entityName)) {
                    List<Field> annotatedFields = this.deferredRelationKeyEntities.get(entityName);
                    for (Field field : annotatedFields) {
                        validateRelations(field, entity, entity);
                    }
                }
                validateEntitiesInMultipleModule(entity);

                entity.getDiagnostics().forEach((ctx::reportDiagnostic));
                this.entities.put(entity.getEntityName(), entity);
            } else {
                checkForFieldAnnotations(ctx, (RecordTypeDescriptorNode) typeDescriptorNode);
            }
        } else {
            checkForFieldAnnotations(ctx, (RecordTypeDescriptorNode) typeDescriptorNode);
        }
    }

    private Optional<AnnotationNode> getEntityAnnotation(NodeList<AnnotationNode> annotations) {
        for (AnnotationNode annotation : annotations) {
            if (Utils.isPersistAnnotation(annotation, Annotations.ENTITY)) {
                return Optional.of(annotation);
            }
        }
        return Optional.empty();
    }

    private void validateEntitiesInMultipleModule(Entity entity) {
        if (this.entities.isEmpty()) {
            this.initialModuleContainingEntity = entity.getModule();
            return;
        }

        if (this.isEntitiesInMultipleModules) {
            entity.addDiagnostic(entity.getLocation(), DiagnosticsCodes.PERSIST_119.getCode(),
                    DiagnosticsCodes.PERSIST_119.getMessage(), DiagnosticsCodes.PERSIST_119.getSeverity());
            return;
        }

        if (!this.initialModuleContainingEntity.equals(entity.getModule())) {
            this.isEntitiesInMultipleModules = true;
            for (Entity validatedEntity : this.entities.values()) {
                entity.addDiagnostic(validatedEntity.getLocation(), DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getMessage(), DiagnosticsCodes.PERSIST_119.getSeverity());
            }
            entity.addDiagnostic(entity.getLocation(), DiagnosticsCodes.PERSIST_119.getCode(),
                    DiagnosticsCodes.PERSIST_119.getMessage(), DiagnosticsCodes.PERSIST_119.getSeverity());
        }
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
                    default:
                        // Unreachable code as type descriptor is a closed record.
                        throw new RuntimeException("Unsupported @persist:Entity annotation field, " + fieldName);
                }

            }
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

    private void validateEntityFields(Entity entity, NodeList<Node> fields, Module currentModule) {
        for (Node fieldNode : fields) {
            Field field;
            Node typeNode;
            if (fieldNode instanceof RecordFieldNode) {
                RecordFieldNode recordFieldNode = (RecordFieldNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                String fieldName = recordFieldNode.fieldName().text().trim();
                typeNode = recordFieldNode.typeName();
                field = getField(fieldName, fieldNode.location(), metadataNode, entity.getEntityName());
                field.setReadOnly(recordFieldNode.readonlyKeyword().isPresent());
                if (recordFieldNode.questionMarkToken().isPresent()) {
                    field.setOptional(true);
                }
            } else if (fieldNode instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) fieldNode;
                Optional<MetadataNode> metadataNode = recordFieldNode.metadata();
                String fieldName = recordFieldNode.fieldName().text().trim();
                typeNode = recordFieldNode.typeName();
                field = getField(fieldName, fieldNode.location(), metadataNode, entity.getEntityName());
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
                field.setArrayType(true);
            }

            if (typeNode instanceof BuiltinSimpleNameReferenceNode) {
                String type = ((BuiltinSimpleNameReferenceNode) typeNode).name().text();
                if (isValidSimpleType(type)) {
                    if (validateNonRelationFieldProperties(field, entity, typeNode, isArrayType)) {
                        continue;
                    }
                } else if (type.equals(BallerinaTypes.BYTE) && isArrayType) {
                    if (field.isOptional()) {
                        entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_104.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_104.getMessage(), field.getFieldName()),
                                DiagnosticsCodes.PERSIST_104.getSeverity());
                        continue;
                    }
                } else {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(), type),
                            DiagnosticsCodes.PERSIST_121.getSeverity());
                }
            } else if (typeNode instanceof QualifiedNameReferenceNode) {
                // Support only time constructs
                QualifiedNameReferenceNode qualifiedName = (QualifiedNameReferenceNode) typeNode;
                String modulePrefix = qualifiedName.modulePrefix().text();
                String identifier = qualifiedName.identifier().text();
                if (!isValidImportedType(modulePrefix, identifier)) {
                    entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_121.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_121.getMessage(),
                                    modulePrefix + ":" + identifier),
                            DiagnosticsCodes.PERSIST_121.getSeverity());
                    continue;
                } else {
                    if (validateNonRelationFieldProperties(field, entity, typeNode, isArrayType)) {
                        continue;
                    }
                }
            } else if (typeNode instanceof SimpleNameReferenceNode) {
                field.setValidRelationAttachmentPoint(true);
                if (this.entities.containsKey(field.getFieldName())) {
                    field.setRelationAttachedToValidEntity(true);
                } else {
                    // Have to check all entities present in this module
                    String attachedEntity = ((SimpleNameReferenceNode) typeNode).name().text();
                    validateAttachmentType(entity, field, attachedEntity, typeNode.location(),
                            currentModule);
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

    private boolean validateNonRelationFieldProperties(Field field, Entity entity, Node typeNode, boolean isArrayType) {
        if (field.isOptional()) {
            entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_104.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_104.getMessage(), field.getFieldName()),
                    DiagnosticsCodes.PERSIST_104.getSeverity());
            return true;
        } else if (isArrayType) {
            entity.addDiagnostic(typeNode.location(), DiagnosticsCodes.PERSIST_120.getCode(),
                    DiagnosticsCodes.PERSIST_120.getMessage(), DiagnosticsCodes.PERSIST_120.getSeverity());
            return true;
        }
        return false;
    }

    private void validateAttachmentType(Entity entity, Field field, String referencedRecordName,
                                        NodeLocation location, Module currentModule) {
        boolean isValidRecord = false;
        boolean isEntity = false;
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
                    isValidRecord = true;
                    Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
                    if (metadata.isPresent()) {
                        if (getEntityAnnotation(metadata.get().annotations()).isPresent()) {
                            isEntity = true;
                        }
                    }
                    break;
                }
            }
        }

        if (!isValidRecord) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_135.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_135.getMessage(), referencedRecordName),
                    DiagnosticsCodes.PERSIST_135.getSeverity());
        } else if (!isEntity) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_132.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_132.getMessage(), referencedRecordName),
                    DiagnosticsCodes.PERSIST_132.getSeverity());
        } else {
            field.setRelationAttachedToValidEntity(true);
        }
    }

    private Field getField(String fieldName, NodeLocation location, Optional<MetadataNode> metadataNode,
                           String containingEntity) {
        AnnotationNode autoIncrementNode = null;
        AnnotationNode relationNode = null;
        if (metadataNode.isPresent()) {
            NodeList<AnnotationNode> annotations = metadataNode.get().annotations();
            for (AnnotationNode annotation : annotations) {
                if (Utils.isPersistAnnotation(annotation, Annotations.AUTO_INCREMENT)) {
                    autoIncrementNode = annotation;
                } else if (Utils.isPersistAnnotation(annotation, Annotations.RELATION)) {
                    relationNode = annotation;
                }
            }
        }
        return new Field(fieldName, location, autoIncrementNode, relationNode, containingEntity);
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
                        .equals(BallerinaTypes.INT)) {
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
                        } else if (specificFieldValue instanceof BasicLiteralNode) {
                            if (!((BasicLiteralNode) specificFieldValue).literalToken().text().equals(Constants.ONE)) {
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

    private void validateRelationAnnotation(Entity entity) {
        for (Field validEntityField : entity.getValidEntityFields()) {
            if (!validEntityField.isValidRelationAttachmentPoint()
                    && validEntityField.getRelationAnnotation() != null) {
                entity.addDiagnostic(validEntityField.getFieldLocation(), DiagnosticsCodes.PERSIST_117.getCode(),
                        DiagnosticsCodes.PERSIST_117.getMessage(), DiagnosticsCodes.PERSIST_117.getSeverity());
                continue;
            }
            if (!validEntityField.isRelationAttachedToValidEntity()) {
                // Relation annotation type is only validated if not attached properly
                continue;
            }

            if (!validEntityField.isOptional()) {
                entity.addDiagnostic(validEntityField.getFieldLocation(),
                        DiagnosticsCodes.PERSIST_133.getCode(), DiagnosticsCodes.PERSIST_133.getMessage(),
                        DiagnosticsCodes.PERSIST_133.getSeverity());
            }

            AnnotationNode relationAnnotation = validEntityField.getRelationAnnotation();
            if (relationAnnotation != null && relationAnnotation.annotValue().isPresent()) {
                processRelationAnnotation(entity, validEntityField, relationAnnotation.annotValue().get());
            }

            SeparatedNodeList<Node> keyColumnExpressions = validEntityField.getKeyColumnExpressions();
            SeparatedNodeList<Node> referenceExpressions = validEntityField.getReferenceExpressions();

            if ((keyColumnExpressions != null && referenceExpressions != null)
                    && (keyColumnExpressions.size() != referenceExpressions.size())) {
                entity.addDiagnostic(validEntityField.getRelationAnnotation().location(),
                        DiagnosticsCodes.PERSIST_109.getCode(),
                        DiagnosticsCodes.PERSIST_109.getMessage(),
                        DiagnosticsCodes.PERSIST_109.getSeverity());
            }

            Node typeNode = getReferencedType(validEntityField);
            String referredEntity = ((SimpleNameReferenceNode) typeNode).name().text();
            if (this.entities.containsKey(referredEntity)) {
                // Related entity is already process and is available in entities list
                validateRelations(validEntityField, this.entities.get(referredEntity), entity);
                if (this.deferredRelationKeyEntities.containsKey(entity.getEntityName())) {
                    List<Field> annotatedFields = this.deferredRelationKeyEntities.get(entity.getEntityName());
                    annotatedFields.removeIf(field -> field.getContainingEntityName().equals(referredEntity));
                    if (annotatedFields.isEmpty()) {
                        this.deferredRelationKeyEntities.remove(entity.getEntityName());
                    }
                }
            } else {
                if (this.deferredRelationKeyEntities.containsKey(referredEntity)) {
                    this.deferredRelationKeyEntities.get(referredEntity).add(validEntityField);
                } else {
                    List<Field> references = new ArrayList<>();
                    references.add(validEntityField);
                    this.deferredRelationKeyEntities.put(referredEntity, references);
                }
            }
        }
    }

    private void processRelationAnnotation(Entity entity, Field validEntityField,
                                           MappingConstructorExpressionNode relationAnnotation) {
        SeparatedNodeList<MappingFieldNode> fields = relationAnnotation.fields();
        for (MappingFieldNode fieldNode : fields) {
            SpecificFieldNode specificFieldNode = (SpecificFieldNode) fieldNode;
            // If field is given as token( key: ) or string ("key": )
            String fieldName = getAnnotationFieldName(specificFieldNode);
            @SuppressWarnings("OptionalGetWithoutIsPresent")
            ExpressionNode specificFieldValue = specificFieldNode.valueExpr().get();
            switch (fieldName) {
                case RelationAnnotation.KEY_COLUMNS:
                    if (specificFieldValue instanceof ListConstructorExpressionNode) {
                        // todo: Validate for empty list
                        ListConstructorExpressionNode listConstructorExpressionNode =
                                (ListConstructorExpressionNode) specificFieldValue;
                        SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                        validEntityField.setKeyColumnExpressions(expressions);
                    } else {
                        entity.addDiagnostic(specificFieldNode.location(),
                                DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                        RelationAnnotation.KEY_COLUMNS),
                                DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                    break;
                case RelationAnnotation.REFERENCED_FIELDS:
                    if (specificFieldValue instanceof ListConstructorExpressionNode) {
                        // todo: Validate for empty list
                        ListConstructorExpressionNode listConstructorExpressionNode =
                                (ListConstructorExpressionNode) specificFieldValue;
                        SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                        validEntityField.setReferenceExpressions(expressions);
                    } else {
                        entity.addDiagnostic(specificFieldNode.location(),
                                DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(),
                                        RelationAnnotation.REFERENCED_FIELDS),
                                DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                    break;
                case RelationAnnotation.ON_DELETE:
                case RelationAnnotation.ON_UPDATE:
                    if (!(specificFieldValue instanceof QualifiedNameReferenceNode) &&
                            !(specificFieldValue instanceof BasicLiteralNode)) {
                        entity.addDiagnostic(specificFieldNode.location(),
                                DiagnosticsCodes.PERSIST_127.getCode(),
                                MessageFormat.format(DiagnosticsCodes.PERSIST_127.getMessage(), fieldName),
                                DiagnosticsCodes.PERSIST_127.getSeverity());
                    }
                    break;
                default:
                    // Unreachable call, as relation annotation type descriptor is closed record.
                    throw new RuntimeException("Unsupported field in @persist:Relation annotation " +
                            fieldName);
            }
        }
    }

    private void validateRelations(Field annotatedField, Entity referredEntity, Entity reportDiagnosticsEntity) {
        Field referredField = null;
        for (Field field : referredEntity.getValidEntityFields()) {
            Node typeNode = getReferencedType(field);
            if (typeNode instanceof SimpleNameReferenceNode) {
                String fieldType = ((SimpleNameReferenceNode) typeNode).name().text();
                if (fieldType.equals(annotatedField.getContainingEntityName())) {
                    referredField = field;
                    break;
                }
            }
        }

        if (referredField == null) {
            reportDiagnosticsEntity.addDiagnostic(annotatedField.getFieldLocation(),
                    DiagnosticsCodes.PERSIST_115.getCode(),
                    MessageFormat.format(DiagnosticsCodes.PERSIST_115.getMessage(), referredEntity.getEntityName()),
                    DiagnosticsCodes.PERSIST_115.getSeverity());
            return;
        }

        // One to many annotations, with reference given in child
        if ((referredField.isArrayType() && !annotatedField.isArrayType()) ||
                (!referredField.isArrayType() && annotatedField.isArrayType())) {
            if (referredField.isArrayType() && referredField.getRelationAnnotation() != null) {
                reportDiagnosticsEntity.addDiagnostic(referredField.getRelationAnnotation().location(),
                        DiagnosticsCodes.PERSIST_118.getCode(), DiagnosticsCodes.PERSIST_118.getMessage(),
                        DiagnosticsCodes.PERSIST_118.getSeverity());
            }
            if (annotatedField.isArrayType() && annotatedField.getRelationAnnotation() != null) {
                reportDiagnosticsEntity.addDiagnostic(annotatedField.getRelationAnnotation().location(),
                        DiagnosticsCodes.PERSIST_118.getCode(), DiagnosticsCodes.PERSIST_118.getMessage(),
                        DiagnosticsCodes.PERSIST_118.getSeverity());
            }
        }

        // one - one relation
        if (!referredField.isArrayType() && !annotatedField.isArrayType()) {
            if (referredField.getRelationAnnotation() != null && annotatedField.getRelationAnnotation() != null) {
                reportDiagnosticsEntity.addDiagnostic(annotatedField.getRelationAnnotation().location(),
                        DiagnosticsCodes.PERSIST_116.getCode(), DiagnosticsCodes.PERSIST_116.getMessage(),
                        DiagnosticsCodes.PERSIST_116.getSeverity());
            }
            if (referredField.getRelationAnnotation() == null && annotatedField.getRelationAnnotation() == null) {
                reportDiagnosticsEntity.addDiagnostic(annotatedField.getFieldLocation(),
                        DiagnosticsCodes.PERSIST_134.getCode(), DiagnosticsCodes.PERSIST_134.getMessage(),
                        DiagnosticsCodes.PERSIST_134.getSeverity());
            }
        }
    }

    private Node getReferencedType(Field field) {
        Node type = field.getType();
        if (type instanceof OptionalTypeDescriptorNode) {
            type = ((OptionalTypeDescriptorNode) type).typeDescriptor();
            field.setOptional(true);
        }
        if (type instanceof ArrayTypeDescriptorNode) {
            type = ((ArrayTypeDescriptorNode) type).memberTypeDesc();
            field.setArrayType(true);
        }
        return type;
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
            if (Utils.isPersistAnnotation(annotation, Annotations.AUTO_INCREMENT)) {
                Utils.reportDiagnostic(ctx, annotation.location(), DiagnosticsCodes.PERSIST_126.getCode(),
                        DiagnosticsCodes.PERSIST_126.getMessage(), DiagnosticsCodes.PERSIST_126.getSeverity());
            } else if (Utils.isPersistAnnotation(annotation, Annotations.RELATION)) {
                Utils.reportDiagnostic(ctx, annotation.location(), DiagnosticsCodes.PERSIST_125.getCode(),
                        DiagnosticsCodes.PERSIST_125.getMessage(), DiagnosticsCodes.PERSIST_125.getSeverity());
            }
        }
    }

    private void validateConstraintFieldNames(Entity entity, String value, NodeLocation location) {
        if (!entity.getEntityFieldNames().contains(value)) {
            entity.addDiagnostic(location, DiagnosticsCodes.PERSIST_102.getCode(),
                    DiagnosticsCodes.PERSIST_102.getMessage(), DiagnosticsCodes.PERSIST_102.getSeverity());
        }
    }

    private boolean isValidSimpleType(String type) {
        switch (type) {
            case BallerinaTypes.INT:
            case BallerinaTypes.BOOLEAN:
            case BallerinaTypes.DECIMAL:
            case BallerinaTypes.FLOAT:
            case BallerinaTypes.STRING:
                return true;
            default:
                return false;
        }
    }

    private boolean isValidImportedType(String modulePrefix, String identifier) {
        if (!modulePrefix.equals(Constants.TIME_MODULE)) {
            return false;
        }
        switch (identifier) {
            case BallerinaTimeTypes.DATE:
            case BallerinaTimeTypes.TIME_OF_DAY:
            case BallerinaTimeTypes.UTC:
            case BallerinaTimeTypes.CIVIL:
                return true;
            default:
                return false;
        }
    }

}
