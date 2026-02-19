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

    /**
     * Generate a unique field name derived from the given entity name, avoiding collisions with existing names.
     *
     * @param entityName the base entity name to derive the field name from
     * @param fieldNames the list of existing field names to avoid collisions with
     * @return a lowercase field name derived from {@code entityName} that is not present in {@code fieldNames};
     * a numeric suffix is appended if needed to ensure uniqueness
     */
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

    /**
     * Compute persist model information (model name and path to ballerina.toml) for the project that contains
     * the source referenced by the given analysis context.
     *
     * @param ctx the syntax node analysis context used to locate the current package and its source root
     * @return a PersistModelInformation populated with the discovered model name and TOML path; returns a default
     *         PersistModelInformation with both fields set to {@code null} if the information cannot be resolved
     */
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

    /**
     * Resolve persist model information for a Ballerina source file.
     *
     * Searches for a Ballerina.toml associated with the given .bal file in two levels:
     * 1) If the file's containing folder is the known persist directory and contains Ballerina.toml,
     *    returns a PersistModelInformation with that toml path and a null modelName.
     * 2) Otherwise, if the containing folder is a directory, use its name as the modelName and
     *    search for Ballerina.toml in the parent folder; return a PersistModelInformation with
     *    the derived modelName and the found toml path (or null if none found).
     * If the provided path has no parent, returns a default PersistModelInformation with both fields null.
     *
     * @param balFilePath the path to the .bal file to analyze
     * @return a PersistModelInformation containing the resolved modelName (may be null) and the path
     *         to the associated Ballerina.toml (may be null)
     */
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

        /**
         * Creates a PersistModelInformation with both `modelName` and `ballerinaTomlPath` set to {@code null}.
         */
        public PersistModelInformation() {
            this(null, null);
        }

        /**
         * Creates a PersistModelInformation for the given Ballerina TOML path and leaves the model name unset.
         *
         * @param ballerinaTomlPath the path to the Ballerina TOML file; may be null
         */
        public PersistModelInformation(Path ballerinaTomlPath) {
            this(null, ballerinaTomlPath);
        }
    }

    /**
     * Locate the project's Ballerina.toml when the provided folder is a persist directory.
     *
     * @param balFileContainingFolder the path expected to end with the persist directory name
     * @return the path to the project's BALLERINA_TOML if the persist directory's parent exists and the file is
     * present, or {@code null} otherwise
     */
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

    /**
     * Resolve the datastore name for a persist model using the project's TOML configuration.
     *
     * @param configPath path to the project's Ballerina.toml (may be replaced by target/Persist.toml if present)
     * @param model      the persist model name to select, or {@code null} to select the default model entry
     * @return the resolved datastore name, or {@code null} if no matching datastore is found
     * @throws BalException if {@code configPath} is {@code null} or if reading/parsing the configuration fails
     */
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

    /**
     * Locate the datastore name in a TOML configuration file for the specified persist model.
     *
     * @param configPath path to the TOML configuration file
     * @param model      the persist model name to match, or {@code null} to select the default model entry
     * @return           the resolved datastore name if a matching entry is found, {@code null} otherwise
     * @throws BalException if the configuration file cannot be read
     */
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

    /**
     * Extracts the datastore name from a TOML document member when the member represents a persist configuration
     * table.
     *
     * @param member a TOML document member node to inspect (may be a table or table array)
     * @param model  optional model name used to select a model-specific datastore; may be null
     * @return the datastore name when present for the given member and model, or `null` if none is found
     */
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

    /**
     * Extracts the datastore value from a TOML table's fields when the table name and model conditions match.
     *
     * Examines the provided fields for `MODEL` and file path entries, validates model-related conditions, and then
     * returns the value of the specified datastore key if present.
     *
     * @param tableName the name of the current TOML table
     * @param expectedTableName the table name expected for this extraction (must match {@code tableName})
     * @param fields the list of key-value fields in the table
     * @param datastoreKey the key name whose value should be returned when conditions are satisfied
     * @param model optional model name used to filter matching entries; may be {@code null}
     * @return the datastore value if present and model conditions are satisfied, {@code null} otherwise
     */
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

    /**
     * Checks whether the provided MODEL and FILE_PATH values satisfy the requested model selection.
     *
     * @param model the requested model name, or {@code null} to indicate the default (no model)
     * @param modelFieldValue the value of the TOML `model` field, or {@code null} if absent
     * @param filePathValue the value of the TOML `filePath` field, or {@code null} if absent
     * @return {@code true} if the values satisfy the model selection rules, {@code false} otherwise
     */
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


    /**
     * Extracts the key identifier text from the given key-value node.
     *
     * @param field the key-value node to read the key from
     * @return the key identifier text, trimmed of surrounding whitespace
     */
    private static String getKey(KeyValueNode field) {
        return field.identifier().toSourceCode().trim();
    }

    /**
     * Extracts the value text from a KeyValueNode, trimming whitespace and removing enclosing double quotes.
     *
     * @param field the key-value node to read the value from
     * @return the node's value text with surrounding whitespace trimmed and enclosing `"` characters removed
     */
    private static String getValue(KeyValueNode field) {
        return field.value().toSourceCode().trim().replace("\"", "");
    }

    /**
     * Resolve the datastore name for the current Ballerina file represented by the given code action context.
     *
     * @param ctx the code action context containing the current file path
     * @return the configured datastore name for the resolved persist model, or `null` if no datastore is configured
     * for that model
     * @throws BalException if the configuration path cannot be determined or read
     */
    public static String getDatastore(CodeActionContext ctx) throws BalException {
        Path balFilePath = ctx.filePath();
        PersistModelInformation persistModelInformation = getPersistModelInformation(balFilePath);
        return getDatastore(persistModelInformation.ballerinaTomlPath(), persistModelInformation.modelName());
    }

    /**
     * Extracts a comma-separated list of string values from a specific field of a given annotation node.
     *
     * Searches the provided annotation nodes for an annotation matching `annotation` and, if found,
     * returns the contents of its `field` as a list of trimmed strings parsed from a bracketed,
     * quote-delimited string array expression (e.g. ["a","b"]).
     *
     * @param annotationNodes the list of annotation nodes to search
     * @param annotation the fully qualified annotation name to match
     * @param field the field name within the annotation whose value should be parsed
     * @return a list of strings parsed from the annotation field; an empty list if the annotation or field is not
     * present or has no value
     */
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
