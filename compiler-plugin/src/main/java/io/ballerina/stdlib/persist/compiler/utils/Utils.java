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
import io.ballerina.projects.ProjectKind;
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
import io.ballerina.toml.syntax.tree.TableArrayNode;
import io.ballerina.toml.syntax.tree.TableNode;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocuments;
import io.ballerina.tools.text.TextRange;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BNumericProperty;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BStringProperty;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Stream;

import static io.ballerina.stdlib.persist.compiler.Constants.MODEL;
import static io.ballerina.stdlib.persist.compiler.Constants.PERSIST_DIRECTORY;

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

    public static PersistModelInformation getPersistModelInfo(SyntaxNodeAnalysisContext ctx) {
        try {
            if (ctx.currentPackage().project().kind().equals(ProjectKind.SINGLE_FILE_PROJECT)) {
                Path balFilePath = ctx.currentPackage().project().sourceRoot().toAbsolutePath();
                return getPersistModelInformation(balFilePath);
            }
        } catch (UnsupportedOperationException e) {
            //todo log properly This is to identify any issues in resolving path
        }
        return new PersistModelInformation();
    }

    private static PersistModelInformation getPersistModelInformation(Path balFilePath) {
        Path balFileContainingFolder = balFilePath.getParent();
        if (balFileContainingFolder == null) {
            return new PersistModelInformation();
        }

        // First level check
        Path ballerinaTomlPath =
                getBallerinaTomlPathFromPersistDir(balFileContainingFolder);
        if (ballerinaTomlPath != null) {
            return new PersistModelInformation(ballerinaTomlPath);
        }

        // Second level check
        Path parent = balFileContainingFolder.getParent();
        String modelName = null;
        if (balFileContainingFolder.toFile().isDirectory()) {
            Path fileName = balFileContainingFolder.getFileName();
            modelName = fileName != null ? fileName.toString() : null;
        }

        Path secondLevelToml = parent != null
                ? getBallerinaTomlPathFromPersistDir(parent)
                : null;
        return new PersistModelInformation(modelName, secondLevelToml);
    }

    public record PersistModelInformation(String modelName, Path ballerinaTomlPath) {

        public PersistModelInformation() {
            this(null, null);
        }

        public PersistModelInformation(Path ballerinaTomlPath) {
            this(null, ballerinaTomlPath);
        }
    }

    private static Path getBallerinaTomlPathFromPersistDir(Path balFileContainingFolder) {
        if (balFileContainingFolder == null || !balFileContainingFolder.endsWith(PERSIST_DIRECTORY)) {
            return null;
        }

        Path balProjectDir = balFileContainingFolder.getParent();
        if (balProjectDir == null) {
            return null;
        }

        File balProject = balProjectDir.toFile();
        if (!balProject.exists()) {
            return null;
        }

        File tomlFile = balProjectDir.resolve(ProjectConstants.BALLERINA_TOML).toFile();
        return tomlFile.exists() ? tomlFile.toPath() : null;
    }

    public static String getDatastore(Path configPath, String model) throws BalException {
        if (configPath == null) {
            throw new BalException("unable to locate the project's Ballerina.toml file");
        }
        Path balProjectDir = configPath.getParent();
        Path targetDir = Paths.get(String.valueOf(balProjectDir), "target");
        Path genCmdConfigPath = targetDir.resolve("Persist.toml");
        if (Files.exists(genCmdConfigPath)) {
            configPath = genCmdConfigPath;
        }
        return getDataStoreName(configPath, model);
    }

    private static String getDataStoreName(Path configPath, String model) throws BalException {
        try {
            TextDocument configDocument = TextDocuments.from(Files.readString(configPath));
            SyntaxTree syntaxTree = SyntaxTree.from(configDocument);
            DocumentNode rootNode = syntaxTree.rootNode();

            return rootNode.members().stream()
                    .map(member -> getDataStoreName(member, model))
                    .filter(Objects::nonNull)
                    .findFirst()
                    .orElse(null);

        } catch (IOException e) {
            throw new BalException("error while reading persist configurations. " + e.getMessage());
        }
    }

    private static String getDataStoreName(DocumentMemberDeclarationNode member, String model) {
        if (member instanceof TableArrayNode arrNode) {
            return extractDataStore(
                    arrNode.identifier().toSourceCode().trim(),
                    Constants.TOOL_PERSIST,
                    arrNode.fields(),
                    Constants.OPTIONS_DATASTORE,
                    model
            );
        }

        if (member instanceof TableNode tableNode) {
            return extractDataStore(
                    tableNode.identifier().toSourceCode().trim(),
                    Constants.PERSIST,
                    tableNode.fields(),
                    Constants.DATASTORE,
                    model
            );
        }

        return null;
    }

    private static String extractDataStore(String tableName, String expectedTableName, NodeList<KeyValueNode> fields,
                                           String datastoreKey, String model) {
        if (!tableName.equals(expectedTableName)) {
            return null;
        }

        String modelFieldValue = null;
        String filePathValue = null;

        for (KeyValueNode field : fields) {
            String key = getKey(field);

            if (key.equals(MODEL)) {
                modelFieldValue = getValue(field);
            } else if (key.equals(Constants.FILE_PATH)) {
                filePathValue = getValue(field);
            }
        }

        if (!isModelConditionSatisfied(model, modelFieldValue, filePathValue)) {
            return null;
        }

        return fields.stream()
                .filter(f -> getKey(f).equals(datastoreKey))
                .map(Utils::getValue)
                .findFirst()
                .orElse(null);
    }

    private static boolean isModelConditionSatisfied(String model, String modelFieldValue, String filePathValue) {
        if (model == null) {
            // MODEL must be absent
            if (modelFieldValue != null) {
                return false;
            }

            // FILE_PATH must be absent OR end with persist/model.bal
            return filePathValue == null ||
                    filePathValue.endsWith("persist/model.bal");
        }

        // MODEL field present and equals
        if (model.equals(modelFieldValue)) {
            return true;
        }

        // OR FILE_PATH ends with persist/{model}/model.bal
        return filePathValue != null && filePathValue.endsWith(String.format("persist/%s/model.bal", model));
    }


    private static String getKey(KeyValueNode field) {
        return field.identifier().toSourceCode().trim();
    }

    private static String getValue(KeyValueNode field) {
        return field.value().toSourceCode().trim().replace("\"", "");
    }

    public static String getDatastore(CodeActionContext ctx) throws BalException {
        Path balFilePath = ctx.filePath();
        PersistModelInformation persistModelInformation = getPersistModelInformation(balFilePath);
        return getDatastore(persistModelInformation.ballerinaTomlPath(), persistModelInformation.modelName());
    }

    public static List<String> readStringArrayValueFromAnnotation(List<AnnotationNode> annotationNodes,
                                                                  String annotation, String field) {
        for (AnnotationNode annotationNode : annotationNodes) {
            String annotationName = annotationNode.annotReference().toSourceCode().trim();
            if (annotationName.equals(annotation)) {
                Optional<MappingConstructorExpressionNode> annotationFieldNode = annotationNode.annotValue();
                if (annotationFieldNode.isPresent()) {
                    for (MappingFieldNode mappingFieldNode : annotationFieldNode.get().fields()) {
                        SpecificFieldNode specificFieldNode = (SpecificFieldNode) mappingFieldNode;
                        String fieldName = specificFieldNode.fieldName().toSourceCode().trim();
                        if (!fieldName.equals(field)) {
                            return Collections.emptyList();
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
        return Collections.emptyList();
    }
}
