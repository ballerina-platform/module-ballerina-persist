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
                {"valid-persist-model-path.bal", LinePosition.from(2, 1), "valid-persist-model-path.bal",
                        "PERSIST_101", "REMOVE_DIAGNOSTIC_LOCATION", "Remove unsupported member"},
                {"usage-of-import-prefix.bal", LinePosition.from(0, 25), "usage-of-import-prefix.bal",
                        "PERSIST_102", "REMOVE_TEXT_RANGE", "Remove import prefix"},
                {"identifier-field-properties.bal", LinePosition.from(4, 14), "identifier-field-properties-nil.bal",
                        "PERSIST_502", "REMOVE_TEXT_RANGE", "Change to 'int' type"},
                {"identifier-field-properties.bal", LinePosition.from(16, 16),
                        "identifier-field-properties-rm-readonly.bal",
                        "PERSIST_503", "REMOVE_TEXT_RANGE", "Change to non-identity field"},
                {"self-referenced-entity.bal", LinePosition.from(8, 10), "self-referenced-entity.bal",
                        "PERSIST_401", "REMOVE_DIAGNOSTIC_LOCATION", "Remove self-referenced field"},
                {"duplicated-relations-field.bal", LinePosition.from(9, 11), "duplicated-relations-field.bal",
                        "PERSIST_403", "REMOVE_DIAGNOSTIC_LOCATION", "Remove duplicate relation field"},

                {"field-properties.bal", LinePosition.from(22, 9), "field-properties-rest-descriptor.bal",
                        "PERSIST_301", "REMOVE_DIAGNOSTIC_LOCATION", "Remove rest descriptor field"},
                {"field-properties.bal", LinePosition.from(12, 13), "field-properties-inherited-field.bal",
                        "PERSIST_303", "REMOVE_DIAGNOSTIC_LOCATION", "Remove inherited field"},
                {"field-properties.bal", LinePosition.from(4, 21), "field-properties-default-value.bal",
                        "PERSIST_302", "REMOVE_TEXT_RANGE", "Remove default value"},
                {"field-properties.bal", LinePosition.from(13, 27), "field-properties-optional-field.bal",
                        "PERSIST_304", "REMOVE_TEXT_RANGE", "Make field mandatory"},
                {"field-types.bal", LinePosition.from(12, 9), "field-types-unsupported-array.bal",
                        "PERSIST_306", "REMOVE_TEXT_RANGE", "Change to 'boolean' type"},

                {"record-properties.bal", LinePosition.from(14, 6), "record-properties.bal",
                        "PERSIST_201", "CHANGE_TO_CLOSED_RECORD", "Change to closed record"},
                {"mandatory-relation-field.bal", LinePosition.from(8, 21), "mandatory-relation-field.bal",
                        "PERSIST_402", "ADD_RELATION_FIELD_IN_RELATED_ENTITY",
                        "Add 'Building'-typed field in 'Workspace' entity"},
                {"mandatory-relation-field.bal", LinePosition.from(27, 19), "mandatory-relation-field2.bal",
                        "PERSIST_402", "ADD_RELATION_FIELD_IN_RELATED_ENTITY",
                        "Add 'Workspace2'-typed field in 'Building1' entity"},

                {"field-types.bal", LinePosition.from(15, 6), "field-types-boolean.bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_BOOLEAN", "Change to 'boolean' type"},
                {"field-types.bal", LinePosition.from(15, 6), "field-types-byte[].bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_BYTE_ARRAY", "Change to 'byte[]' type"},
                {"field-types.bal", LinePosition.from(15, 6), "field-types-decimal.bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_DECIMAL", "Change to 'decimal' type"},
                {"field-types.bal", LinePosition.from(15, 6), "field-types-float.bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_FLOAT", "Change to 'float' type"},
                {"field-types.bal", LinePosition.from(15, 6), "field-types-int.bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_INT", "Change to 'int' type"},
                {"field-types.bal", LinePosition.from(15, 6), "field-types-string.bal",
                        "PERSIST_305", "CHANGE_TYPE_TO_STRING", "Change to 'string' type"},
                {"identifier-field-properties.bal", LinePosition.from(16, 15), "identifier-field-properties.bal",
                        "PERSIST_503", "CHANGE_TYPE_TO_STRING", "Change to 'string' type"},
        };
    }

    @Test(dataProvider = "testDataProvider")
    public void testRemoveCodeSyntax(String fileName, LinePosition cursorPos, String outputFile,
                                     String expectedDiagnosticCode, String expectedActionName, String codeActionTitle)
            throws IOException {
        Path filePath = RESOURCE_PATH.resolve("project_2").resolve("persist")
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
        Assert.assertTrue(codeActions.size() > 0, "Expected at least 1 code action");

        Optional<CodeActionInfo> found = codeActions.stream()
                // Code action args are not validated due to intermittent order change when converting to json
                .filter((codeActionInfo) -> expected.getTitle().equals(codeActionInfo.getTitle()) &&
                        expected.getProviderName().equals(codeActionInfo.getProviderName()))
                .findFirst();
        Assert.assertTrue(found.isPresent(), "Code action not found:" + expected);

        List<DocumentEdit> actualEdits = executeCodeAction(project, filePath, found.get());
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

    private List<CodeActionInfo> getCodeActions(Path filePath, LinePosition cursorPos, Project project) {
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        CodeActionManager codeActionManager = compilation.getCodeActionManager();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        return compilation.diagnosticResult().diagnostics().stream()
                .filter(diagnostic -> TestUtils.isWithinRange(diagnostic.location().lineRange(), cursorPos) &&
                        filePath.endsWith(diagnostic.location().lineRange().filePath()))
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
