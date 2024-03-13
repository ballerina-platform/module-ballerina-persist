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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.BuiltinSimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.EnumDeclarationNode;
import io.ballerina.compiler.syntax.tree.ImportPrefixNode;
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
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.projects.ProjectKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.projects.util.ProjectConstants;
import io.ballerina.stdlib.persist.compiler.model.Entity;
import io.ballerina.stdlib.persist.compiler.model.GroupedRelationField;
import io.ballerina.stdlib.persist.compiler.model.IdentityField;
import io.ballerina.stdlib.persist.compiler.model.RelationField;
import io.ballerina.stdlib.persist.compiler.model.RelationType;
import io.ballerina.stdlib.persist.compiler.model.SimpleTypeField;
import io.ballerina.stdlib.persist.compiler.utils.ValidatorsByDatastore;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BNumericProperty;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BStringProperty;

import java.io.File;
import java.nio.file.Path;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import static io.ballerina.stdlib.persist.compiler.Constants.ANNOTATION_REFS_FIELD;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.BOOLEAN;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.DECIMAL;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.FLOAT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.INT;
import static io.ballerina.stdlib.persist.compiler.Constants.BallerinaTypes.STRING;
import static io.ballerina.stdlib.persist.compiler.Constants.LS;
import static io.ballerina.stdlib.persist.compiler.Constants.PERSIST_DIRECTORY;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_001;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_002;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_003;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_004;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_005;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_101;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_201;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_202;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_301;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_302;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_303;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_304;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_305;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_307;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_309;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_401;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_402;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_403;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_404;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_405;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_406;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_420;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_422;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_501;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_502;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.model.RelationType.MANY_TO_MANY;
import static io.ballerina.stdlib.persist.compiler.model.RelationType.ONE_TO_MANY;
import static io.ballerina.stdlib.persist.compiler.model.RelationType.ONE_TO_ONE;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.getDatastore;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.getFieldName;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.getTypeName;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.hasCompilationErrors;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.readStringArrayValueFromAnnotation;
import static io.ballerina.stdlib.persist.compiler.utils.Utils.stripEscapeCharacter;

/**
 * Persist model definition validator.
 */
public class PersistModelDefinitionValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<String, Entity> entities = new HashMap<>();
    private final List<String> entityNames = new ArrayList<>();
    private final List<String> enumTypes = new ArrayList<>();
    private final Map<String, List<RelationField>> deferredRelationKeyEntities = new HashMap<>();
    private final Map<String, List<GroupedRelationField>> deferredGroupedRelationKeyEntities = new HashMap<>();

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (!isPersistModelDefinitionDocument(ctx)) {
            return;
        }

        if (hasCompilationErrors(ctx)) {
            return;
        }

        String datastore;
        try {
            datastore = getDatastore(ctx);
        } catch (BalException e) {
            throw new RuntimeException(e);
        }

        if (ctx.node() instanceof ImportPrefixNode) {
            Token prefix = ((ImportPrefixNode) ctx.node()).prefix();
            if (prefix.kind() != SyntaxKind.UNDERSCORE_KEYWORD) {
                int startOffset = ctx.node().location().textRange().startOffset() - 1;
                int length = ctx.node().location().textRange().length() + 1;
                ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                        new DiagnosticInfo(PERSIST_102.getCode(), PERSIST_102.getMessage(), PERSIST_102.getSeverity()),
                        ctx.node().location(),
                        List.of(new BNumericProperty(startOffset), new BNumericProperty(length))));
            }
            return;
        }

        ModulePartNode rootNode = (ModulePartNode) ctx.node();
        // Names in lowercase to check for duplicate entity names
        List<String> entityNames = new ArrayList<>();
        List<TypeDefinitionNode> foundEntities = new ArrayList<>();
        for (ModuleMemberDeclarationNode member : rootNode.members()) {
            if (member instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) member;
                TypeDescriptorNode typeDescriptorNode = (TypeDescriptorNode) typeDefinitionNode.typeDescriptor();
                if (typeDescriptorNode instanceof RecordTypeDescriptorNode) {
                    String entityName = stripEscapeCharacter(typeDefinitionNode.typeName().text().trim());
                    if (entityNames.contains(entityName.toLowerCase(Locale.ROOT))) {
                        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                                new DiagnosticInfo(PERSIST_202.getCode(),
                                        MessageFormat.format(PERSIST_202.getMessage(), entityName),
                                        PERSIST_202.getSeverity()), typeDefinitionNode.typeName().location())
                        );
                    } else {
                        foundEntities.add(typeDefinitionNode);
                        entityNames.add(entityName.toLowerCase(Locale.ROOT));
                        this.entityNames.add(entityName);
                    }
                    continue;
                }
            } else if (member instanceof EnumDeclarationNode) {
                String enumTypeName = stripEscapeCharacter(((EnumDeclarationNode) member).identifier().text().trim());
                enumTypes.add(enumTypeName);
                continue;
            }
            ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                    new DiagnosticInfo(PERSIST_101.getCode(), PERSIST_101.getMessage(), PERSIST_101.getSeverity()),
                    member.location()));
        }

        for (TypeDefinitionNode typeDefinitionNode : foundEntities) {
            String entityName = stripEscapeCharacter(typeDefinitionNode.typeName().text().trim());
            TypeDescriptorNode typeDescriptorNode = (TypeDescriptorNode) typeDefinitionNode.typeDescriptor();
            List<AnnotationNode> annotations = typeDefinitionNode.metadata().map(
                    metadata -> metadata.annotations().stream().toList()).orElse(Collections.emptyList());
            Entity entity = new Entity(entityName, typeDefinitionNode.typeName().location(),
                    ((RecordTypeDescriptorNode) typeDescriptorNode), annotations);
            validateEntityRecordProperties(entity);
            validateEntityFields(entity, datastore);
            validateIdentityFields(entity);
            validateEntityRelations(entity);

            if (this.deferredRelationKeyEntities.containsKey(entityName)) {
                List<RelationField> relationFields = this.deferredRelationKeyEntities.get(entityName);
                for (RelationField field : relationFields) {
                    validateRelation(field, this.entities.get(field.getContainingEntity()), entity, entity);
                }
            }
            if (this.deferredGroupedRelationKeyEntities.containsKey(entityName)) {
                List<GroupedRelationField> groupedRelationFields =
                        this.deferredGroupedRelationKeyEntities.get(entityName);
                for (GroupedRelationField field : groupedRelationFields) {
                    validateGroupedRelation(field, this.entities.get(field.getContainingEntity()), entity, entity);
                }
            }
            this.entities.put(entityName, entity);
            entity.getDiagnostics().forEach(ctx::reportDiagnostic);
        }
    }

    private void validateEntityRecordProperties(Entity entity) {
        // Check whether the entity is a closed record
        RecordTypeDescriptorNode recordTypeDescriptorNode = entity.getTypeDescriptorNode();
        if (recordTypeDescriptorNode.bodyStartDelimiter().kind() != SyntaxKind.OPEN_BRACE_PIPE_TOKEN) {
            entity.reportDiagnostic(PERSIST_201.getCode(), PERSIST_201.getMessage(), PERSIST_201.getSeverity(),
                    recordTypeDescriptorNode.location(),
                    List.of(
                            new BNumericProperty(recordTypeDescriptorNode.bodyStartDelimiter().textRange().endOffset()),
                            new BNumericProperty(recordTypeDescriptorNode.bodyEndDelimiter().textRange().startOffset())
                    ));
        }
    }

    private void validateEntityFields(Entity entity, String datastore) {
        // Check whether the entity has rest field initialization
        RecordTypeDescriptorNode typeDescriptorNode = entity.getTypeDescriptorNode();
        if (typeDescriptorNode.recordRestDescriptor().isPresent()) {
            entity.reportDiagnostic(PERSIST_301.getCode(), PERSIST_301.getMessage(), PERSIST_301.getSeverity(),
                    typeDescriptorNode.recordRestDescriptor().get().location());
        }

        NodeList<Node> fields = typeDescriptorNode.fields();
        // FieldNames in lower case
        List<String> fieldNames = new ArrayList<>();
        for (Node fieldNode : fields) {
            IdentityField identityField = null;
            boolean isIdentityField = false;
            int readonlyTextRangeStartOffset = 0;
            RecordFieldNode recordFieldNode;
            String fieldName;
            if (fieldNode instanceof RecordFieldNode) {
                recordFieldNode = (RecordFieldNode) fieldNode;
                fieldName = stripEscapeCharacter(recordFieldNode.fieldName().text().trim());
                if (recordFieldNode.readonlyKeyword().isPresent()) {
                    isIdentityField = true;
                    readonlyTextRangeStartOffset = recordFieldNode.readonlyKeyword().get().textRange().startOffset();
                    identityField = new IdentityField(fieldName);
                }
            } else if (fieldNode instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode defaultField = (RecordFieldWithDefaultValueNode) fieldNode;
                int startOffset = defaultField.fieldName().textRange().endOffset();
                int length = defaultField.semicolonToken().textRange().startOffset() - startOffset;
                entity.reportDiagnostic(PERSIST_302.getCode(), PERSIST_302.getMessage(), PERSIST_302.getSeverity(),
                        fieldNode.location(), List.of(new BNumericProperty(startOffset), new BNumericProperty(length)));
                continue;
            } else {
                // Inherited Field
                entity.reportDiagnostic(PERSIST_303.getCode(), PERSIST_303.getMessage(), PERSIST_303.getSeverity(),
                        fieldNode.location());
                continue;
            }

            List<AnnotationNode> annotations =
                    recordFieldNode.metadata().map(metadata ->
                            metadata.annotations().stream().toList()).orElse(Collections.emptyList());

            if (fieldNames.contains(fieldName.toLowerCase(Locale.ROOT))) {
                entity.reportDiagnostic(PERSIST_307.getCode(),
                        MessageFormat.format(PERSIST_307.getMessage(), fieldName), PERSIST_307.getSeverity(),
                        recordFieldNode.fieldName().location());
                continue;
            }
            fieldNames.add(fieldName.toLowerCase(Locale.ROOT));

            // Check if optional field
            if (recordFieldNode.questionMarkToken().isPresent()) {
                if (datastore.equals(Constants.Datastores.REDIS)) {
                    if (recordFieldNode.readonlyKeyword().isPresent()) {
                        int startOffset = recordFieldNode.questionMarkToken().get().textRange().startOffset();
                        int length = recordFieldNode.semicolonToken().textRange().startOffset() - startOffset;
                        entity.reportDiagnostic(PERSIST_309.getCode(), PERSIST_309.getMessage(),
                                PERSIST_309.getSeverity(), recordFieldNode.location(),
                                List.of(new BNumericProperty(startOffset), new BNumericProperty(length)));
                    }
                } else {
                    int startOffset = recordFieldNode.questionMarkToken().get().textRange().startOffset();
                    int length = recordFieldNode.semicolonToken().textRange().startOffset() - startOffset;
                    entity.reportDiagnostic(PERSIST_304.getCode(), PERSIST_304.getMessage(), PERSIST_304.getSeverity(),
                            recordFieldNode.location(),
                            List.of(new BNumericProperty(startOffset), new BNumericProperty(length)));
                }
            }

            Node typeNode = recordFieldNode.typeName();
            Node processedTypeNode = typeNode;
            String typeNamePostfix = "";
            boolean isArrayType = false;
            int arrayStartOffset = 0;
            int arrayLength = 0;
            boolean isOptionalType = false;
            boolean isValidType = false;
            boolean isSimpleType = false;
            int nullableStartOffset = 0;
            String fieldType;
            if (processedTypeNode instanceof OptionalTypeDescriptorNode) {
                isOptionalType = true;
                OptionalTypeDescriptorNode optionalTypeNode = (OptionalTypeDescriptorNode) processedTypeNode;
                processedTypeNode = optionalTypeNode.typeDescriptor();
                nullableStartOffset = optionalTypeNode.questionMarkToken().textRange().startOffset();
            }
            if (processedTypeNode instanceof ArrayTypeDescriptorNode) {
                isArrayType = true;
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) processedTypeNode);
                arrayStartOffset = arrayTypeDescriptorNode.dimensions().get(0).openBracket().textRange().startOffset();
                arrayLength = arrayTypeDescriptorNode.dimensions().get(0).closeBracket().textRange().endOffset() -
                        arrayStartOffset;
                processedTypeNode = arrayTypeDescriptorNode.memberTypeDesc();
                typeNamePostfix = SyntaxKind.OPEN_BRACKET_TOKEN.stringValue() +
                        SyntaxKind.CLOSE_BRACKET_TOKEN.stringValue();
            }

            if (processedTypeNode instanceof BuiltinSimpleNameReferenceNode) {
                String type = ((BuiltinSimpleNameReferenceNode) processedTypeNode).name().text();
                fieldType = type;
                List<DiagnosticProperty<?>> properties = List.of(
                        new BNumericProperty(arrayStartOffset),
                        new BNumericProperty(arrayLength),
                        new BStringProperty(isOptionalType ? type + "?" : type));
                isValidType = ValidatorsByDatastore.validateSimpleTypes(
                        entity, typeNode, typeNamePostfix, isArrayType, isOptionalType, properties, type, datastore);
                isSimpleType = true;
            } else if (processedTypeNode instanceof QualifiedNameReferenceNode) {
                // Support only time constructs
                QualifiedNameReferenceNode qualifiedName = (QualifiedNameReferenceNode) processedTypeNode;
                String modulePrefix = stripEscapeCharacter(qualifiedName.modulePrefix().text());
                String identifier = stripEscapeCharacter(qualifiedName.identifier().text());
                fieldType = modulePrefix + ":" + identifier;
                List<DiagnosticProperty<?>> properties = List.of(
                        new BNumericProperty(arrayStartOffset),
                        new BNumericProperty(arrayLength),
                        new BStringProperty(isOptionalType ? fieldType + "?" : fieldType));

                isValidType = ValidatorsByDatastore.validateImportedTypes(
                        entity, typeNode, isArrayType, isOptionalType, properties, modulePrefix, identifier, datastore);
                isSimpleType = true;
            } else if (processedTypeNode instanceof SimpleNameReferenceNode) {
                String typeName = stripEscapeCharacter(
                        ((SimpleNameReferenceNode) processedTypeNode).name().text().trim());
                fieldType = typeName;
                if (this.entityNames.contains(typeName)) {
                    isValidType = true;
                    entity.setContainsRelations(true);
                    entity.addRelationField(new RelationField(fieldName, typeName,
                            typeNode.location().textRange().endOffset(), isOptionalType, nullableStartOffset,
                            isArrayType, arrayStartOffset, arrayLength, recordFieldNode.location(),
                            entity.getEntityName(), annotations));
                } else {
                    if (this.enumTypes.contains(typeName)) {
                        typeName = Constants.BallerinaTypes.ENUM;
                    }

                    // Revisit once https://github.com/ballerina-platform/ballerina-lang/issues/39441 is resolved
                    List<DiagnosticProperty<?>> properties = List.of(
                            new BNumericProperty(arrayStartOffset),
                            new BNumericProperty(arrayLength),
                            new BStringProperty(isOptionalType ? typeName + "?" : typeName));
                    isValidType = ValidatorsByDatastore.validateSimpleTypes(entity, typeNode, typeNamePostfix,
                            isArrayType, isOptionalType, properties, typeName, datastore);
                    isSimpleType = true;
                }
            } else {
                String typeName = getTypeName(processedTypeNode);
                fieldType = typeName;
                if (!isArrayType && !ValidatorsByDatastore.isValidSimpleType(typeName, datastore)) {
                    entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                                    typeName), PERSIST_305.getSeverity(), typeNode.location());
                } else if (isArrayType && !ValidatorsByDatastore.isValidArrayType(typeName, datastore)) {
                    entity.reportDiagnostic(PERSIST_306.getCode(), MessageFormat.format(PERSIST_306.getMessage(),
                            typeName), PERSIST_306.getSeverity(), typeNode.location());
                }
            }
            if (isIdentityField) {
                identityField.setType(fieldType);
                identityField.setValidType(isValidType);
                identityField.setNullable(isOptionalType);
                identityField.setNullableStartOffset(nullableStartOffset);
                identityField.setReadonlyTextRangeStartOffset(readonlyTextRangeStartOffset);
                identityField.setTypeLocation(typeNode.location());
                entity.addIdentityField(identityField);
            }

            if (isSimpleType) {
                entity.addNonRelationField(new SimpleTypeField(fieldName, fieldType, isValidType,
                        isOptionalType, isArrayType, fieldNode.location(), typeNode.location(), annotations));
            }

        }
    }

    private void validateIdentityFields(Entity entity) {
        if (entity.getIdentityFields().isEmpty()) {
            entity.reportDiagnostic(PERSIST_501.getCode(), MessageFormat.format(PERSIST_501.getMessage(),
                    entity.getEntityName()), PERSIST_501.getSeverity(), entity.getEntityNameLocation());
            entity.getNonRelationFields().stream()
                    .filter(field -> field.isValidType() && !field.isNullable() &&
                            !field.isArrayType() && getSupportedIdentityFields().contains(field.getType()))
                    .forEach(field -> {
                        String codeActionTitle = MessageFormat.format("Mark field ''{0}'' as identity field",
                                field.getName());
                        entity.reportDiagnostic(PERSIST_001.getCode(), PERSIST_001.getMessage(),
                                PERSIST_001.getSeverity(), entity.getEntityNameLocation(),
                                List.of(new BNumericProperty(field.getNodeLocation().textRange().startOffset()),
                                        new BStringProperty(codeActionTitle),
                                        new BStringProperty("readonly ")));
                    });
            return;
        }

        for (IdentityField identityField : entity.getIdentityFields()) {
            if (!identityField.isValidType()) {
                continue;
            }
            String type = identityField.getType();
            if (!getSupportedIdentityFields().contains(type)) {
                entity.reportDiagnostic(PERSIST_503.getCode(), MessageFormat.format(PERSIST_503.getMessage(),
                                type), PERSIST_503.getSeverity(), identityField.getTypeLocation(),
                        List.of(new BNumericProperty(identityField.getReadonlyTextRangeStartOffset()),
                                new BNumericProperty(9)));
                continue;
            }
            if (identityField.isNullable()) {
                entity.reportDiagnostic(PERSIST_502.getCode(), MessageFormat.format(PERSIST_502.getMessage(),
                                entity.getEntityName()), PERSIST_502.getSeverity(), identityField.getTypeLocation(),
                        List.of(new BNumericProperty(identityField.getNullableStartOffset()),
                                new BNumericProperty(1), new BStringProperty(type)));
            }
        }

    }

    private List<String> getSupportedIdentityFields() {
        return List.of(
                INT, STRING, BOOLEAN, DECIMAL, FLOAT
        );
    }

    private void validateEntityRelations(Entity entity) {
        if (!entity.isContainsRelations()) {
            return;
        }

        for (RelationField relationField : entity.getRelationFields().values()) {
            String referredEntity = relationField.getType();

            if (referredEntity.equals(relationField.getContainingEntity())) {
                entity.reportDiagnostic(PERSIST_401.getCode(), PERSIST_401.getMessage(),
                        PERSIST_401.getSeverity(), relationField.getLocation());
                break;
            }

            if (this.entities.containsKey(referredEntity)) {
                validateRelation(relationField, entity, this.entities.get(referredEntity), entity);
                removeDeferredRelationsFromFirstEntity(entity, referredEntity);
            } else {
                this.deferredRelationKeyEntities.compute(referredEntity, (key, value) -> {
                    if (value == null) {
                        value = new ArrayList<>();
                    }
                    value.add(relationField);
                    return value;
                });
            }
        }

        for (GroupedRelationField relationField : entity.getGroupedRelationFields().values()) {
            String referredEntity = relationField.getRelationFields().get(0).getType();
            if (referredEntity.equals(relationField.getContainingEntity())) {
                relationField.getRelationFields()
                        .forEach((field) -> entity.reportDiagnostic(PERSIST_401.getCode(), PERSIST_401.getMessage(),
                                PERSIST_401.getSeverity(), field.getLocation())
                        );
                break;
            }

            if (this.entities.containsKey(referredEntity)) {
                validateGroupedRelation(relationField, entity, this.entities.get(referredEntity), entity);
                removeDeferredRelationsFromFirstEntity(entity, referredEntity);
            } else {
                this.deferredGroupedRelationKeyEntities.compute(referredEntity, (key, value) -> {
                    if (value == null) {
                        value = new ArrayList<>();
                    }
                    value.add(relationField);
                    return value;
                });
            }
        }
    }

    private void removeDeferredRelationsFromFirstEntity(Entity entity, String referredEntity) {
        if (this.deferredRelationKeyEntities.containsKey(entity.getEntityName())) {
            List<RelationField> referredFields =
                    this.deferredRelationKeyEntities.get(entity.getEntityName());
            referredFields.removeIf(field -> field.getContainingEntity().equals(referredEntity));
            if (referredFields.isEmpty()) {
                this.deferredRelationKeyEntities.remove(entity.getEntityName());
            }
        }
        if (this.deferredGroupedRelationKeyEntities.containsKey(entity.getEntityName())) {
            List<GroupedRelationField> referredFields =
                    this.deferredGroupedRelationKeyEntities.get(entity.getEntityName());
            referredFields.removeIf(field -> field.getContainingEntity().equals(referredEntity));
            if (referredFields.isEmpty()) {
                this.deferredGroupedRelationKeyEntities.remove(entity.getEntityName());
            }
        }
    }

    private void validateRelation(RelationField processingField, Entity processingEntity, Entity referredEntity,
                                  Entity reportDiagnosticsEntity) {
        String processingEntityName = processingField.getContainingEntity();
        RelationField referredField =
                referredEntity.getRelationFields().get(processingEntityName);
        if (referredField != null) {
            validateRelationType(processingField, processingEntity, referredField, referredEntity,
                    reportDiagnosticsEntity);
            return;
        }

        GroupedRelationField groupedRelationField =
                referredEntity.getGroupedRelationFields().get(processingEntityName);
        if (groupedRelationField != null) {
            RelationField firstRelationMatch = groupedRelationField.getRelationFields().get(0);
            validateRelationType(processingField, processingEntity, firstRelationMatch, referredEntity,
                    reportDiagnosticsEntity);
            for (int i = 1; i < groupedRelationField.getRelationFields().size(); i++) {
                reportMandatoryCorrespondingFieldDiagnostic(groupedRelationField.getRelationFields().get(i),
                        processingEntity, reportDiagnosticsEntity);
            }
            return;
        }
        reportMandatoryCorrespondingFieldDiagnostic(processingField, referredEntity, reportDiagnosticsEntity);
    }

    private void validateGroupedRelation(GroupedRelationField processingField, Entity processingEntity,
                                         Entity referredEntity, Entity reportDiagnosticsEntity) {
        String processingEntityName = processingField.getContainingEntity();
        GroupedRelationField groupedRelationField =
                referredEntity.getGroupedRelationFields().get(processingEntityName);
        List<RelationField> processingRelationFields = processingField.getRelationFields();
        if (groupedRelationField != null) {
            List<RelationField> referredRelationFields = groupedRelationField.getRelationFields();
            int processingFieldSize = processingRelationFields.size();
            int relatedFieldSize = referredRelationFields.size();
            int minCount = Math.min(processingFieldSize, relatedFieldSize);
            for (int i = 0; i < minCount; i++) {
                RelationField processingRelationField = processingRelationFields.get(i);
                RelationField relatedRelationField = referredRelationFields.get(i);
                validateRelationType(processingRelationField, processingEntity, relatedRelationField,
                        referredEntity, reportDiagnosticsEntity);
            }
            if (processingFieldSize < relatedFieldSize) {
                for (int i = processingFieldSize; i < groupedRelationField.getRelationFields().size(); i++) {
                    reportMandatoryCorrespondingFieldDiagnostic(groupedRelationField.getRelationFields().get(i),
                            processingEntity, reportDiagnosticsEntity);
                }
            } else if (processingFieldSize > relatedFieldSize) {
                for (int i = relatedFieldSize; i < processingField.getRelationFields().size(); i++) {
                    reportMandatoryCorrespondingFieldDiagnostic(processingField.getRelationFields().get(i),
                            referredEntity, reportDiagnosticsEntity);
                }
            } else {
                // processingFieldSize == relatedFieldSize
                // Validate all relations have same owner
                boolean isOwnerIdentifiable = processingRelationFields.stream()
                        .allMatch((RelationField::isOwnerIdentifiable));
                if (!isOwnerIdentifiable) {
                    return;
                }
                long processingFieldOwnerCount = processingRelationFields.stream()
                        .filter((field -> field.getOwner().equals(processingEntity.getEntityName()))).count();
                if (processingFieldOwnerCount == 0 || processingFieldOwnerCount == processingFieldSize) {
                    return;
                }

                // If processing field is chosen as the owner.
                List<DiagnosticProperty<?>> processingFieldDiagProperties = new ArrayList<>();
                processingFieldDiagProperties.add(new BStringProperty(processingEntityName));

                // If referred field is chosen as the owner.
                List<DiagnosticProperty<?>> referredFieldDiagProperties = new ArrayList<>();
                referredFieldDiagProperties.add(new BStringProperty(referredEntity.getEntityName()));

                for (int i = 0; i < processingFieldSize; i++) {
                    RelationField processingRelationField = processingRelationFields.get(i);
                    RelationField referredRelationField = referredRelationFields.get(i);
                    if (processingRelationField.getOwner().equals(processingEntityName)) {
                        updateSameOwnerDiagnosticProperties(processingRelationField.getRelationType(),
                                referredFieldDiagProperties, referredRelationField,
                                processingRelationField);
                    } else {
                        updateSameOwnerDiagnosticProperties(processingRelationField.getRelationType(),
                                processingFieldDiagProperties, processingRelationField,
                                referredRelationField);
                    }
                }

                for (int i = 0; i < processingFieldSize; i++) {
                    reportDiagnosticsForDifferentOwners(reportDiagnosticsEntity, processingRelationFields.get(i),
                            processingFieldDiagProperties, referredFieldDiagProperties);
                    reportDiagnosticsForDifferentOwners(reportDiagnosticsEntity, referredRelationFields.get(i),
                            processingFieldDiagProperties, referredFieldDiagProperties);
                }
            }
            return;
        }

        RelationField referredField = referredEntity.getRelationFields().get(processingEntityName);
        if (referredField != null) {
            validateRelationType(processingRelationFields.get(0), processingEntity, referredField,
                    referredEntity, reportDiagnosticsEntity);
            for (int i = 1; i < processingField.getRelationFields().size(); i++) {
                reportMandatoryCorrespondingFieldDiagnostic(processingField.getRelationFields().get(i), referredEntity,
                        reportDiagnosticsEntity);
            }
            return;
        }
        for (int i = 0; i < processingField.getRelationFields().size(); i++) {
            reportMandatoryCorrespondingFieldDiagnostic(processingField.getRelationFields().get(i), referredEntity,
                    reportDiagnosticsEntity);
        }
    }

    private void updateSameOwnerDiagnosticProperties(RelationType relationType,
                                                     List<DiagnosticProperty<?>> referredFieldDiagProperties,
                                                     RelationField removeField, RelationField addField) {
        if (relationType.equals(ONE_TO_ONE)) {
            referredFieldDiagProperties.add(new BNumericProperty(removeField.getNullableStartOffset()));
            referredFieldDiagProperties.add(new BNumericProperty(1));
            referredFieldDiagProperties.add(new BNumericProperty(addField.getTypeEndOffset()));
            referredFieldDiagProperties.add(new BStringProperty("?"));
        } else {
            referredFieldDiagProperties.add(new BNumericProperty(removeField.getArrayStartOffset()));
            referredFieldDiagProperties.add(new BNumericProperty(removeField.getArrayRangeLength()));
            referredFieldDiagProperties.add(new BNumericProperty(addField.getTypeEndOffset()));
            referredFieldDiagProperties.add(new BStringProperty("[]"));
        }
    }

    private void reportDiagnosticsForDifferentOwners(Entity reportDiagnosticsEntity, RelationField relationField,
                                                     List<DiagnosticProperty<?>> processingFieldProperties,
                                                     List<DiagnosticProperty<?>> referredFieldProperties) {
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_403.getCode(), PERSIST_403.getMessage(),
                PERSIST_403.getSeverity(), relationField.getLocation());
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_004.getCode(), PERSIST_004.getMessage(),
                PERSIST_004.getSeverity(), relationField.getLocation(),
                processingFieldProperties);
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_004.getCode(), PERSIST_004.getMessage(),
                PERSIST_004.getSeverity(), relationField.getLocation(),
                referredFieldProperties);
    }

    private void validateRelationType(RelationField processingField, Entity processingEntity,
                                      RelationField referredField, Entity referredEntity,
                                      Entity reportDiagnosticsEntity) {
        // 1:1 relations
        if (!processingField.isArrayType() && !referredField.isArrayType()) {
            if (!processingField.isOptionalType() && !referredField.isOptionalType()) {
                reportOwnerUnidentifiableDiagnotics(reportDiagnosticsEntity, processingField.getLocation(),
                        processingField, referredField);
                reportOwnerUnidentifiableDiagnotics(reportDiagnosticsEntity, referredField.getLocation(),
                        processingField, referredField);
            } else if (processingField.isOptionalType() && referredField.isOptionalType()) {
                reportTwoNillableFieldInOneToOneRelation(reportDiagnosticsEntity, processingField.getLocation(),
                        processingField, referredField);
                reportTwoNillableFieldInOneToOneRelation(reportDiagnosticsEntity, referredField.getLocation(),
                        processingField, referredField);
            } else {
                processingField.setRelationType(ONE_TO_ONE);
                processingField.setOwnerIdentifiable(true);
                processingField.setOwner(processingField.isOptionalType() ?
                        referredEntity.getEntityName() : processingEntity.getEntityName());
                if (processingField.isOptionalType()) {
                    validatePresenceOfForeignKey(referredField, referredEntity, processingEntity,
                            reportDiagnosticsEntity);
                } else {
                    validatePresenceOfForeignKey(processingField, processingEntity, referredEntity,
                            reportDiagnosticsEntity);
                }
            }
            return;
        }

        // n:m relations
        if (processingField.isArrayType() && referredField.isArrayType()) {
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_420.getCode(),
                    MessageFormat.format(PERSIST_420.getMessage(), referredEntity.getEntityName()),
                    PERSIST_420.getSeverity(), processingField.getLocation());
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_420.getCode(),
                    MessageFormat.format(PERSIST_420.getMessage(), referredEntity.getEntityName()),
                    PERSIST_420.getSeverity(), referredField.getLocation());
            processingField.setOwnerIdentifiable(false);
            processingField.setRelationType(MANY_TO_MANY);
            return;
        }

        // 1:n relations
        boolean isProcessingFiledNillable = validateNillableTypeFor1ToMany(processingField, reportDiagnosticsEntity);
        boolean isReferredFieldNillable = validateNillableTypeFor1ToMany(referredField, reportDiagnosticsEntity);
        // This is to reduce confusion in code actions. If type is nillable how do we switch for owner change,
        // Should nillable value also be taken or not
        if (!isProcessingFiledNillable && !isReferredFieldNillable) {
            processingField.setRelationType(ONE_TO_MANY);
            processingField.setOwnerIdentifiable(true);
            processingField.setOwner(processingField.isArrayType() ?
                    referredEntity.getEntityName() : processingEntity.getEntityName()
            );
        }
        if (!processingField.isArrayType()) {
            validatePresenceOfForeignKey(processingField, processingEntity, referredEntity, reportDiagnosticsEntity);
        } else {
            validatePresenceOfForeignKey(referredField, referredEntity, processingEntity, reportDiagnosticsEntity);
        }
    }

    private void reportTwoNillableFieldInOneToOneRelation(Entity reportDiagnosticsEntity, NodeLocation location,
                                                          RelationField processingField, RelationField referredField) {
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_405.getCode(), PERSIST_405.getMessage(),
                PERSIST_405.getSeverity(), location);
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_003.getCode(), PERSIST_003.getMessage(),
                PERSIST_003.getSeverity(), location,
                List.of(new BNumericProperty(processingField.getNullableStartOffset()),
                        new BNumericProperty(1),
                        new BStringProperty(processingField.getContainingEntity() + "." +
                                processingField.getName())));
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_003.getCode(), PERSIST_003.getMessage(),
                PERSIST_003.getSeverity(), location,
                List.of(new BNumericProperty(referredField.getNullableStartOffset()),
                        new BNumericProperty(1),
                        new BStringProperty(referredField.getContainingEntity() + "." +
                                referredField.getName())));
    }

    private void reportOwnerUnidentifiableDiagnotics(Entity reportDiagnosticsEntity, NodeLocation location,
                                                     RelationField processingField, RelationField referredField) {
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_404.getCode(), PERSIST_404.getMessage(),
                PERSIST_404.getSeverity(), location);

        String codeActionTitle = "Make ''{0}'' entity relation owner";
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_002.getCode(), PERSIST_002.getMessage(),
                PERSIST_002.getSeverity(), location,
                List.of(new BNumericProperty(referredField.getTypeEndOffset()),
                        new BStringProperty(MessageFormat.format(codeActionTitle,
                                processingField.getContainingEntity())),
                        new BStringProperty("?")));
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_002.getCode(), PERSIST_002.getMessage(),
                PERSIST_002.getSeverity(), location,
                List.of(new BNumericProperty(processingField.getTypeEndOffset()),
                        new BStringProperty(MessageFormat.format(codeActionTitle,
                                referredField.getContainingEntity())),
                        new BStringProperty("?")));
    }

    private void reportMandatoryCorrespondingFieldDiagnostic(RelationField relationField, Entity missingFieldEntity,
                                                             Entity reportDiagnosticsEntity) {
        NodeList<Node> fields = missingFieldEntity.getTypeDescriptorNode().fields();
        ArrayList<String> fieldNames = new ArrayList<>();
        for (Node field : fields) {
            String fieldName = ((RecordFieldNode) field).fieldName().text();
            fieldNames.add(fieldName);
        }
        Node lastField = fields.get(fields.size() - 1);
        int addFieldLocation = lastField.location().textRange().endOffset();
        reportDiagnosticsEntity.reportDiagnostic(PERSIST_402.getCode(),
                MessageFormat.format(PERSIST_402.getMessage(), missingFieldEntity.getEntityName()),
                PERSIST_402.getSeverity(), relationField.getLocation());

        String codeActionTitle = "Add corresponding{0}relation field in ''" + missingFieldEntity.getEntityName()
                + "'' entity";
        if (!relationField.isArrayType() && !relationField.isOptionalType()) {
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_005.getCode(), PERSIST_005.getMessage(),
                    PERSIST_005.getSeverity(), relationField.getLocation(), List.of(
                            new BNumericProperty(addFieldLocation),
                            new BStringProperty(MessageFormat.format(codeActionTitle, " 1-1 ")),
                            new BStringProperty(MessageFormat.format(LS + "\t{0}? {1};",
                                    relationField.getContainingEntity(),
                                    getFieldName(relationField.getContainingEntity(), fieldNames)

                            ))));
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_005.getCode(), PERSIST_005.getMessage(),
                    PERSIST_005.getSeverity(), relationField.getLocation(), List.of(
                            new BNumericProperty(addFieldLocation),
                            new BStringProperty(MessageFormat.format(codeActionTitle, " 1-n ")),
                            new BStringProperty(MessageFormat.format(LS + "\t{0}[] {1};",
                                    relationField.getContainingEntity(),
                                    getFieldName(relationField.getContainingEntity(), fieldNames)
                            ))));
        } else {
            // Field Type: EntityType? EntityType[]
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_005.getCode(), PERSIST_005.getMessage(),
                    PERSIST_005.getSeverity(), relationField.getLocation(), List.of(
                            new BNumericProperty(addFieldLocation),
                            new BStringProperty(MessageFormat.format(codeActionTitle, " ")),
                            new BStringProperty(MessageFormat.format(LS + "\t{0} {1};",
                                    relationField.getContainingEntity(),
                                    getFieldName(relationField.getContainingEntity(), fieldNames)
                            ))));
        }
    }

    private boolean validateNillableTypeFor1ToMany(RelationField field, Entity reportDiagnosticsEntity) {
        if (field.isOptionalType()) {
            String type = field.isArrayType() ? field.getType() + "[]" : field.getType();
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_406.getCode(), PERSIST_406.getMessage(),
                    PERSIST_406.getSeverity(), field.getLocation(),
                    List.of(new BNumericProperty(field.getNullableStartOffset()),
                            new BNumericProperty(1), new BStringProperty(type)));
            return true;
        }
        return false;
    }

    private void validatePresenceOfForeignKey(RelationField ownerRelationField, Entity owner, Entity referredEntity,
                                              Entity reportDiagnosticsEntity) {
        for (String identityField : referredEntity.getIdentityFieldNames()) {
            String foreignKey = ownerRelationField.getName().toLowerCase(Locale.ENGLISH) +
                    identityField.substring(0, 1).toUpperCase(Locale.ENGLISH) + identityField.substring(1);
            owner.getNonRelationFields().stream().
                    filter(field -> field.getName().equals(foreignKey))
                    .findFirst()
                    .ifPresent(field -> validateRelationAnnotationFieldName
                            (field, reportDiagnosticsEntity, foreignKey, referredEntity,
                                    ownerRelationField));
        }
    }

    private void validateRelationAnnotationFieldName(SimpleTypeField field, Entity reportDiagnosticsEntity,
                                            String foreignKey, Entity referredEntity,
                                            RelationField ownerRelationField) {
        List<String> references = readStringArrayValueFromAnnotation
                (ownerRelationField.getAnnotations(), Constants.SQL_RELATION_MAPPING_ANNOTATION_NAME,
                        ANNOTATION_REFS_FIELD);
        if (references == null || !references.contains(field.getName())) {
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_422.getCode(), MessageFormat.format(
                            PERSIST_422.getMessage(), foreignKey, referredEntity.getEntityName()),
                    PERSIST_422.getSeverity(), field.getNodeLocation());
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
