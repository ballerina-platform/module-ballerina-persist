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
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Sql script generator.
 */
public class PersistGenerateSqlScript {

    private static final String NEW_LINE = "\n";
    private static final String TAB = "\t";
    private static final String EMPTY = "";
    private static final String PRIMARY_KEY_START_SCRIPT = NEW_LINE + TAB + "PRIMARY KEY(";
    private static final String UNIQUE_KEY_START_SCRIPT = NEW_LINE + TAB + "UNIQUE KEY(";

    protected static void generateSqlScript(RecordTypeDescriptorNode recordNode, TypeDefinitionNode typeDefinitionNode,
                                            String tableName, NodeList<ModuleMemberDeclarationNode> memberNodes,
                                            List<String> primaryKeys, List<List<String>> uniqueConstraints,
                                            SyntaxNodeAnalysisContext ctx) {
        if (tableName.isEmpty()) {
            tableName = typeDefinitionNode.typeName().text();
        }
        String sqlScript = generateTableQuery(tableName);
        sqlScript = sqlScript + generateFieldsQuery(recordNode, tableName, memberNodes, primaryKeys, uniqueConstraints,
                ctx);
        createSqFile(sqlScript, ctx, recordNode.location());
    }

    private static String generateTableQuery(String tableName) {
        return MessageFormat.format("DROP TABLE IF EXISTS {0};{1}CREATE TABLE {0} (", tableName, NEW_LINE);
    }

    private static String generateFieldsQuery(RecordTypeDescriptorNode recordNode, String tableName,
                                              NodeList<ModuleMemberDeclarationNode> memberNodes,
                                              List<String> primaryKeys, List<List<String>> uniqueConstraints,
                                              SyntaxNodeAnalysisContext ctx) {
        NodeList<Node> fields = recordNode.fields();
        String type;
        String end = NEW_LINE + ");";
        Node node;
        Optional<MetadataNode> metadata;
        String fieldName;
        String sqlScript = EMPTY;
        for (Node field : fields) {
            String notNull = " NOT NULL";
            String startValue = EMPTY;
            if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
                startValue = fieldNode.expression().toSourceCode().trim();
            } else {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                if (fieldNode.questionMarkToken().isPresent()) {
                    notNull = EMPTY;
                }
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
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
                QualifiedNameReferenceNode typeNode = (QualifiedNameReferenceNode) node;
                type = getType(typeNode.identifier().text());
            } else if (node instanceof SimpleNameReferenceNode) {
                SimpleNameReferenceNode typeNode = (SimpleNameReferenceNode) node;
                type = typeNode.name().text();
            } else {
                BuiltinSimpleNameReferenceNode typeNode = (BuiltinSimpleNameReferenceNode) node;
                type = getType(typeNode.name().text());
            }
            String relationScript = EMPTY;
            if (metadata.isPresent()) {
                for (AnnotationNode annotationNode : metadata.get().annotations()) {
                    String annotationName = annotationNode.annotReference().toSourceCode().trim();
                    if (annotationName.equals(Constants.AUTO_INCREMENT)) {
                        autoIncrement = " AUTO_INCREMENT";
                        startValue = processAutoIncrementAnnotations(annotationNode, startValue, ctx);
                        if (!startValue.isEmpty() && Integer.parseInt(startValue) > 1) {
                            end = MessageFormat.format("{0}) {1} = {2};", NEW_LINE, autoIncrement, startValue);
                        }
                    } else if (annotationName.equals(Constants.RELATION)) {
                        relationScript = processRelationAnnotation(annotationNode, type, tableName, memberNodes, type);
                    }
                }
            }
            fieldName = eliminateSingleQuote(fieldName);
            if (relationScript.isEmpty()) {
                sqlScript = MessageFormat.format("{0} {1}{2}{3} {4}{5}{6},", sqlScript, NEW_LINE, TAB,
                        fieldName, type, notNull, autoIncrement);
            } else {
                sqlScript = sqlScript.concat(relationScript);
            }
        }
        sqlScript = sqlScript + addPrimaryKeyUniqueKey(primaryKeys, uniqueConstraints);
        return MessageFormat.format("{0} {1}", sqlScript.substring(0, sqlScript.length() - 1) , end);
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
            if (!uniqueKeyScript.equals(PRIMARY_KEY_START_SCRIPT)) {
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
                            Utils.reportErrorOrWarning(ctx, specificFieldNode.location(),
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
                                                    String referenceTableName) {
        String delete = EMPTY;
        String update = EMPTY;
        String relationScript = EMPTY;
        ListConstructorExpressionNode foreignKeys = null;
        ListConstructorExpressionNode reference = null;
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.KEY)) {
                    Optional<ExpressionNode> node = specificFieldNode.valueExpr();
                    if (node.isPresent()) {
                        foreignKeys = (ListConstructorExpressionNode) node.get();
                    }
                } else if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.REFERENCE)) {
                    Optional<ExpressionNode> node = specificFieldNode.valueExpr();
                    if (node.isPresent()) {
                        reference = (ListConstructorExpressionNode) node.get();
                    }
                } else if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.CASCADE_DELETE)) {
                    Optional<ExpressionNode> optional = specificFieldNode.valueExpr();
                    if (optional.isPresent() && optional.get().toSourceCode().trim().equals(Constants.TRUE)) {
                        delete = " ON DELETE CASCADE";
                    }
                } else {
                    Optional<ExpressionNode> optional = specificFieldNode.valueExpr();
                    if (optional.isPresent() && optional.get().toSourceCode().trim().equals(Constants.TRUE)) {
                        update = " ON UPDATE CASCADE";
                    }
                }
            }
            if ((foreignKeys != null && reference != null) &&
                    !(foreignKeys.expressions().size() == 0 && reference.expressions().size() == 0)) {
                SeparatedNodeList<Node> referenceValueNode = reference.expressions();
                int i = 0;
                for (Node node : foreignKeys.expressions()) {
                    String referenceKey = Utils.getValue(referenceValueNode.get(i).toSourceCode().trim());
                    String foreignKeyType = getForeignKeyType(memberNodes, referenceKey, referenceTableName);
                    relationScript = relationScript.concat(
                            constructForeignKeyScript(Utils.getValue(node.toSourceCode().trim()), foreignKeyType,
                                    tableName, fieldType, String.valueOf(i), referenceKey, delete, update));
                    i++;
                }
            } else { // todo this logic is used to get the missing foreign key and reference key
                List<List<String>> referenceInfo;
                String referenceKey;
                String foreignKeyType;
                String foreignKey;
                if (reference != null && reference.expressions().size() != 0) {
                    referenceKey = Utils.getValue(reference.expressions().get(0).toSourceCode().trim());
                    foreignKey = referenceTableName.toLowerCase(Locale.ENGLISH) +
                            referenceKey.substring(0, 1).toUpperCase(Locale.ENGLISH) +
                            referenceKey.substring(1);
                    foreignKeyType = getForeignKeyType(memberNodes, referenceKey, referenceTableName);
                    relationScript = relationScript + constructForeignKeyScript(foreignKey,
                            foreignKeyType, tableName, fieldType, "0", referenceKey, delete, update);
                } else if (foreignKeys != null && foreignKeys.expressions().size() != 0) {
                    foreignKey = Utils.getValue(foreignKeys.expressions().get(0).toSourceCode().trim());
                    referenceInfo = getReferenceKeyAndType(memberNodes, referenceTableName);
                    relationScript = relationScript + constructForeignKeyScript(foreignKey,
                            referenceInfo.get(1).get(0), tableName, fieldType, "0", referenceInfo.get(0).get(0),
                            delete, update);
                } else {
                    referenceInfo = getReferenceKeyAndType(memberNodes, referenceTableName);
                    List<String> referenceKeys = referenceInfo.get(0);
                    List<String> referenceTypes = referenceInfo.get(1);
                    int i = 0;
                    for (String key : referenceKeys) {
                        foreignKey = referenceTableName.toLowerCase(Locale.ENGLISH) +
                                key.substring(0, 1).toUpperCase(Locale.ENGLISH) + key.substring(1);
                        relationScript = relationScript + constructForeignKeyScript(foreignKey,
                                referenceTypes.get(i), tableName, referenceTableName, String.valueOf(i),
                                key, delete, update);
                        i++;
                    }
                }
            }
        }
        return relationScript;
    }

    private static String constructForeignKeyScript(String fieldName, String fieldType, String tableName,
                                                    String referenceTableName,
                                                    String value, String referenceKey, String delete, String update) {
        return MessageFormat.format("{10}{11}{0} {1}, {10}{11}CONSTRAINT " +
                        "FK_{2}_{3}_{4} FOREIGN KEY({5}) REFERENCES {6}({7}){8}{9},", fieldName, getType(fieldType),
                tableName.toUpperCase(Locale.ENGLISH), referenceTableName.toUpperCase(Locale.ENGLISH), value, fieldName,
                referenceTableName, referenceKey, delete, update, NEW_LINE, TAB);
    }

    private static List<List<String>> getReferenceKeyAndType(NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                             String referenceTableName) {
        List<String> primaryKeys = new ArrayList<>();
        List<List<String>> uniqueConstraints = new ArrayList<>();
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (typeDescriptor instanceof RecordTypeDescriptorNode) {
                    if (typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                        Optional<MetadataNode> metadata = typeDefinitionNode.metadata();
                        if (metadata.isPresent()) {
                            for (AnnotationNode annotation : metadata.get().annotations()) {
                                if (annotation.annotReference().toSourceCode().equals(Constants.ENTITY)) {
                                    Optional<MappingConstructorExpressionNode> mappingConstructorExpressionNode =
                                            annotation.annotValue();
                                    if (mappingConstructorExpressionNode.isPresent()) {
                                        SeparatedNodeList<MappingFieldNode> fields =
                                                mappingConstructorExpressionNode.get().fields();
                                        for (MappingFieldNode mappingFieldNode : fields) {
                                            SpecificFieldNode fieldNode = (SpecificFieldNode) mappingFieldNode;
                                            Optional<ExpressionNode> expressionNode = fieldNode.valueExpr();
                                            if (expressionNode.isPresent() &&
                                                    !fieldNode.fieldName().toSourceCode().trim().
                                                            equals(Constants.TABLE_NAME)) {
                                                ListConstructorExpressionNode listConstructorExpressionNode =
                                                        (ListConstructorExpressionNode) expressionNode.get();
                                                SeparatedNodeList<Node> expressions = listConstructorExpressionNode.
                                                        expressions();
                                                for (Node expression : expressions) {
                                                    if (expression instanceof BasicLiteralNode) {
                                                        primaryKeys.add(Utils.
                                                                getValue(expression.toSourceCode().trim()));
                                                    } else {
                                                        listConstructorExpressionNode =
                                                                (ListConstructorExpressionNode) expression;
                                                        SeparatedNodeList<Node> exps = listConstructorExpressionNode.
                                                                expressions();
                                                        List<String> uniqueConstraint = new ArrayList<>();
                                                        for (Node exp : exps) {
                                                            if (exp instanceof BasicLiteralNode) {
                                                                uniqueConstraint.add(Utils.
                                                                        getValue(exp.toSourceCode().trim()));
                                                            }
                                                        }
                                                        uniqueConstraints.add(uniqueConstraint);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        List<List<String>> referenceInfo;
        if (primaryKeys.size() > 0 || uniqueConstraints.size() > 0) {
            if (primaryKeys.size() == 1 || uniqueConstraints.size() == 1) {
                referenceInfo = getInfoFromSinglePrimaryOrUniqueKeys(memberNodes, referenceTableName, primaryKeys,
                        uniqueConstraints);
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
            List<List<String>> uniqueConstraints) {
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
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (typeDescriptor instanceof RecordTypeDescriptorNode) {
                    RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
                    if (typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                        for (Node recordField : recordTypeDescriptor.fields()) {
                            if (!referenceKey.isEmpty()) {
                                if (recordField instanceof RecordFieldNode) {
                                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                        referenceInfo.add(referenceKeys);
                                        referenceInfo.add(referenceTypes);
                                        return referenceInfo;
                                    }
                                } else {
                                    RecordFieldWithDefaultValueNode recordFieldNode =
                                            (RecordFieldWithDefaultValueNode) recordField;
                                    if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                        referenceInfo.add(referenceKeys);
                                        referenceInfo.add(referenceTypes);
                                        return referenceInfo;
                                    }
                                }
                            }
                        }
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
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (typeDescriptor instanceof RecordTypeDescriptorNode) {
                    RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
                    if (typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                        for (Node recordField : recordTypeDescriptor.fields()) {
                            if (primaryKeys.size() > 1) {
                                if (recordField instanceof RecordFieldNode) {
                                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                                    if (primaryKeys.contains(recordFieldNode.fieldName().text())) {
                                        referenceKeys.add(recordField.toSourceCode().trim());
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                    }
                                } else {
                                    RecordFieldWithDefaultValueNode recordFieldNode =
                                            (RecordFieldWithDefaultValueNode) recordField;
                                    if (primaryKeys.contains(recordFieldNode.fieldName().text())) {
                                        referenceKeys.add(recordField.toSourceCode().trim());
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                    }
                                }
                            } else if (uniqueConstraints.size() > 1) {
                                List<String> uniqueConstraint = uniqueConstraints.get(0);
                                if (recordField instanceof RecordFieldNode) {
                                    RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                                    if (uniqueConstraint.contains(recordFieldNode.fieldName().text())) {
                                        referenceKeys.add(recordField.toSourceCode().trim());
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                    }
                                } else {
                                    RecordFieldWithDefaultValueNode recordFieldNode =
                                            (RecordFieldWithDefaultValueNode) recordField;
                                    if (uniqueConstraint.contains(recordFieldNode.fieldName().text())) {
                                        referenceKeys.add(recordField.toSourceCode().trim());
                                        referenceTypes.add(recordFieldNode.typeName().toSourceCode().trim());
                                    }
                                }
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
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (typeDescriptor instanceof RecordTypeDescriptorNode) {
                    RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
                    if (typeDefinitionNode.typeName().text().equals(referenceTableName)) {
                        for (Node recordField : recordTypeDescriptor.fields()) {
                            if (recordField instanceof RecordFieldNode) {
                                RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                                String recordType = recordFieldNode.typeName().toSourceCode().trim();
                                if (recordType.equals(Constants.BallerinaTypes.INT) ||
                                        recordType.equals(Constants.BallerinaTypes.STRING)) {
                                    referenceKeys.add(recordFieldNode.fieldName().toSourceCode().trim());
                                    referenceTypes.add(recordType);
                                    referenceInfo.add(referenceKeys);
                                    referenceInfo.add(referenceTypes);
                                    return referenceInfo;
                                }
                            } else {
                                RecordFieldWithDefaultValueNode recordFieldNode =
                                        (RecordFieldWithDefaultValueNode) recordField;
                                String recordType = recordFieldNode.typeName().toSourceCode().trim();
                                if (recordType.equals(Constants.BallerinaTypes.INT) ||
                                        recordType.equals(Constants.BallerinaTypes.STRING)) {
                                    referenceKeys.add(recordFieldNode.fieldName().toSourceCode().trim());
                                    referenceTypes.add(recordType);
                                    referenceInfo.add(referenceKeys);
                                    referenceInfo.add(referenceTypes);
                                    return referenceInfo;
                                }

                            }
                        }
                    }
                }
            }
        }
        return null;
    }

    private static String getForeignKeyType(NodeList<ModuleMemberDeclarationNode> memberNodes, String referenceKey,
                                            String typeName) {
        for (ModuleMemberDeclarationNode memberNode : memberNodes) {
            if (memberNode instanceof TypeDefinitionNode) {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                Node typeDescriptor = typeDefinitionNode.typeDescriptor();
                if (typeDescriptor instanceof RecordTypeDescriptorNode) {
                    RecordTypeDescriptorNode recordTypeDescriptor = (RecordTypeDescriptorNode) typeDescriptor;
                    if (typeDefinitionNode.typeName().text().equals(typeName)) {
                        for (Node recordField : recordTypeDescriptor.fields()) {
                            if (recordField instanceof RecordFieldNode) {
                                RecordFieldNode recordFieldNode = (RecordFieldNode) recordField;
                                if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                                    return recordFieldNode.typeName().toSourceCode().trim();
                                }
                            } else {
                                RecordFieldWithDefaultValueNode recordFieldNode =
                                        (RecordFieldWithDefaultValueNode) recordField;
                                if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                                    return recordFieldNode.typeName().toSourceCode().trim();
                                }
                            }
                        }
                    }
                }
            }
        }
        return EMPTY;
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

    private static void createSqFile(String script, SyntaxNodeAnalysisContext ctx, Location location) {
        try {
            String content = EMPTY;
            Path path = Paths.get("target", "persist_db_scripts.sql").toAbsolutePath();
            if (Files.exists(path)) {
                byte[] bytes = Files.readAllBytes(path);
                content = new String(bytes, StandardCharsets.UTF_8);
                content = content.concat(NEW_LINE + NEW_LINE);
            }
            Files.writeString(path, content.concat(script));
        } catch (IOException e) {
            Utils.reportErrorOrWarning(ctx, location, DiagnosticsCodes.PERSIST_110.getCode(),
                    "error in read or write a script file: " + e.getMessage(),
                    DiagnosticsCodes.PERSIST_110.getSeverity());
        }
    }
}
