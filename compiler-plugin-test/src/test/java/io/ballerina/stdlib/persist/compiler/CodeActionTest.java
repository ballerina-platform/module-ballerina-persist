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
import com.google.gson.JsonObject;
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
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.Constants.REMOVE_TEXT_RANGE;
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
                {"valid-persist-model-path.bal", LinePosition.from(2, 1), "Remove unsupported member",
                        TextRange.from(32, 26), "PERSIST_101", "REMOVE_UNSUPPORTED_MEMBERS"},
                {"usage-of-import-prefix.bal", LinePosition.from(0, 25), "Remove import prefix",
                        TextRange.from(21, 9), "PERSIST_102", "REMOVE_MODULE_PREFIX"},
        };
    }

    @Test(dataProvider = "testDataProvider")
    public void testRemoveCodeSyntax(String fileName, LinePosition cursorPos, String codeActionTitle,
                                     TextRange codeActionArgNodeLocation, String expectedDiagnosticCode,
                                     String expectedActionName) throws IOException {
        Path filePath = RESOURCE_PATH.resolve("project_2").resolve("persist")
                .resolve(fileName);
        Path resultPath = RESOURCE_PATH.resolve("codeaction")
                .resolve(fileName);

        CodeActionArgument locationArg = CodeActionArgument.from(REMOVE_TEXT_RANGE, codeActionArgNodeLocation);
        CodeActionInfo expectedCodeAction = CodeActionInfo.from(codeActionTitle, List.of(locationArg));
        expectedCodeAction.setProviderName(expectedDiagnosticCode + "/ballerina/persist/" + expectedActionName);

        performTest(filePath, cursorPos, expectedCodeAction, resultPath);
    }

    protected void performTest(Path filePath, LinePosition cursorPos, CodeActionInfo expected, Path expectedSrc)
            throws IOException {
        Project project = ProjectLoader.loadProject(filePath, getEnvironmentBuilder());
        List<CodeActionInfo> codeActions = getCodeActions(filePath, cursorPos, project);
        Assert.assertTrue(codeActions.size() > 0, "Expected at least 1 code action");

        JsonObject expectedCodeAction = GSON.toJsonTree(expected).getAsJsonObject();
        Optional<CodeActionInfo> found = codeActions.stream()
                .filter(codeActionInfo -> {
                    JsonObject actualCodeAction = GSON.toJsonTree(codeActionInfo).getAsJsonObject();
                    return actualCodeAction.equals(expectedCodeAction);
                })
                .findFirst();
        Assert.assertTrue(found.isPresent(), "Code action not found:" + expectedCodeAction.toString());

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
