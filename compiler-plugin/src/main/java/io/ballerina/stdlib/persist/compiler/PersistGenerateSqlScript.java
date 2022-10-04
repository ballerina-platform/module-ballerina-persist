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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ArrayTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.BuiltinSimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.OptionalTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.RecordFieldNode;
import io.ballerina.compiler.syntax.tree.RecordFieldWithDefaultValueNode;
import io.ballerina.compiler.syntax.tree.RecordTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Location;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Sql script generator.
 */
public class PersistGenerateSqlScript {

    private static final String NEW_LINE = System.lineSeparator();
    private static final String TAB = "\t";
    private static final String EMPTY = "";
    private static final String PRIMARY_KEY_START_SCRIPT = NEW_LINE + TAB + "PRIMARY KEY(";
    private static final String UNIQUE_KEY_START_SCRIPT = NEW_LINE + TAB + "UNIQUE KEY(";
    private static final String UNIQUE = " UNIQUE";
    private static final String DIAGNOSTIC = "Diagnostic";
    public static final String ON_DELETE = "onDelete";
    public static final String ON_DELETE_SYNTAX = " ON DELETE";
    public static final String ON_UPDATE_SYNTAX = " ON UPDATE";
    public static final String RESTRICT = "persist:RESTRICT";
    public static final String CASCADE = "persist:CASCADE";
    public static final String SET_NULL = "persist:SET_NULL";
    public static final String NO_ACTION = "persist:NO_ACTION";
    public static final String RESTRICT_SYNTAX = " RESTRICT";
    public static final String CASCADE_SYNTAX = " CASCADE";
    public static final String NO_ACTION_SYNTAX = " NO ACTION";
    public static final String SET_NULL_SYNTAX = " SET NULL";
    public static final String SET_DEFAULT_SYNTAX = " SET DEFAULT";
    public static final String TRUE = "true";
    public static final String FALSE = "false";

    protected static void generateSqlScript(RecordTypeDescriptorNode recordNode, TypeDefinitionNode typeDefinitionNode,
                                            String tableName, NodeList<ModuleMemberDeclarationNode> memberNodes,
                                            List<String> primaryKeys, List<List<String>> uniqueConstraints,
                                            SyntaxNodeAnalysisContext ctx, HashMap<String,
            List<String>> referenceTables, List<String> tableNamesInScript) {
        String recordName = typeDefinitionNode.typeName().text();
        if (tableName.isEmpty()) {
            tableName = recordName;
        }
        String sqlScript = generateTableQuery(tableName);
        String fieldsQuery = generateFieldsQuery(recordNode, tableName, memberNodes, primaryKeys, uniqueConstraints,
                ctx, referenceTables, recordName);
        if (!fieldsQuery.equals(DIAGNOSTIC)) {
            sqlScript = sqlScript + fieldsQuery;
            createSqFile(sqlScript, ctx, recordNode.location(), tableName, referenceTables, tableNamesInScript);
        }
    }

    private static String generateTableQuery(String tableName) {
        return MessageFormat.format("DROP TABLE IF EXISTS {0};{1}CREATE TABLE {0} (", tableName, NEW_LINE);
    }

    private static String generateFieldsQuery(RecordTypeDescriptorNode recordNode, String tableName,
                                              NodeList<ModuleMemberDeclarationNode> memberNodes,
                                              List<String> primaryKeys, List<List<String>> uniqueConstraints,
                                              SyntaxNodeAnalysisContext ctx,
                                              HashMap<String, List<String>> referenceTables, String recordName) {
        NodeList<Node> fields = recordNode.fields();
        String type;
        String end = NEW_LINE + ");";
        Node node;
        Optional<MetadataNode> metadata;
        String fieldName;
        String sqlScript = EMPTY;
        for (Node field : fields) {
            String tableAssociationType = "";
            String length = Constants.VARCHAR_LENGTH;
            String notNull = Constants.NOT_NULL;
            String startValue = EMPTY;
            String referenceTableName = "";
            String fieldType;
            boolean isArrayType = false;
            boolean isUserDefinedType = false;
            String hasRelationAnnotation = FALSE;
            if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
                startValue = fieldNode.expression().toSourceCode().trim();
                fieldType = fieldNode.typeName().toString();
            } else {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                if (fieldNode.questionMarkToken().isPresent()) {
                    notNull = EMPTY;
                }
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
                fieldType = fieldNode.typeName().toString();
            }
            String autoIncrement = EMPTY;
            if (node instanceof OptionalTypeDescriptorNode) {
                Node typeNode = ((OptionalTypeDescriptorNode) node).typeDescriptor();
                if (typeNode instanceof SimpleNameReferenceNode) {
                    SimpleNameReferenceNode simpleNameReferenceNode = (SimpleNameReferenceNode) typeNode;
                    type = simpleNameReferenceNode.name().text().trim();
                } else {
                    type = getType(typeNode.toSourceCode().trim());
                }
                notNull = EMPTY;
            } else if (node instanceof QualifiedNameReferenceNode) {
                type = getType(((QualifiedNameReferenceNode) node).identifier().text());
            } else if (node instanceof SimpleNameReferenceNode) {
                isUserDefinedType = true;
                type = ((SimpleNameReferenceNode) node).name().text();
                String[] properties = checkRelationShip(memberNodes, recordName, type);
                if (properties.length == 0) {
                    tableAssociationType = Constants.ONE_TO_ONE;
                    referenceTableName = type;
                    hasRelationAnnotation = FALSE;
                } else {
                    tableAssociationType = properties[1];
                    referenceTableName = properties[0];
                    hasRelationAnnotation = properties[2];
                }
            } else if (node instanceof ArrayTypeDescriptorNode) {
                isUserDefinedType = true;
                isArrayType = true;
                type = ((ArrayTypeDescriptorNode) node).memberTypeDesc().toString().trim();
                String[] properties = checkRelationShip(memberNodes, recordName, type);
                if (properties.length == 0) {
                    Utils.reportDiagnostic(ctx, field.location(), DiagnosticsCodes.PERSIST_115.getCode(),
                            MessageFormat.format(DiagnosticsCodes.PERSIST_115.getMessage(), type),
                            DiagnosticsCodes.PERSIST_115.getSeverity());
                    return DIAGNOSTIC;
                } else {
                    tableAssociationType = properties[1];
                    referenceTableName = properties[0];
                    hasRelationAnnotation = properties[2];
                }
                if (tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                    tableAssociationType = Constants.ONE_TO_MANY;
                } else if (tableAssociationType.equals(Constants.ONE_TO_MANY)) {
                    Utils.reportDiagnostic(ctx, field.location(), DiagnosticsCodes.PERSIST_114.getCode(),
                            DiagnosticsCodes.PERSIST_114.getMessage(), DiagnosticsCodes.PERSIST_114.getSeverity());
                    return DIAGNOSTIC;
                }
            } else {
                type = getType(((BuiltinSimpleNameReferenceNode) node).name().text());
            }
            String relationScript = EMPTY;
            if (metadata.isPresent()) {
                for (AnnotationNode annotationNode : metadata.get().annotations()) {
                    String annotationName = annotationNode.annotReference().toSourceCode().trim();
                    if (fieldType.trim().equals(Constants.BallerinaTypes.STRING) &&
                            annotationName.equals(Constants.CONSTRAINT_STRING)) {
                        length = processConstraintAnnotations(annotationNode);
                    }
                    if (annotationName.equals(Constants.AUTO_INCREMENT)) {
                        autoIncrement = Constants.AUTO_INCREMENT_WITH_SPACE;
                        startValue = processAutoIncrementAnnotations(annotationNode, startValue, ctx);
                        if (!startValue.isEmpty() && Integer.parseInt(startValue) > 1) {
                            end = MessageFormat.format("{0}){1} = {2};", NEW_LINE,
                                    Constants.AUTO_INCREMENT_WITH_TAB, startValue);
                        }
                    }
                    if (annotationName.equals(Constants.RELATION)) {
                        if (hasRelationAnnotation.equals(TRUE)) {
                            Utils.reportDiagnostic(ctx, annotationNode.location(),
                                    DiagnosticsCodes.PERSIST_116.getCode(), DiagnosticsCodes.PERSIST_116.getMessage(),
                                    DiagnosticsCodes.PERSIST_116.getSeverity());
                            return DIAGNOSTIC;
                        }
                        if (isArrayType || !isUserDefinedType) {
                            Utils.reportDiagnostic(ctx, annotationNode.location(),
                                    DiagnosticsCodes.PERSIST_117.getCode(), DiagnosticsCodes.PERSIST_117.getMessage(),
                                    DiagnosticsCodes.PERSIST_117.getSeverity());
                            return DIAGNOSTIC;
                        }
                        updateReferenceTable(tableName, referenceTableName, referenceTables);
                        relationScript = processRelationAnnotation(annotationNode, type, tableName, memberNodes,
                                referenceTableName, tableAssociationType);
                    }
                }
            }
            fieldName = eliminateSingleQuote(fieldName);
            if (relationScript.isEmpty() && tableAssociationType.equals("")) {
                if (type.equals(Constants.SqlTypes.VARCHAR)) {
                    type = type.concat("(" + length + ")"); // Add varchar length
                }
                sqlScript = MessageFormat.format("{0}{1}{2}{3} {4}{5}{6},", sqlScript, NEW_LINE, TAB,
                        fieldName, type, notNull, autoIncrement);
            } else if (!relationScript.isEmpty()) {
                sqlScript = sqlScript.concat(relationScript);
            }
        }
        sqlScript = sqlScript + addPrimaryKeyUniqueKey(primaryKeys, uniqueConstraints);
        return MessageFormat.format("{0}{1}", sqlScript.substring(0, sqlScript.length() - 1) , end);
    }

    private static String[] checkRelationShip(NodeList<ModuleMemberDeclarationNode> memberNodes, String recordName,
                                              String referenceRecordName) {
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
            Optional<MetadataNode> entityMetadata = typeDefinitionNode.metadata();
            if (entityMetadata.isPresent()) {
                NodeList<AnnotationNode> annotations = entityMetadata.get().annotations();
                for (AnnotationNode annotation: annotations) {
                    if (!annotation.annotReference().toSourceCode().trim().equals(Constants.ENTITY)) {
                        continue;
                    }
                    Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                            annotation.annotValue();
                    if (mappingConstructorExpressionNode.isPresent()) {
                        SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().fields();
                        for (MappingFieldNode mappingFieldNode : fields) {
                            SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                            String name = fieldNode.fieldName().toSourceCode().trim().
                                    replaceAll(Constants.UNNECESSARY_CHARS_REGEX, "");
                            Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                            if (expressionNode.isPresent()) {
                                if (name.equals(Constants.TABLE_NAME)) {
                                    referenceRecordName =
                                            Utils.eliminateDoubleQuotes(expressionNode.get().toSourceCode().trim());
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
                    RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) recordField;
                    fieldType = recordFieldNode.typeName().toSourceCode().trim();
                    Optional<MetadataNode> metaData = recordFieldNode.metadata();
                    if (metaData.isPresent()) {
                        relationAnnotation = checkRelationAnnotation(metaData.get());
                    }
                }
                if (fieldType.contains(recordName)) {
                    if (fieldType.endsWith("]")) {
                        return new String[]{referenceRecordName, Constants.ONE_TO_MANY, relationAnnotation};
                    } else {
                        return new String[]{referenceRecordName, Constants.ONE_TO_ONE, relationAnnotation};
                    }
                }
            }
        }
        return new String[]{};
    }

    private static String checkRelationAnnotation(MetadataNode metadataNode) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            if (annotation.annotReference().toSourceCode().trim().equals(Constants.RELATION)) {
                return TRUE;
            }
        }
        return FALSE;
    }

    private static String processConstraintAnnotations(AnnotationNode annotationNode) {
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        String length = Constants.VARCHAR_LENGTH;
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                String fieldName = specificFieldNode.fieldName().toSourceCode().trim();
                if (fieldName.equals(Constants.MAX_LENGTH)) {
                    Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                    if (valueExpr.isPresent()) {
                        return valueExpr.get().toSourceCode().trim();
                    }
                } else if (fieldName.equals(Constants.LENGTH)) {
                    Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                    if (valueExpr.isPresent()) {
                        return valueExpr.get().toSourceCode().trim();
                    }
                }
            }
        }
        return length;
    }

    private static void updateReferenceTable(String tableName, String referenceTableName,
                                             HashMap<String, List<String>> referenceTables) {
        List<String> setOfReferenceTables;
        if (referenceTables.containsKey(referenceTableName)) {
            setOfReferenceTables = referenceTables.get(referenceTableName);
        } else {
            setOfReferenceTables = new ArrayList<>();
        }
        setOfReferenceTables.add(tableName);
        referenceTables.put(referenceTableName, setOfReferenceTables);
    }

    private static String eliminateSingleQuote(String fieldName) {
        if (fieldName.startsWith("'")) {
            return fieldName.substring(1);
        }
        return fieldName;
    }

    private static String addPrimaryKeyUniqueKey(List<String> primaryKeys, List<List<String>> uniqueConstraints) {
        String primaryKeyScript = PRIMARY_KEY_START_SCRIPT;
        String uniqueKeyScript = UNIQUE_KEY_START_SCRIPT;
        String stringFormat = "{0}{1}, ";
        String script = EMPTY;
        for (String primaryKey : primaryKeys) {
            primaryKeyScript = MessageFormat.format(stringFormat, primaryKeyScript, primaryKey);
        }
        if (!primaryKeyScript.equals(PRIMARY_KEY_START_SCRIPT)) {
            script = primaryKeyScript.substring(0, primaryKeyScript.length() - 2).concat("),");
        }
        for (List<String> uniqueConstraint :uniqueConstraints) {
            for (String unique : uniqueConstraint) {
                uniqueKeyScript = MessageFormat.format(stringFormat, uniqueKeyScript, unique);
            }
            if (!uniqueKeyScript.equals(UNIQUE_KEY_START_SCRIPT)) {
                script = script.concat(uniqueKeyScript.substring(0, uniqueKeyScript.length() - 2).concat("),"));
            }
            uniqueKeyScript = UNIQUE_KEY_START_SCRIPT;
        }
        return script;
    }

    private static String processAutoIncrementAnnotations(AnnotationNode annotationNode, String startValue,
                                                          SyntaxNodeAnalysisContext ctx) {
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                if (startValue.isEmpty() || Integer.parseInt(startValue) < 1) {
                    if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.START_VALUE)) {
                        Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                        if (valueExpr.isPresent()) {
                            startValue =  valueExpr.get().toSourceCode().trim();
                        }
                    }
                }
                // todo mysql doesn't support increment. So, set the warning.
                //  some db support this, So, need to improve this properly.
                if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.INCREMENT)) {
                    Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                    if (valueExpr.isPresent()) {
                        if (!valueExpr.get().toSourceCode().trim().equals(Constants.ONE)) {
                            Utils.reportDiagnostic(ctx, specificFieldNode.location(),
                                    DiagnosticsCodes.PERSIST_112.getCode(),
                                    DiagnosticsCodes.PERSIST_112.getMessage(),
                                    DiagnosticsCodes.PERSIST_112.getSeverity());
                        }
                    }

                }
            }
        }
        return startValue;
    }

    private static String processRelationAnnotation(AnnotationNode annotationNode, String fieldType, String tableName,
                                                    NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                    String referenceTableName, String relationshipType) {
        String delete = EMPTY;
        String update = EMPTY;
        StringBuilder relationScript = new StringBuilder(EMPTY);
        ListConstructorExpressionNode foreignKeys = null;
        ListConstructorExpressionNode reference = null;
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.KEY_COLUMNS)) {
                    Optional<ExpressionNode> node = specificFieldNode.valueExpr();
                    if (node.isPresent()) {
                        foreignKeys = (ListConstructorExpressionNode) node.get();
                    }
                } else if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.REFERENCE)) {
                    Optional<ExpressionNode> node = specificFieldNode.valueExpr();
                    if (node.isPresent()) {
                        reference = (ListConstructorExpressionNode) node.get();
                    }
                } else if (specificFieldNode.fieldName().toSourceCode().trim().equals(ON_DELETE)) {
                    Optional<ExpressionNode> optional = specificFieldNode.valueExpr();
                    if (optional.isPresent()) {
                        delete = ON_DELETE_SYNTAX + getReferenceAction(optional.get().toSourceCode().trim());
                    }
                } else {
                    Optional<ExpressionNode> optional = specificFieldNode.valueExpr();
                    if (optional.isPresent()) {
                        update = ON_UPDATE_SYNTAX + getReferenceAction(optional.get().toSourceCode().trim());
                    }
                }
            }
            if ((foreignKeys != null && reference != null) &&
                    !(foreignKeys.expressions().size() == 0 && reference.expressions().size() == 0)) {
                SeparatedNodeList<Node> referenceValueNode = reference.expressions();
                int i = 0;
                for (Node node : foreignKeys.expressions()) {
                    String referenceKey = Utils.eliminateDoubleQuotes(referenceValueNode.get(i).toSourceCode().trim());
                    String foreignKeyType = getForeignKeyType(memberNodes, referenceKey, fieldType,
                            foreignKeys.expressions().size(), relationshipType);
                    relationScript = new StringBuilder(relationScript.toString().concat(
                            constructForeignKeyScript(Utils.eliminateDoubleQuotes(node.toSourceCode().trim()),
                                    foreignKeyType, tableName, referenceTableName, String.valueOf(i), referenceKey,
                                    delete, update)));
                    i++;
                }
            } else {
                List<List<String>> referenceInfo;
                String referenceKey;
                String foreignKeyType;
                String foreignKey;
                if (reference != null && reference.expressions().size() != 0) {
                    referenceKey = Utils.eliminateDoubleQuotes(reference.expressions().get(0).toSourceCode().trim());
                    foreignKey = fieldType.toLowerCase(Locale.ENGLISH) +
                            referenceKey.substring(0, 1).toUpperCase(Locale.ENGLISH) +
                            referenceKey.substring(1);
                    foreignKeyType = getForeignKeyType(memberNodes, referenceKey, fieldType,
                            reference.expressions().size(), relationshipType);
                    relationScript.append(constructForeignKeyScript(foreignKey,
                            foreignKeyType, tableName, referenceTableName, "0", referenceKey, delete, update));
                } else if (foreignKeys != null && foreignKeys.expressions().size() != 0) {
                    foreignKey = Utils.eliminateDoubleQuotes(foreignKeys.expressions().get(0).toSourceCode().trim());
                    referenceInfo = getReferenceKeyAndType(memberNodes, fieldType,
                            foreignKeys.expressions().size(), relationshipType);
                    relationScript.append(constructForeignKeyScript(foreignKey,
                            referenceInfo.get(1).get(0), tableName, referenceTableName, "0",
                            referenceInfo.get(0).get(0), delete, update));
                } else {
                    referenceInfo = getReferenceKeyAndType(memberNodes, fieldType, 1,
                            relationshipType);
                    String referenceKeyName = referenceInfo.get(0).get(0);
                    String referenceType = referenceInfo.get(1).get(0);
                    foreignKey = fieldType.toLowerCase(Locale.ENGLISH) +
                            referenceKeyName.substring(0, 1).toUpperCase(Locale.ENGLISH) +
                            referenceKeyName.substring(1);
                        relationScript.append(constructForeignKeyScript(foreignKey,
                                referenceType, tableName, referenceTableName, String.valueOf(0),
                                referenceKeyName, delete, update));
                }
            }
        }
        return relationScript.toString();
    }

    private static String getReferenceAction(String value) {
        switch (value) {
            case RESTRICT:
                return RESTRICT_SYNTAX;
            case CASCADE:
                return CASCADE_SYNTAX;
            case NO_ACTION:
                return NO_ACTION_SYNTAX;
            case SET_NULL:
                return SET_NULL_SYNTAX;
            default:
                return SET_DEFAULT_SYNTAX;
        }
    }

    private static String constructForeignKeyScript(String fieldName, String fieldType, String tableName,
                                                    String referenceTableName,
                                                    String value, String referenceKey, String delete, String update) {
        String sqlType = fieldType;
        if (fieldType.trim().equals(Constants.BallerinaTypes.STRING)) {
            sqlType = Constants.SqlTypes.VARCHAR + "(" + Constants.VARCHAR_LENGTH + ")";
        }
        return MessageFormat.format("{10}{11}{0} {1},{10}{11}CONSTRAINT " +
                        "FK_{2}_{3}_{4} FOREIGN KEY({5}) REFERENCES {6}({7}){8}{9},", fieldName, sqlType,
                tableName.toUpperCase(Locale.ENGLISH), referenceTableName.toUpperCase(Locale.ENGLISH), value, fieldName,
                referenceTableName, referenceKey, delete, update, NEW_LINE, TAB);
    }

    private static List<List<String>> getReferenceKeyAndType(NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                             String referenceTableName, int noOfForeignKeys,
                                                             String tableAssociationType) {
        List<String> primaryKeys = new ArrayList<>();
        List<List<String>> uniqueConstraints = new ArrayList<>();
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (!(memberNode instanceof TypeDefinitionNode)) {
                continue;
            }
            TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
            Node typeDescriptor = typeDefinitionNode.typeDescriptor();
            if (!(typeDescriptor instanceof RecordTypeDescriptorNode)) {
                continue;
            }
            if (!(typeDefinitionNode.typeName().text().equals(referenceTableName))) {
                continue;
            }
            Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
            if (metadata.isEmpty()) {
                continue;
            }
            for (AnnotationNode annotation : metadata.get().annotations()) {
                if (!(annotation.annotReference().toSourceCode().trim().equals(Constants.ENTITY))) {
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
                        } else {
                            listConstructorExpressionNode =
                                    (ListConstructorExpressionNode) expression;
                            SeparatedNodeList<Node> exps = listConstructorExpressionNode.
                                    expressions();
                            List<String> uniqueConstraint = new ArrayList<>();
                            for (Node exp : exps) {
                                if (exp instanceof BasicLiteralNode) {
                                    uniqueConstraint.add(Utils.
                                            eliminateDoubleQuotes(
                                                    exp.toSourceCode().trim()));
                                }
                            }
                            uniqueConstraints.add(uniqueConstraint);
                        }
                    }
                }
            }
        }

        List<List<String>> referenceInfo;
        if (primaryKeys.size() > 0 || uniqueConstraints.size() > 0) {
            if (primaryKeys.size() == 1 || uniqueConstraints.size() == 1) {
                referenceInfo = getInfoFromSinglePrimaryOrUniqueKeys(memberNodes, referenceTableName, primaryKeys,
                        uniqueConstraints, noOfForeignKeys, tableAssociationType);
            } else {
                referenceInfo = getInfoFromCompositePrimaryOrUniqueKeys(referenceTableName, memberNodes, primaryKeys,
                        uniqueConstraints);
            }
            if (referenceInfo != null) {
                return referenceInfo;
            }
        }
        referenceInfo = getInfoFromIntOrStringTypeField(memberNodes, referenceTableName);
        return referenceInfo;
    }

    private static List<List<String>> getInfoFromSinglePrimaryOrUniqueKeys (
            NodeList<ModuleMemberDeclarationNode> memberNodes, String referenceTableName, List<String> primaryKeys,
            List<List<String>> uniqueConstraints, int noOfForeignKeys, String tableAssociationType) {
        List<List<String>> referenceInfo = new ArrayList<>();
        List<String> referenceKeys = new ArrayList<>();
        List<String> referenceTypes = new ArrayList<>();
        String referenceKey = EMPTY;
        if (primaryKeys.size() == 1) {
            referenceKey = primaryKeys.get(0);
            referenceKeys.add(referenceKey);
        } else if (uniqueConstraints.size() == 1 && uniqueConstraints.get(0).size() == 1) {
            referenceKey = uniqueConstraints.get(0).get(0);
            referenceKeys.add(referenceKey);
        }
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
            if (!typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                continue;
            }
            Optional<MetadataNode>  entityMetadata = typeDefinitionNode.metadata();
            if (entityMetadata.isEmpty()) {
                continue;
            }
            String unique = "";
            if (noOfForeignKeys == 1 && tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                unique = getUniqueKeyword(entityMetadata.get(), referenceKey);
            }
            for (Node recordField : recordTypeDescriptor.fields()) {
                if (referenceKey.isEmpty()) {
                    continue;
                }
                String fieldType;
                NodeList<AnnotationNode> annotations = null;
                if (recordField instanceof RecordFieldNode) {
                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        fieldType = recordFieldNode.typeName().toSourceCode().trim();
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        fieldType = getForeignKeyFieldType(annotations, fieldType) + unique;
                        referenceTypes.add(fieldType);
                        referenceInfo.add(referenceKeys);
                        referenceInfo.add(referenceTypes);
                        return referenceInfo;
                    }
                } else {
                    RecordFieldWithDefaultValueNode recordFieldNode =
                            (RecordFieldWithDefaultValueNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        fieldType = recordFieldNode.typeName().toSourceCode().trim();
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        fieldType = getForeignKeyFieldType(annotations, fieldType) + unique;
                        referenceTypes.add(fieldType);
                        referenceInfo.add(referenceKeys);
                        referenceInfo.add(referenceTypes);
                        return referenceInfo;
                    }
                }
            }
        }
        return null;
    }

    private static List<List<String>> getInfoFromCompositePrimaryOrUniqueKeys(String referenceTableName,
                                                                              NodeList<ModuleMemberDeclarationNode>
                                                                                      memberNodes,
                                                                              List<String> primaryKeys,
                                                                              List<List<String>> uniqueConstraints) {
        List<List<String>> referenceInfo = new ArrayList<>();
        List<String> referenceKeys = new ArrayList<>();
        List<String> referenceTypes = new ArrayList<>();
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
            if (!typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                for (Node recordField : recordTypeDescriptor.fields()) {
                    if (primaryKeys.size() > 1) {
                        String fieldType;
                        NodeList<AnnotationNode> annotations = null;
                        if (recordField instanceof RecordFieldNode) {
                            RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                            if (!primaryKeys.contains(recordFieldNode.fieldName().text())) {
                                continue;
                            }
                            referenceKeys.add(recordField.toSourceCode().trim());
                            fieldType = recordFieldNode.typeName().toSourceCode().trim();
                            Optional<MetadataNode> metadata = recordFieldNode.metadata();
                            if (metadata.isPresent()) {
                                annotations = metadata.get().annotations();
                            }
                        } else {
                            RecordFieldWithDefaultValueNode recordFieldNode =
                                    (RecordFieldWithDefaultValueNode) recordField;
                            fieldType = recordFieldNode.typeName().toSourceCode().trim();
                            if (primaryKeys.contains(recordFieldNode.fieldName().text())) {
                                referenceKeys.add(recordField.toSourceCode().trim());
                                Optional<MetadataNode> metadata = recordFieldNode.metadata();
                                if (metadata.isPresent()) {
                                    annotations = metadata.get().annotations();
                                }
                            }
                        }
                        fieldType = getForeignKeyFieldType(annotations, fieldType);
                        referenceTypes.add(fieldType);
                    } else if (uniqueConstraints.size() > 1) {
                        String fieldType;
                        NodeList<AnnotationNode> annotations = null;
                        List<String> uniqueConstraint = uniqueConstraints.get(0);
                        if (recordField instanceof RecordFieldNode) {
                            RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                            if (uniqueConstraint.contains(recordFieldNode.fieldName().text())) {
                                referenceKeys.add(recordField.toSourceCode().trim());
                                fieldType = recordFieldNode.typeName().toSourceCode().trim();
                                Optional<MetadataNode> metadata = recordFieldNode.metadata();
                                if (metadata.isPresent()) {
                                    annotations = metadata.get().annotations();
                                }
                                fieldType = getForeignKeyFieldType(annotations, fieldType);
                                referenceTypes.add(fieldType);
                            }
                        } else {
                            RecordFieldWithDefaultValueNode recordFieldNode =
                                    (RecordFieldWithDefaultValueNode) recordField;
                            if (uniqueConstraint.contains(recordFieldNode.fieldName().text())) {
                                referenceKeys.add(recordField.toSourceCode().trim());
                                fieldType = recordFieldNode.typeName().toSourceCode().trim();
                                Optional<MetadataNode> metadata = recordFieldNode.metadata();
                                if (metadata.isPresent()) {
                                    annotations = metadata.get().annotations();
                                }
                                fieldType = getForeignKeyFieldType(annotations, fieldType);
                                referenceTypes.add(fieldType);
                            }
                        }
                    }
                }
            }
        }
        if (referenceKeys.size() > 0) {
            referenceInfo.add(referenceKeys);
            referenceInfo.add(referenceTypes);
            return referenceInfo;
        }
        return null;
    }

    private static List<List<String>> getInfoFromIntOrStringTypeField(NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                                      String referenceTableName) {
        List<List<String>> referenceInfo = new ArrayList<>();
        List<String> referenceKeys = new ArrayList<>();
        List<String> referenceTypes = new ArrayList<>();
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
            if (!typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                continue;
            }
            for (Node recordField : recordTypeDescriptor.fields()) {
                String fieldType;
                NodeList<AnnotationNode> annotations = null;
                if (recordField instanceof RecordFieldNode) {
                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                    fieldType = recordFieldNode.typeName().toSourceCode().trim();
                    if (fieldType.equals(Constants.BallerinaTypes.INT) ||
                            fieldType.equals(Constants.BallerinaTypes.STRING)) {
                        referenceKeys.add(recordFieldNode.fieldName().toSourceCode().trim());
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        fieldType = getForeignKeyFieldType(annotations, fieldType);
                        referenceTypes.add(fieldType);
                        referenceInfo.add(referenceKeys);
                        referenceInfo.add(referenceTypes);
                        return referenceInfo;
                    }
                } else {
                    RecordFieldWithDefaultValueNode recordFieldNode =
                            (RecordFieldWithDefaultValueNode) recordField;
                    fieldType = recordFieldNode.typeName().toSourceCode().trim();
                    if (fieldType.equals(Constants.BallerinaTypes.INT) ||
                            fieldType.equals(Constants.BallerinaTypes.STRING)) {
                        referenceKeys.add(recordFieldNode.fieldName().toSourceCode().trim());
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        fieldType = getForeignKeyFieldType(annotations, fieldType);
                        referenceTypes.add(fieldType);
                        referenceInfo.add(referenceKeys);
                        referenceInfo.add(referenceTypes);
                        return referenceInfo;
                    }
                }
            }
        }
        return null;
    }

    private static String getForeignKeyType(NodeList<ModuleMemberDeclarationNode> memberNodes, String referenceKey,
                                            String typeName, int noOfForeignKeys, String tableAssociationType) {
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
            if (!typeDefinitionNode.typeName().text().equals(typeName)) {
                continue;
            }
            Optional<MetadataNode>  entityMetadata = typeDefinitionNode.metadata();
            if (entityMetadata.isEmpty()) {
                continue;
            }
            String unique = "";
            if (noOfForeignKeys == 1 && tableAssociationType.equals(Constants.ONE_TO_ONE)) {
                unique = getUniqueKeyword(entityMetadata.get(), referenceKey);
            }
            for (Node recordField : recordTypeDescriptor.fields()) {
                String fieldType;
                NodeList<AnnotationNode> annotations = null;
                if (recordField instanceof RecordFieldNode) {
                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        fieldType = recordFieldNode.typeName().toSourceCode().trim();
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        return getForeignKeyFieldType(annotations, fieldType) + unique;
                    }
                } else {
                    RecordFieldWithDefaultValueNode recordFieldNode = (RecordFieldWithDefaultValueNode) recordField;
                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                        fieldType = recordFieldNode.typeName().toSourceCode().trim();
                        Optional<MetadataNode> metadata = recordFieldNode.metadata();
                        if (metadata.isPresent()) {
                            annotations = metadata.get().annotations();
                        }
                        return getForeignKeyFieldType(annotations, fieldType) + unique;
                    }
                }
            }
        }
        return EMPTY;
    }

    private static String getUniqueKeyword(MetadataNode metadataNode, String referenceKey) {
        for (AnnotationNode annotationNode : metadataNode.annotations()) {
            String annotationName = annotationNode.annotReference().toSourceCode().trim();
            if (annotationName.equals(Constants.ENTITY)) {
                Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                        annotationNode.annotValue();
                if (mappingConstructorExpressionNode.isPresent()) {
                    SeparatedNodeList<MappingFieldNode> fields = mappingConstructorExpressionNode.get().fields();
                    for (MappingFieldNode mappingFieldNode : fields) {
                        SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                        String name = fieldNode.fieldName().toSourceCode().trim().
                                replaceAll(Constants.UNNECESSARY_CHARS_REGEX, "");
                        if (name.equals(Constants.KEY)) {
                            Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                            if (expressionNode.isPresent()) {
                                ListConstructorExpressionNode listConstructorExpressionNode =
                                        (ListConstructorExpressionNode) expressionNode.get();
                                SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                                for (Node expression : expressions) {
                                    if (expression instanceof BasicLiteralNode &&
                                            Utils.eliminateDoubleQuotes(expression.toSourceCode().trim()).
                                                    equals(referenceKey)) {
                                        return UNIQUE;
                                    }
                                }
                            }
                        }
                        if (name.equals(Constants.UNIQUE_CONSTRAINTS)) {
                            Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                            if (expressionNode.isPresent()) {
                                ListConstructorExpressionNode listConstructorExpressionNode =
                                        (ListConstructorExpressionNode) expressionNode.get();
                                SeparatedNodeList<Node> expressions = listConstructorExpressionNode.expressions();
                                if (expressions.size() == 1) {
                                    listConstructorExpressionNode = (ListConstructorExpressionNode) expressions.get(0);
                                    if (listConstructorExpressionNode.expressions().size() == 1) {
                                        return UNIQUE;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return "";
    }

    private static String getForeignKeyFieldType(NodeList<AnnotationNode> annotations, String fieldType) {
        if (annotations != null) {
            for (AnnotationNode annotationNode : annotations) {
                String annotationName = annotationNode.annotReference().toSourceCode().trim();
                if (annotationName.equals(Constants.CONSTRAINT_STRING) &&
                        fieldType.trim().equals(Constants.BallerinaTypes.STRING)) {
                    return Constants.SqlTypes.VARCHAR + "(" + processConstraintAnnotations(annotationNode) + ")";
                }
            }
        }
        String type = getType(fieldType);
        if (type.equals(Constants.SqlTypes.VARCHAR)) {
            type = type.concat("(" + Constants.VARCHAR_LENGTH + ")");
        }
        return type;
    }

    private static String getType(String type) {
        switch (type) {
            case Constants.BallerinaTypes.INT:
                return Constants.SqlTypes.INT;
            case Constants.BallerinaTypes.BOOLEAN:
                return Constants.SqlTypes.BOOLEAN;
            case Constants.BallerinaTypes.DECIMAL:
                return Constants.SqlTypes.DECIMAL;
            case Constants.BallerinaTypes.FLOAT:
                return Constants.SqlTypes.FLOAT;
            case Constants.BallerinaTypes.DATE:
                return Constants.SqlTypes.DATE;
            case Constants.BallerinaTypes.TIME_OF_DAY:
                return Constants.SqlTypes.TIME;
            case Constants.BallerinaTypes.UTC:
                return Constants.SqlTypes.TIME_STAMP;
            case Constants.BallerinaTypes.CIVIL:
                return Constants.SqlTypes.DATE_TIME;
            default:
                return Constants.SqlTypes.VARCHAR;
        }
    }

    private static void createSqFile(String script, SyntaxNodeAnalysisContext ctx, Location location,
                                     String tableName, HashMap<String, List<String>> referenceTables,
                                     List<String> tableNamesInScript) {
        try {
            String content = EMPTY;
            Path directoryPath = ctx.currentPackage().project().targetDir().toAbsolutePath();
            Path filePath = Paths.get(String.valueOf(directoryPath), Constants.FILE_NAME);
            if (Files.exists(filePath)) {
                byte[] bytes = Files.readAllBytes(filePath);
                content = new String(bytes, StandardCharsets.UTF_8);
                String tableNames = "";
                int firstIndex = 0;
                if (referenceTables.containsKey(tableName)) {
                    List<String> tables = referenceTables.get(tableName);
                    for (String table : tables) {
                        String name = table + ";";
                        int index = content.indexOf(name);
                        if ((firstIndex == 0 || index < firstIndex) && index > 1) {
                            tableNames = name;
                            firstIndex = index;
                        }
                    }
                    int index = firstIndex + tableNames.length();
                    content = content.substring(0, index) + NEW_LINE + NEW_LINE + script + NEW_LINE +
                            content.substring(index);
                } else {
                    int firstIndexOfScript = 0;
                    for (String table :tableNamesInScript) {
                        if (referenceTables.containsKey(table)) {
                            int index = script.indexOf(tableName);
                            if ((firstIndexOfScript == 0 || index < firstIndexOfScript) && index > 1) {
                                firstIndexOfScript = index;
                            }
                        }
                    }
                    if (firstIndexOfScript > 0) {
                        int index = firstIndexOfScript + tableName.length() + 1;
                        content = script.substring(0, index) + NEW_LINE + NEW_LINE + content + NEW_LINE +
                                script.substring(index);
                    } else {
                        script = script.concat(NEW_LINE + NEW_LINE);
                        content = script.concat(content);
                    }
                }
            } else {
                if (Files.notExists(directoryPath)) {
                    Files.createDirectories(directoryPath);
                }
                content = content.concat(script);
            }
            Files.writeString(filePath, content);
            tableNamesInScript.add(tableName);
        } catch (IOException e) {
            Utils.reportDiagnostic(ctx, location, DiagnosticsCodes.PERSIST_110.getCode(),
                    "error in read or write a script file: " + e.getMessage(),
                    DiagnosticsCodes.PERSIST_110.getSeverity());
        }
    }
}
