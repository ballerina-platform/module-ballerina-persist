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
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.MessageFormat;
import java.util.List;
import java.util.Optional;

/**
 * Sql script generator.
 */
public class PersistGenerateSqlScript {

    private static final String NEW_LINE = "\n";
    private static final String TAB = "\t";
    private static final String PRIMARY_KEY_START_SCRIPT = NEW_LINE + TAB + "PRIMARY KEY(";
    private static final String UNIQUE_KEY_START_SCRIPT = NEW_LINE + TAB + "UNIQUE KEY(";
    protected static void generateSqlScript(RecordTypeDescriptorNode recordNode, TypeDefinitionNode typeDefinitionNode,
                                            String tableName, NodeList<ModuleMemberDeclarationNode> memberNodes,
                                            List<String> primaryKeys, List<List<String>> uniqueConstraints,
                                            SyntaxNodeAnalysisContext ctx) {
        String sqlScript = generateTableQuery(tableName, typeDefinitionNode);
        sqlScript = sqlScript + generateFieldsQuery(recordNode, tableName, memberNodes, primaryKeys, uniqueConstraints);
        createSqFile(sqlScript, ctx, recordNode.location());
    }

    private static String generateTableQuery(String tableName, TypeDefinitionNode typeDefinitionNode) {
        if (tableName.isEmpty()) {
            tableName = typeDefinitionNode.typeName().text();
        }
        return MessageFormat.format("DROP TABLE IF EXISTS {0};{1}CREATE TABLE {0} (", tableName, NEW_LINE);
    }

    private static String generateFieldsQuery(RecordTypeDescriptorNode recordNode, String tableName,
                                              NodeList<ModuleMemberDeclarationNode> memberNodes,
                                              List<String> primaryKeys, List<List<String>> uniqueConstraints) {
        NodeList<Node> fields = recordNode.fields();
        String type;
        String end = NEW_LINE + ");";
        Node node;
        Optional<MetadataNode> metadata;
        String fieldName;
        String sqlScript = "";
        for (Node field : fields) {
            String startValue = "";
            if (field instanceof RecordFieldWithDefaultValueNode) {
                RecordFieldWithDefaultValueNode fieldNode = (RecordFieldWithDefaultValueNode) field;
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
                startValue = fieldNode.expression().toSourceCode().trim();
            } else {
                RecordFieldNode fieldNode = (RecordFieldNode) field;
                node = fieldNode.typeName();
                metadata = fieldNode.metadata();
                fieldName = fieldNode.fieldName().text();
            }
            String notNull = "NOT NULL";
            String autoIncrement = "";
            if (node instanceof OptionalTypeDescriptorNode) {
                Node typeNode = ((OptionalTypeDescriptorNode) node).typeDescriptor();
                if (typeNode instanceof SimpleNameReferenceNode) {
                    SimpleNameReferenceNode simpleNameReferenceNode = (SimpleNameReferenceNode) typeNode;
                    type = simpleNameReferenceNode.name().text().trim();
                } else {
                    type = getType(typeNode.toSourceCode().trim());
                }
                notNull = "";
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
            String relationScript = "";
            if (metadata.isPresent()) {
                for (AnnotationNode annotationNode : metadata.get().annotations()) {
                    String annotationName = annotationNode.annotReference().toSourceCode().trim();
                    if (annotationName.equals(Constants.PER_AUTO_INCREMENT)) {
                        autoIncrement = "AUTO_INCREMENT";
                        if (startValue.isEmpty() || Integer.parseInt(startValue) < 1) {
                            startValue = processAutoIncrementAnnotations(annotationNode);
                        }
                        if (!startValue.isEmpty() && !startValue.equals(Constants.ONE)) {
                            end = MessageFormat.format("{0}) {1} = {2};", NEW_LINE, autoIncrement, startValue);
                        }
                    } else if (annotationName.equals(Constants.RELATION)) {
                        relationScript = processRelationAnnotation(annotationNode, type, tableName, memberNodes, type);
                    }
                }
            }
            if (relationScript.isEmpty()) {
                sqlScript = MessageFormat.format("{0} {1}{2}{3} {4} {5} {6},", sqlScript, NEW_LINE, TAB,
                        fieldName, type, notNull, autoIncrement);
            } else {
                sqlScript = sqlScript.concat(relationScript);
            }
        }
        sqlScript = sqlScript + addPrimaryKeyUniqueKey(primaryKeys, uniqueConstraints);
        return MessageFormat.format("{0} {1}", sqlScript.substring(0, sqlScript.length() - 1) , end);
    }

    private static String addPrimaryKeyUniqueKey(List<String> primaryKeys, List<List<String>> uniqueConstraints) {
        String primaryKeyScript = PRIMARY_KEY_START_SCRIPT;
        String uniqueKeyScript = UNIQUE_KEY_START_SCRIPT;
        String stringFormat = "{0}{1}, ";
        String script = "";
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

    private static String processAutoIncrementAnnotations(AnnotationNode annotationNode) {
        Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
        if (annotationFieldNode.isPresent()) {
            for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                if (specificFieldNode.fieldName().toSourceCode().trim().equals(Constants.START_VALUE)) {
                    return specificFieldNode.valueExpr().get().toSourceCode().trim();
                }
            }
        }
        return "";
    }

    private static String processRelationAnnotation(AnnotationNode annotationNode, String fieldType, String tableName,
                                                    NodeList<ModuleMemberDeclarationNode> memberNodes,
                                                    String typeName) {
        String delete = "";
        String update = "";
        String relationScript = "";
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
                    if (optional.isPresent() && optional.get().toSourceCode().trim().equals("true")) {
                        delete = " ON DELETE CASCADE";
                    }
                } else {
                    Optional<ExpressionNode> optional = specificFieldNode.valueExpr();
                    if (optional.isPresent() && optional.get().toSourceCode().trim().equals("true")) {
                        update = " ON UPDATE CASCADE";
                    }
                }
            }
            if (foreignKeys != null && reference != null) {
                SeparatedNodeList<Node> referenceValueNode = reference.expressions();
                int i = 0;
                for (Node node : foreignKeys.expressions()) {
                    String referenceKey = Utils.getValue(referenceValueNode.get(i).toSourceCode().trim());
                    String type = getForeignKeyType(memberNodes, referenceKey, typeName);
                    relationScript = MessageFormat.format("{10}{11}{0} {1}, {10}{11}CONSTRAINT " +
                                    "FK_{2}_{3}_{4} FOREIGN KEY({5}) REFERENCES {6}({7}) {8} {9},",
                            Utils.getValue(node.toSourceCode().trim()), type, tableName, fieldType, String.valueOf(i),
                            Utils.getValue(node.toSourceCode().trim()), fieldType, referenceKey, delete, update,
                            NEW_LINE, TAB);
                    i++;
                }
            }

        }
        return relationScript;
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
                                    return getType(recordFieldNode.typeName().toSourceCode().trim());
                                }
                            } else {
                                RecordFieldWithDefaultValueNode recordFieldNode =
                                        (RecordFieldWithDefaultValueNode) recordField;
                                if (recordFieldNode.fieldName().text().equals(referenceKey)) {
                                    return getType(recordFieldNode.typeName().toSourceCode().trim());
                                }
                            }
                        }
                    }
                }
            }
        }
        return "";
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
            String content = "";
            Path path = Paths.get("target", "sql_script.sql").toAbsolutePath();
            PrintStream asd = System.out;
            asd.println(path);
            if (Files.exists(path)) {
                byte[] bytes = Files.readAllBytes(path);
                content = new String(bytes, StandardCharsets.UTF_8);
                content = content.concat(NEW_LINE + NEW_LINE);
            }
            Files.writeString(path, content.concat(script));
        } catch (IOException e) {
            PrintStream asd = System.out;
            asd.println(e.getMessage());
            asd.println("#################################");
            Utils.reportDiagnosticInfo(ctx, location, DiagnosticsCodes.PERSIST_110.getCode(), e.getMessage(),
                    DiagnosticsCodes.PERSIST_110.getSeverity());
        }
    }
}
