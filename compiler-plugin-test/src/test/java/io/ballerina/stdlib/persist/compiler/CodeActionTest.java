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
import io.ballerina.tools.text.TextRange;
import org.testng.Assert;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.Constants.END_DELIMITER_TEXT_RANGE;
import static io.ballerina.stdlib.persist.compiler.Constants.REMOVE_TEXT_RANGE;
import static io.ballerina.stdlib.persist.compiler.Constants.START_DELIMITER_TEXT_RANGE;
import static io.ballerina.stdlib.persist.compiler.TestUtils.getEnvironmentBuilder;

/**
 * Code action related test cases.
 */
public class CodeActionTest {

    protected static final Path RESOURCE_PATH = Paths.get("src", "test", "resources", "test-src");
    private static final Gson GSON = new Gson();


    @DataProvider
    private Object[][] testDataProvider() {
        return new Object[][]{
                {"valid-persist-model-path.bal", LinePosition.from(2, 1), "valid-persist-model-path.bal",
                        "Remove unsupported member", "PERSIST_101", "REMOVE_UNSUPPORTED_MEMBERS",
                        Map.of(REMOVE_TEXT_RANGE, TextRange.from(32, 26))},
                {"usage-of-import-prefix.bal", LinePosition.from(0, 25), "usage-of-import-prefix.bal",
                        "Remove import prefix", "PERSIST_102", "REMOVE_MODULE_PREFIX",
                        Map.of(REMOVE_TEXT_RANGE, TextRange.from(21, 9))},
                {"record-properties.bal", LinePosition.from(14, 6), "record-properties.bal",
                        "Change to closed record", "PERSIST_201", "CHANGE_TO_CLOSED_RECORD",
                        Map.of(START_DELIMITER_TEXT_RANGE, TextRange.from(232, 0),
                                END_DELIMITER_TEXT_RANGE, TextRange.from(338, 0))},
                {"mandatory-relation-field.bal", LinePosition.from(8, 21), "mandatory-relation-field.bal",
                        "Add 'Building'-typed field in 'Workspace' entity",
                        "PERSIST_402", "ADD_RELATION_FIELD_IN_RELATED_ENTITY",
                        Map.of("code.add.text.range", TextRange.from(284, 0),
                                "relation.type", "Building")},
                {"mandatory-relation-field.bal", LinePosition.from(27, 19), "mandatory-relation-field2.bal",
                        "Add 'Workspace2'-typed field in 'Building1' entity",
                        "PERSIST_402", "ADD_RELATION_FIELD_IN_RELATED_ENTITY",
                        Map.of("code.add.text.range", TextRange.from(426, 0),
                                "relation.type", "Building")},
        };
    }

    @Test(dataProvider = "testDataProvider")
    public void testRemoveCodeSyntax(String fileName, LinePosition cursorPos, String outputFile, String codeActionTitle,
                                     String expectedDiagnosticCode, String expectedActionName,
                                     Map<String, TextRange> codeActionArgs) throws IOException {
        Path filePath = RESOURCE_PATH.resolve("project_2").resolve("persist")
                .resolve(fileName);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(outputFile);

        List<CodeActionArgument> codeActionArguments = codeActionArgs.entrySet().stream()
                .map((entry) -> CodeActionArgument.from(entry.getKey(), entry.getValue()))
                .collect(Collectors.toList());
        CodeActionInfo expectedCodeAction = CodeActionInfo.from(codeActionTitle, codeActionArguments);
        expectedCodeAction.setProviderName(expectedDiagnosticCode + "/ballerina/persist/" + expectedActionName);

        performTest(filePath, cursorPos, expectedCodeAction, resultPath);
    }

    protected void performTest(Path filePath, LinePosition cursorPos, CodeActionInfo expected, Path expectedSrc)
            throws IOException {
        Project project = ProjectLoader.loadProject(filePath, getEnvironmentBuilder());
        List<CodeActionInfo> codeActions = getCodeActions(filePath, cursorPos, project);
        Assert.assertTrue(codeActions.size() > 0, "Expected at least 1 code action");

        Optional<CodeActionInfo> found = codeActions.stream()
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
