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

import com.google.gson.Gson;
import io.ballerina.projects.CodeActionManager;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.Project;
import io.ballerina.projects.directory.ProjectLoader;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.tools.text.LinePosition;
import org.testng.Assert;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;


import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.TestUtils.getEnvironmentBuilder;

/**
 * Code action related test cases.
 */
public class CodeActionTest {

    protected static final Path RESOURCE_PATH = Paths.get("src", "test", "resources");
    private static final Gson GSON = new Gson();

    @DataProvider
    private Object[][] testDataProvider() {
        return new Object[][]{
                {"project_2", "valid-persist-model-path.bal", LinePosition.from(2, 1),
                        "valid-persist-model-path.bal", "PERSIST_101", "REMOVE_DIAGNOSTIC_LOCATION",
                        "Remove unsupported member"},

                {"project_2", "usage-of-import-prefix.bal", LinePosition.from(0, 25),
                        "usage-of-import-prefix.bal", "PERSIST_102", "REMOVE_TEXT_RANGE",
                        "Remove import prefix"},

                {"project_2", "record-properties.bal", LinePosition.from(18, 6),
                        "record-properties.bal", "PERSIST_201", "CHANGE_TO_CLOSED_RECORD", "Change to closed record"},

                {"project_2", "field-properties.bal", LinePosition.from(22, 9),
                        "field-properties-rest-descriptor.bal", "PERSIST_301", "REMOVE_DIAGNOSTIC_LOCATION",
                        "Remove rest descriptor field"},
                {"project_2", "field-properties.bal", LinePosition.from(12, 13),
                        "field-properties-inherited-field.bal", "PERSIST_303", "REMOVE_DIAGNOSTIC_LOCATION",
                        "Remove inherited field"},
                {"project_2", "field-properties.bal", LinePosition.from(4, 21),
                        "field-properties-default-value.bal", "PERSIST_302", "REMOVE_TEXT_RANGE",
                        "Remove default value"},
                {"project_2", "field-properties.bal", LinePosition.from(13, 27),
                        "field-properties-optional-field.bal", "PERSIST_304", "REMOVE_TEXT_RANGE",
                        "Make field mandatory"},

                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-boolean.bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_BOOLEAN", "Change to 'boolean' type"},
                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-byte[].bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_BYTE_ARRAY", "Change to 'byte[]' type"},
                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-decimal.bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_DECIMAL", "Change to 'decimal' type"},
                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-float.bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_FLOAT", "Change to 'float' type"},
                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-int.bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_INT", "Change to 'int' type"},
                {"project_2", "field-types-valid.bal", LinePosition.from(15, 6), "field-types-string.bal",
                        "PERSIST_306", "CHANGE_TYPE_TO_STRING", "Change to 'string' type"},
                {"project_3", "field-types.bal", LinePosition.from(13, 4), "field-types-nillable.bal",
                        "PERSIST_308", "CHANGE_TYPE_TO_NOT_NILLABLE", "Change to 'float' type"},

                {"project_2", "field-types-valid.bal", LinePosition.from(18, 12),
                        "field-types-unsupported-array.bal", "PERSIST_306", "REMOVE_TEXT_RANGE",
                        "Change to 'time:Civil' type"},

                {"project_2", "self-referenced-entity.bal", LinePosition.from(8, 10),
                        "self-referenced-entity.bal", "PERSIST_401", "REMOVE_DIAGNOSTIC_LOCATION",
                        "Remove self-referenced field"},

                {"project_2", "mandatory-relation-field.bal", LinePosition.from(8, 21),
                        "mandatory-relation-entity[]-type.bal", "PERSIST_005", "ADD_SINGLE_TEXT",
                        "Add corresponding relation field in 'Workspace' entity"},
                {"project_2", "mandatory-relation-field.bal", LinePosition.from(27, 19),
                        "mandatory-relation-entity-type-1.bal", "PERSIST_005", "ADD_SINGLE_TEXT",
                        "Add corresponding 1-1 relation field in 'Building1' entity"},
                {"project_2", "mandatory-relation-field.bal", LinePosition.from(27, 19),
                        "mandatory-relation-entity-type-2.bal", "PERSIST_005", "ADD_SINGLE_TEXT",
                        "Add corresponding 1-n relation field in 'Building1' entity"},
                {"project_2", "mandatory-relation-field.bal", LinePosition.from(58, 10),
                        "mandatory-relation-entity-optional-type.bal", "PERSIST_005", "ADD_SINGLE_TEXT",
                        "Add corresponding relation field in 'Building3' entity"},
                {"project_2", "mandatory-relation-multiple-field-1.bal", LinePosition.from(13, 10),
                        "mandatory-relation-multiple-field-1.bal",
                        "PERSIST_005", "ADD_SINGLE_TEXT", "Add corresponding 1-n relation field in 'User' entity"},
                {"project_2", "mandatory-relation-multiple-field-2.bal", LinePosition.from(13, 10),
                        "mandatory-relation-multiple-field-2.bal",
                        "PERSIST_005", "ADD_SINGLE_TEXT", "Add corresponding 1-1 relation field in 'User' entity"},
                {"project_2", "mandatory-relation-multiple-field-3.bal", LinePosition.from(15, 10),
                        "mandatory-relation-multiple-field-3.bal",
                        "PERSIST_005", "ADD_SINGLE_TEXT", "Add corresponding 1-1 relation field in 'User' entity"},
                {"project_2", "mandatory-relation-multiple-field-4.bal", LinePosition.from(11, 10),
                        "mandatory-relation-multiple-field-4.bal",
                        "PERSIST_005", "ADD_SINGLE_TEXT", "Add corresponding 1-1 relation field in 'User' entity"},

                // PERSIST_403
                {"project_2", "different-owners.bal", LinePosition.from(9, 9),
                        "different-owners-building.bal", "PERSIST_004", "SWITCH_RELATION_OWNER",
                        "Make 'Building' entity relation owner"},
                {"project_2", "different-owners.bal", LinePosition.from(15, 11),
                        "different-owners-workspace.bal", "PERSIST_004", "SWITCH_RELATION_OWNER",
                        "Make 'Workspace' entity relation owner"},
                {"project_2", "different-owners.bal", LinePosition.from(35, 11),
                        "different-owners-building2.bal", "PERSIST_004", "SWITCH_RELATION_OWNER",
                        "Make 'Building2' entity relation owner"},
                {"project_2", "different-owners.bal", LinePosition.from(27, 11),
                        "different-owners-workspace2.bal", "PERSIST_004", "SWITCH_RELATION_OWNER",
                        "Make 'Workspace2' entity relation owner"},

                // PERSIST_404
                {"project_2", "nillable-relation-field.bal", LinePosition.from(44, 9),
                        "nillable-relation-field-building3-owner.bal",
                        "PERSIST_002", "ADD_SINGLE_TEXT", "Make 'Building3' entity relation owner"},
                {"project_2", "nillable-relation-field.bal", LinePosition.from(44, 9),
                        "nillable-relation-field-workspace3-owner.bal",
                        "PERSIST_002", "ADD_SINGLE_TEXT", "Make 'Workspace3' entity relation owner"},

                // PERSIST_405
                {"project_2", "nillable-relation-field.bal", LinePosition.from(59, 11),
                        "nillable-relation-field-1-1-both-optional.bal",
                        "PERSIST_003", "REMOVE_TEXT_RANGE", "Change 'Workspace4.location' to non-nillable field"},
                {"project_2", "nillable-relation-field.bal", LinePosition.from(59, 11),
                        "nillable-relation-field-1-1-both-optional2.bal",
                        "PERSIST_003", "REMOVE_TEXT_RANGE", "Change 'Building4.workspaces' to non-nillable field"},
                {"project_2", "nillable-relation-field.bal", LinePosition.from(14, 9),
                        "nillable-relation-field.bal", "PERSIST_406", "REMOVE_TEXT_RANGE", "Change to 'Building' type"},

                // PERSIST_501
                {"project_2", "readonly-field.bal", LinePosition.from(3, 16),
                        "readonly-field-beneficiaryId.bal", "PERSIST_001", "ADD_SINGLE_TEXT",
                        "Mark field 'beneficiaryId' as identity field"},
                {"project_2", "readonly-field.bal", LinePosition.from(3, 16), "readonly-field-needId.bal",
                        "PERSIST_001", "ADD_SINGLE_TEXT", "Mark field 'needId' as identity field"},
                {"project_2", "readonly-field.bal", LinePosition.from(3, 16), "readonly-field-quantity.bal",
                        "PERSIST_001", "ADD_SINGLE_TEXT", "Mark field 'quantity' as identity field"},

                {"project_2", "identifier-field-properties.bal", LinePosition.from(4, 14),
                        "identifier-field-properties-nil.bal", "PERSIST_502", "REMOVE_TEXT_RANGE",
                        "Change to 'int' type"},
                {"project_2", "identifier-field-properties.bal", LinePosition.from(16, 16),
                        "identifier-field-properties-rm-readonly.bal",
                        "PERSIST_503", "REMOVE_TEXT_RANGE", "Change to non-identity field"},

                {"project_2", "identifier-field-properties.bal", LinePosition.from(16, 15),
                        "identifier-field-properties.bal", "PERSIST_503", "CHANGE_TYPE_TO_STRING",
                        "Change to 'string' type"},
        };
    }

    @Test(dataProvider = "testDataProvider")
    public void testRemoveCodeSyntax(String directory, String fileName, LinePosition cursorPos, String outputFile,
                                     String expectedDiagnosticCode, String expectedActionName, String codeActionTitle)
            throws IOException {
        Path filePath = RESOURCE_PATH.resolve(directory).resolve("persist")
                .resolve(fileName);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(outputFile);

        CodeActionInfo expectedCodeAction = CodeActionInfo.from(codeActionTitle, List.of());
        expectedCodeAction.setProviderName(expectedDiagnosticCode + "/ballerina/persist/" + expectedActionName);

        performTest(filePath, cursorPos, expectedCodeAction, resultPath);
    }

    protected void performTest(Path filePath, LinePosition cursorPos, CodeActionInfo expected, Path expectedSrc)
            throws IOException {
        Project project = ProjectLoader.loadProject(filePath, getEnvironmentBuilder());
        List<CodeActionInfo> codeActions = getCodeActions(filePath, cursorPos, project);
        CodeActionInfo codeAction = validateCodeAction(codeActions, expected);
        List<DocumentEdit> actualEdits = executeCodeAction(project, filePath, codeAction);

        // Changes to 1 file expected
        Assert.assertEquals(actualEdits.size(), 1, "Expected changes to 1 file");

        String expectedFileUri = filePath.toUri().toString();
        Optional<DocumentEdit> actualEdit = actualEdits.stream()
                .filter(docEdit -> docEdit.getFileUri().equals(expectedFileUri))
                .findFirst();

        Assert.assertTrue(actualEdit.isPresent(), "Edits not found for fileUri: " + expectedFileUri);

        String modifiedSourceCode = actualEdit.get().getModifiedSyntaxTree().toSourceCode();
        String expectedSourceCode = Files.readString(expectedSrc);
        Assert.assertEquals(modifiedSourceCode, expectedSourceCode,
                "Actual source code didn't match expected source code");
    }

    private CodeActionInfo validateCodeAction(List<CodeActionInfo> found, CodeActionInfo expected) {
        Assert.assertTrue(found.size() > 0, "Expected at least 1 code action");
        Optional<CodeActionInfo> foundCodeAction = found.stream()
                // Code action args are not validated due to intermittent order change when converting to json
                .filter((codeActionInfo) -> expected.getTitle().equals(codeActionInfo.getTitle()) &&
                        expected.getProviderName().equals(codeActionInfo.getProviderName()))
                .findFirst();
        Assert.assertTrue(foundCodeAction.isPresent(), "Code action not found:" + expected);
        return foundCodeAction.get();
    }

    private List<CodeActionInfo> getCodeActions(Path filePath, LinePosition cursorPos, Project project) {
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        CodeActionManager codeActionManager = compilation.getCodeActionManager();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        return compilation.diagnosticResult().diagnostics().stream()
                .filter(diagnostic -> TestUtils.isWithinRange(diagnostic.location().lineRange(), cursorPos) &&
                        filePath.endsWith(diagnostic.location().lineRange().fileName()))
                .flatMap(diagnostic -> {
                    CodeActionContextImpl context = CodeActionContextImpl.from(
                            filePath.toUri().toString(),
                            filePath,
                            cursorPos,
                            document,
                            compilation.getSemanticModel(documentId.moduleId()),
                            diagnostic);
                    return codeActionManager.codeActions(context).getCodeActions().stream();
                })
                .collect(Collectors.toList());
    }

    private List<DocumentEdit> executeCodeAction(Project project, Path filePath, CodeActionInfo codeAction) {
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        List<CodeActionArgument> codeActionArguments = codeAction.getArguments().stream()
                .map(arg -> CodeActionArgument.from(GSON.toJsonTree(arg)))
                .collect(Collectors.toList());

        CodeActionExecutionContext executionContext = CodeActionExecutionContextImpl.from(
                filePath.toUri().toString(),
                filePath,
                null,
                document,
                compilation.getSemanticModel(document.documentId().moduleId()),
                codeActionArguments);

        return compilation.getCodeActionManager()
                .executeCodeAction(codeAction.getProviderName(), executionContext);
    }

}
