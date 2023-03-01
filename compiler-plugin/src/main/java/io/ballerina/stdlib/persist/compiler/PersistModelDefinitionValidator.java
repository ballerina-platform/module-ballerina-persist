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
import io.ballerina.stdlib.persist.compiler.model.IdentityField;
import io.ballerina.stdlib.persist.compiler.model.RelationField;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BNumericProperty;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BStringProperty;

import java.io.File;
import java.nio.file.Path;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

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
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_201;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_202;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_301;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_302;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_303;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_304;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_305;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_307;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_401;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_402;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_403;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_420;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_421;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_422;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_501;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_502;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.Utils.stripEscapeCharacter;

/**
 * Persist model definition validator.
 */
public class PersistModelDefinitionValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Map<String, Entity> entities = new HashMap<>();
    private final List<String> entityNames = new ArrayList<>();
    private final Map<String, List<RelationField>> deferredRelationKeyEntities = new HashMap<>();

    @Override
    public void perform(SyntaxNodeAnalysisContext ctx) {
        if (!isPersistModelDefinitionDocument(ctx)) {
            return;
        }

        if (Utils.hasCompilationErrors(ctx)) {
            return;
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
            }
            ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                    new DiagnosticInfo(PERSIST_101.getCode(), PERSIST_101.getMessage(), PERSIST_101.getSeverity()),
                    member.location()));
        }

        for (TypeDefinitionNode typeDefinitionNode : foundEntities) {
            String entityName = stripEscapeCharacter(typeDefinitionNode.typeName().text().trim());
            TypeDescriptorNode typeDescriptorNode = (TypeDescriptorNode) typeDefinitionNode.typeDescriptor();

            Entity entity = new Entity(entityName, typeDefinitionNode.typeName().location(),
                    ((RecordTypeDescriptorNode) typeDescriptorNode));
            validateEntityRecordProperties(entity);
            validateEntityFields(entity);
            validateIdentityFields(entity);
            validateEntityRelations(entity);

            if (this.deferredRelationKeyEntities.containsKey(entityName)) {
                List<RelationField> annotatedFields = this.deferredRelationKeyEntities.get(entityName);
                for (RelationField field : annotatedFields) {
                    validateRelation(field, this.entities.get(field.getContainingEntity()), entity, entity);
                }
            }

            entity.getDiagnostics().forEach((ctx::reportDiagnostic));
            this.entities.put(entityName, entity);
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

    private void validateEntityFields(Entity entity) {
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

            if (fieldNames.contains(fieldName.toLowerCase(Locale.ROOT))) {
                entity.reportDiagnostic(PERSIST_307.getCode(),
                        MessageFormat.format(PERSIST_307.getMessage(), fieldName), PERSIST_307.getSeverity(),
                        recordFieldNode.fieldName().location());
                continue;
            }
            fieldNames.add(fieldName.toLowerCase(Locale.ROOT));

            // Check if optional field
            if (recordFieldNode.questionMarkToken().isPresent()) {
                int startOffset = recordFieldNode.questionMarkToken().get().textRange().startOffset();
                int length = recordFieldNode.semicolonToken().textRange().startOffset() - startOffset;
                entity.reportDiagnostic(PERSIST_304.getCode(), PERSIST_304.getMessage(), PERSIST_304.getSeverity(),
                        recordFieldNode.location(),
                        List.of(new BNumericProperty(startOffset), new BNumericProperty(length)));
            }

            Node typeNode = recordFieldNode.typeName();
            Node processedTypeNode = typeNode;
            String typeNamePostfix = "";
            boolean isArrayType = false;
            boolean isOptionalType = false;
            boolean isValidType = false;
            int nullableStartOffset = 0;
            String identityFieldType;
            if (processedTypeNode instanceof OptionalTypeDescriptorNode) {
                isOptionalType = true;
                OptionalTypeDescriptorNode optionalTypeNode = (OptionalTypeDescriptorNode) processedTypeNode;
                processedTypeNode = optionalTypeNode.typeDescriptor();
                nullableStartOffset = optionalTypeNode.questionMarkToken().textRange().startOffset();
            }
            if (processedTypeNode instanceof ArrayTypeDescriptorNode) {
                isArrayType = true;
                ArrayTypeDescriptorNode arrayTypeDescriptorNode = ((ArrayTypeDescriptorNode) processedTypeNode);
                processedTypeNode = arrayTypeDescriptorNode.memberTypeDesc();
                typeNamePostfix = SyntaxKind.OPEN_BRACKET_TOKEN.stringValue() +
                        SyntaxKind.CLOSE_BRACKET_TOKEN.stringValue();
            }

            if (processedTypeNode instanceof BuiltinSimpleNameReferenceNode) {
                String type = ((BuiltinSimpleNameReferenceNode) processedTypeNode).name().text();
                identityFieldType = type;
                isValidType = validateSimpleTypes(entity, typeNode, typeNamePostfix, isArrayType, type);
                entity.addNonRelationField(stripEscapeCharacter(recordFieldNode.fieldName().text().trim()),
                        recordFieldNode.location());
            } else if (processedTypeNode instanceof QualifiedNameReferenceNode) {
                // Support only time constructs
                QualifiedNameReferenceNode qualifiedName = (QualifiedNameReferenceNode) processedTypeNode;
                String modulePrefix = stripEscapeCharacter(qualifiedName.modulePrefix().text());
                String identifier = stripEscapeCharacter(qualifiedName.identifier().text());
                identityFieldType = modulePrefix + ":" + identifier;
                if (isValidImportedType(modulePrefix, identifier)) {
                    if (isArrayType) {
                        entity.reportDiagnostic(PERSIST_306.getCode(),
                                MessageFormat.format(PERSIST_306.getMessage(), modulePrefix + ":" + identifier),
                                PERSIST_306.getSeverity(), typeNode.location());
                    } else {
                        isValidType = true;
                    }
                } else {
                    entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                                    modulePrefix + ":" + identifier + typeNamePostfix), PERSIST_305.getSeverity(),
                            typeNode.location());
                }
                entity.addNonRelationField(stripEscapeCharacter(recordFieldNode.fieldName().text().trim()),
                        recordFieldNode.location());
            } else if (processedTypeNode instanceof SimpleNameReferenceNode) {
                String typeName = stripEscapeCharacter(
                        ((SimpleNameReferenceNode) processedTypeNode).name().text().trim());
                identityFieldType = typeName;
                if (this.entityNames.contains(typeName)) {
                    // Remove once optional associations are supported
                    if (isOptionalType) {
                        entity.reportDiagnostic(PERSIST_421.getCode(), PERSIST_421.getMessage(),
                                PERSIST_421.getSeverity(), typeNode.location());
                    }
                    isValidType = true;
                    entity.setContainsRelations(true);
                    entity.addRelationField(new RelationField(typeName, isArrayType, recordFieldNode.location(),
                            entity.getEntityName()));
                    // Revisit once https://github.com/ballerina-platform/ballerina-lang/issues/39441 is resolved
                } else {
                    isValidType = validateSimpleTypes(entity, typeNode, typeNamePostfix, isArrayType, typeName);
                }
            } else {
                String typeName = Utils.getTypeName(processedTypeNode);
                identityFieldType = typeName;
                entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                                typeName), PERSIST_305.getSeverity(),
                        typeNode.location());
            }
            if (isIdentityField) {
                identityField.setType(identityFieldType);
                identityField.setValidType(isValidType);
                identityField.setNullable(isOptionalType);
                identityField.setNullableStartOffset(nullableStartOffset);
                identityField.setReadonlyTextRangeStartOffset(readonlyTextRangeStartOffset);
                identityField.setTypeLocation(typeNode.location());
                entity.addIdentityField(identityField);
            }
        }
    }

    private boolean validateSimpleTypes(Entity entity, Node typeNode, String typeNamePostfix,
                                        boolean isArrayType, String type) {
        if (isValidSimpleType(type)) {
            if (isArrayType) {
                entity.reportDiagnostic(PERSIST_306.getCode(),
                        MessageFormat.format(PERSIST_306.getMessage(), type),
                        PERSIST_306.getSeverity(), typeNode.location());
                return false;
            }
        } else if (!(type.equals(BYTE) && isArrayType)) {
            entity.reportDiagnostic(PERSIST_305.getCode(), MessageFormat.format(PERSIST_305.getMessage(),
                            type + typeNamePostfix), PERSIST_305.getSeverity(),
                    typeNode.location());
            return false;
        }
        return true;
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

    private void validateIdentityFields(Entity entity) {
        if (entity.getIdentityFields().isEmpty()) {
            entity.reportDiagnostic(PERSIST_501.getCode(), MessageFormat.format(PERSIST_501.getMessage(),
                    entity.getEntityName()), PERSIST_501.getSeverity(), entity.getEntityNameLocation());
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

        List<String> validRelationTypes = new ArrayList<>();
        for (RelationField relationField : entity.getRelationFields()) {
            String referredEntity = relationField.getType();

            if (relationField.getType().equals(relationField.getContainingEntity())) {
                entity.reportDiagnostic(PERSIST_401.getCode(), PERSIST_401.getMessage(),
                        PERSIST_401.getSeverity(), relationField.getLocation());
                break;
            }

            // Duplicated Relations
            if (validRelationTypes.contains(relationField.getType())) {
                entity.reportDiagnostic(PERSIST_403.getCode(),
                        MessageFormat.format(PERSIST_403.getMessage(), relationField.getType()),
                        PERSIST_403.getSeverity(), relationField.getLocation());
                break;
            }

            validRelationTypes.add(relationField.getType());

            if (this.entities.containsKey(referredEntity)) {
                validateRelation(relationField, entity, this.entities.get(referredEntity), entity);
                if (this.deferredRelationKeyEntities.containsKey(entity.getEntityName())) {
                    List<RelationField> referredFields = this.deferredRelationKeyEntities.get(entity.getEntityName());
                    referredFields.removeIf(field -> field.getContainingEntity().equals(referredEntity));
                    if (referredFields.isEmpty()) {
                        this.deferredRelationKeyEntities.remove(entity.getEntityName());
                    }
                }
            } else {
                if (this.deferredRelationKeyEntities.containsKey(referredEntity)) {
                    this.deferredRelationKeyEntities.get(referredEntity).add(relationField);
                } else {
                    List<RelationField> references = new ArrayList<>();
                    references.add(relationField);
                    this.deferredRelationKeyEntities.put(referredEntity, references);
                }
            }
        }
    }

    private void validateRelation(RelationField processingField, Entity processingEntity, Entity referredEntity,
                                  Entity reportDiagnosticsEntity) {

        RelationField referredField = null;
        for (RelationField relationField : referredEntity.getRelationFields()) {
            if (processingField.getContainingEntity().equals(relationField.getType())) {
                referredField = relationField;
                break;
            }
        }

        if (referredField == null) {
            NodeList<Node> fields = referredEntity.getTypeDescriptorNode().fields();
            Node lastField = fields.get(fields.size() - 1);
            int addFieldLocation = lastField.location().textRange().endOffset();
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_402.getCode(),
                    MessageFormat.format(PERSIST_402.getMessage(), referredEntity.getEntityName(),
                            processingField.getContainingEntity()), PERSIST_402.getSeverity(),
                    processingField.getLocation(), List.of(new BNumericProperty(addFieldLocation),
                            new BStringProperty(processingField.getContainingEntity()),
                            new BStringProperty(referredEntity.getEntityName())));
            return;
        }

        // 1:1 relations
        if (!processingField.isArrayType() && !referredField.isArrayType()) {
            // Processing second entity
            if (processingEntity.getEntityName().equals(reportDiagnosticsEntity.getEntityName())) {
                validatePresenceOfForeignKey(referredEntity, processingEntity, reportDiagnosticsEntity);
            } else {
                validatePresenceOfForeignKey(processingEntity, referredEntity, reportDiagnosticsEntity);
            }
            return;
        }

        // n:m relations
        if (processingField.isArrayType() && referredField.isArrayType()) {
            reportDiagnosticsEntity.reportDiagnostic(PERSIST_420.getCode(),
                    MessageFormat.format(PERSIST_420.getMessage(), referredEntity.getEntityName()),
                    PERSIST_420.getSeverity(), processingField.getLocation());
            return;
        }

        // 1:n relations
        if (!processingField.isArrayType()) {
            validatePresenceOfForeignKey(processingEntity, referredEntity, reportDiagnosticsEntity);
        } else {
            validatePresenceOfForeignKey(referredEntity, processingEntity, reportDiagnosticsEntity);
        }
    }

    private void validatePresenceOfForeignKey(Entity parentEntity, Entity childEntity,
                                              Entity reportDiagnosticsEntity) {
        for (String identityField : childEntity.getIdentityFieldNames()) {
            String foreignKey = childEntity.getEntityName().toLowerCase(Locale.ENGLISH) +
                    identityField.substring(0, 1).toUpperCase(Locale.ENGLISH) + identityField.substring(1);
            NodeLocation foreignKeyFieldLocation = parentEntity.getNonRelationFields().get(foreignKey);
            if (foreignKeyFieldLocation != null) {
                reportDiagnosticsEntity.reportDiagnostic(PERSIST_422.getCode(),
                        MessageFormat.format(PERSIST_422.getMessage(), foreignKey, childEntity.getEntityName()),
                        PERSIST_422.getSeverity(), foreignKeyFieldLocation);
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
