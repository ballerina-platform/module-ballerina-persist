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

package io.ballerina.stdlib.persist.compiler.utils;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.util.ProjectConstants;
import io.ballerina.stdlib.persist.compiler.BalException;
import io.ballerina.stdlib.persist.compiler.Constants;
import io.ballerina.toml.syntax.tree.DocumentMemberDeclarationNode;
import io.ballerina.toml.syntax.tree.DocumentNode;
import io.ballerina.toml.syntax.tree.KeyValueNode;
import io.ballerina.toml.syntax.tree.NodeList;
import io.ballerina.toml.syntax.tree.SyntaxTree;
import io.ballerina.toml.syntax.tree.TableNode;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocuments;
import io.ballerina.tools.text.TextRange;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BNumericProperty;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BStringProperty;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Stream;

/**
 * Class containing util functions.
 */
public final class Utils {

    private Utils() {
    }

    public static boolean hasCompilationErrors(SyntaxNodeAnalysisContext context) {
        for (Diagnostic diagnostic : context.compilation().diagnosticResult().diagnostics()) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return true;
            }
        }
        return false;
    }

    public static String stripEscapeCharacter(String name) {
        return name.startsWith("'") ? name.substring(1) : name;
    }

    public static String getTypeName(Node processedTypeNode) {
        String typeName = processedTypeNode.kind().stringValue();
        switch (processedTypeNode.kind()) {
            case HANDLE_TYPE_DESC:
            case ANY_TYPE_DESC:
            case ANYDATA_TYPE_DESC:
            case NEVER_TYPE_DESC:
                // here typename is not empty
                break;
            case UNION_TYPE_DESC:
                typeName = "union";
                break;
            case NIL_TYPE_DESC:
                typeName = "()";
                break;
            case MAP_TYPE_DESC:
                typeName = "map";
                break;
            case ERROR_TYPE_DESC:
                typeName = "error";
                break;
            case STREAM_TYPE_DESC:
                typeName = "stream";
                break;
            case FUNCTION_TYPE_DESC:
                typeName = "function";
                break;
            case TUPLE_TYPE_DESC:
                typeName = "tuple";
                break;
            case TABLE_TYPE_DESC:
                typeName = "table";
                break;
            case DISTINCT_TYPE_DESC:
                typeName = "distinct";
                break;
            case INTERSECTION_TYPE_DESC:
                typeName = "intersection";
                break;
            case FUTURE_TYPE_DESC:
                typeName = "future";
                break;
            case RECORD_TYPE_DESC:
                typeName = "in-line record";
                break;
            case OBJECT_TYPE_DESC:
                typeName = "object";
                break;
            default:
                if (typeName.isBlank()) {
                    typeName = processedTypeNode.kind().name();
                }
        }
        return typeName;
    }

    public static String getStringArgument(CodeActionExecutionContext context, String key) {
        for (CodeActionArgument arg : context.arguments()) {
            if (key.equals(arg.key())) {
                return arg.valueAs(String.class);
            }
        }
        return null;
    }

    public static TextRange getTextRangeArgument(CodeActionExecutionContext context, String key) {
        for (CodeActionArgument arg : context.arguments()) {
            if (key.equals(arg.key())) {
                return arg.valueAs(TextRange.class);
            }
        }
        return null;
    }

    public static String getStringDiagnosticProperty(List<DiagnosticProperty<?>> diagnosticProperties, int index) {
        return ((BStringProperty) diagnosticProperties.get(index)).value();
    }

    public static int getNumericDiagnosticProperty(List<DiagnosticProperty<?>> diagnosticProperties, int index) {
        return ((BNumericProperty) diagnosticProperties.get(index)).value().intValue();
    }

    public static String getFieldName(String entityName, ArrayList<String> fieldNames) {
        String fieldName = entityName.toLowerCase(Locale.ROOT);
        if (fieldNames.contains(fieldName)) {
            int i = 1;
            while (fieldNames.contains(fieldName + i)) {
                i++;
            }
            fieldName = fieldName + i;
        }
        return fieldName;
    }

    public static String getDatastore(SyntaxNodeAnalysisContext ctx) throws BalException {
        Path balFilePath = ctx.currentPackage().project().sourceRoot().toAbsolutePath();

        Path balFileContainingFolder = balFilePath.getParent();
        if (balFileContainingFolder == null) {
            throw new BalException("unable to locate the project's Ballerina.toml file");
        }

        Path balProjectDir = balFileContainingFolder.getParent();
        if (balProjectDir == null) {
            throw new BalException("unable to locate the project's Ballerina.toml file");
        }

        Path configPath = balProjectDir.resolve(ProjectConstants.BALLERINA_TOML);
        try {
            TextDocument configDocument = TextDocuments.from(Files.readString(configPath));
            SyntaxTree syntaxTree = SyntaxTree.from(configDocument);
            DocumentNode rootNote = syntaxTree.rootNode();
            NodeList<DocumentMemberDeclarationNode> nodeList = rootNote.members();
            for (DocumentMemberDeclarationNode member : nodeList) {
                if (member instanceof TableNode) {
                    TableNode node = (TableNode) member;
                    String tableName = node.identifier().toSourceCode().trim();
                    if (tableName.equals(Constants.PERSIST)) {
                        for (KeyValueNode field : node.fields()) {
                            if (field.identifier().toSourceCode().trim().equals(Constants.DATASTORE)) {
                                return field.value().toSourceCode().trim().replaceAll("\"", "");
                            }
                        }
                    }

                }
            }
            throw new BalException("the persist.datastore configuration does not exist in the Ballerina.toml file");
        } catch (IOException e) {
            throw new BalException("error while reading persist configurations. " + e.getMessage());
        }
    }

    public static String getDatastore(CodeActionContext ctx) throws BalException {
        Path balFilePath = ctx.filePath();

        Path balFileContainingFolder = balFilePath.getParent();
        if (balFileContainingFolder == null) {
            throw new BalException("unable to locate the project's Ballerina.toml file");
        }

        Path balProjectDir = balFileContainingFolder.getParent();
        if (balProjectDir == null) {
            throw new BalException("unable to locate the project's Ballerina.toml file");
        }

        Path configPath = balProjectDir.resolve(ProjectConstants.BALLERINA_TOML);
        try {
            TextDocument configDocument = TextDocuments.from(Files.readString(configPath));
            SyntaxTree syntaxTree = SyntaxTree.from(configDocument);
            DocumentNode rootNote = syntaxTree.rootNode();
            NodeList<DocumentMemberDeclarationNode> nodeList = rootNote.members();
            for (DocumentMemberDeclarationNode member : nodeList) {
                if (member instanceof TableNode) {
                    TableNode node = (TableNode) member;
                    String tableName = node.identifier().toSourceCode().trim();
                    if (tableName.equals(Constants.PERSIST)) {
                        for (KeyValueNode field : node.fields()) {
                            if (field.identifier().toSourceCode().trim().equals(Constants.DATASTORE)) {
                                return field.value().toSourceCode().trim().replaceAll("\"", "");
                            }
                        }
                    }

                }
            }
            throw new BalException("the persist.datastore configuration does not exist in the Ballerina.toml file");
        } catch (IOException e) {
            throw new BalException("error while reading persist configurations. " + e.getMessage());
        }
    }

    public static String readStringValueFromAnnotation
            (io.ballerina.compiler.syntax.tree.NodeList<AnnotationNode> annotationNodes, String annotation,
             String field) {
        if (annotationNodes == null) {
            return null;
        }
        for (AnnotationNode annotationNode : annotationNodes) {
            String annotationName = annotationNode.annotReference().toSourceCode().trim();
            if (annotationName.equals(annotation)) {
                Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
                if (annotationFieldNode.isPresent()) {
                    for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                        SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                        String fieldName = specificFieldNode.fieldName().toSourceCode().trim();
                        if (!fieldName.equals(field)) {
                            return null;
                        }
                        Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                        if (valueExpr.isPresent()) {
                            return valueExpr.get().toSourceCode().trim().replace("\"", "");
                        }
                    }
                }
            }
        }
        return null;
    }
    public static boolean isAnnotationPresent
            (io.ballerina.compiler.syntax.tree.NodeList<AnnotationNode> annotationNodes, String annotation) {
        if (annotationNodes == null) {
            return false;
        }
        for (AnnotationNode annotationNode : annotationNodes) {
            String annotationName = annotationNode.annotReference().toSourceCode().trim();
            if (annotationName.equals(annotation)) {
                return true;
            }
        }
        return false;
    }
    public static List<String> readStringArrayValueFromAnnotation
            (io.ballerina.compiler.syntax.tree.NodeList<AnnotationNode> annotationNodes, String annotation,
             String field) {
        if (annotationNodes == null) {
            return null;
        }
        for (AnnotationNode annotationNode : annotationNodes) {
            String annotationName = annotationNode.annotReference().toSourceCode().trim();
            if (annotationName.equals(annotation)) {
                Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
                if (annotationFieldNode.isPresent()) {
                    for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                        SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                        String fieldName = specificFieldNode.fieldName().toSourceCode().trim();
                        if (!fieldName.equals(field)) {
                            return null;
                        }
                        Optional<ExpressionNode> valueExpr = specificFieldNode.valueExpr();
                        if (valueExpr.isPresent()) {
                            return Stream.of(valueExpr.get().toSourceCode().trim().replace("\"", "")
                                    .replace("[", "")
                                    .replace("]", "").split(",")).map(String::trim).toList();
                        }
                    }
                }
            }
        }
        return null;
    }
}
