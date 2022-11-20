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

import io.ballerina.projects.CodeModifierResult;
import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.text.TextRange;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tests the persist compiler plugin.
 */
public class CodeModifierTest {

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Path distributionPath = Paths.get("../", "target", "ballerina-runtime")
                .toAbsolutePath();
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(distributionPath).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private Package loadPackage(String path) {
        Path projectDirPath = Paths.get("src", "test", "resources", "test-src", "modifier").
                toAbsolutePath().resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    @Test
    public void testCodeModifier() {

        Package newPackage = getModifiedPackage("package_01");

        for (DocumentId documentId : newPackage.getDefaultModule().documentIds()) {
            Document document = newPackage.getDefaultModule().document(documentId);

            if (document.name().equals("sample.bal")) {
                // Positive test
                String modifiedFunction =
                        "check from entity:MedicalNeed medicalNeed in mnClient->execute" +
                                "(` WHERE quantity > 5 ORDER BY quantity DESC LIMIT 5`)\n" +
                                "        select {\n" +
                                "            needId: medicalNeed.needId,\n" +
                                "            period: medicalNeed.period,\n" +
                                "            quantity: medicalNeed.quantity\n" +
                                "        };";
                Assert.assertTrue(document.syntaxTree().toSourceCode().contains(modifiedFunction));

                // Negative Tests
                List<String> unmodifiedFunction = List.of(
                        "from record {int needId; string period; int quantity;} medicalNeed in mns",
                        "check from entity:MedicalNeed medicalNeed in mnClient->read()\n" +
                                "        select {\n" +
                                "            needId: medicalNeed.needId,\n" +
                                "            period: medicalNeed.period,\n" +
                                "            quantity: medicalNeed.quantity\n" +
                                "        };"
                );

                unmodifiedFunction.forEach(codeSnippet ->
                        Assert.assertTrue(document.syntaxTree().toSourceCode().contains(codeSnippet), codeSnippet));
            }
        }
    }

    @Test
    public void limitClauseTest() {

        Package newPackage = getModifiedPackage("package_02");

        List<String> modifiedFunctions = List.of(
                "check from entity:MedicalNeed medicalNeed in mnClient->execute(` LIMIT 5`)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };");
        verifyModifiedFunctions(newPackage, modifiedFunctions);
    }

    @Test
    public void orderByClauseTest() {

        Package newPackage = getModifiedPackage("package_03");

        List<String> modifiedFunctions = List.of(
                "check from entity:MedicalNeed medicalNeed in mnClient->execute(` ORDER BY quantity `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from entity:MedicalNeed medicalNeed in mnClient->execute(` ORDER BY quantity ASC `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from entity:MedicalNeed medicalNeed in mnClient->execute(` ORDER BY needId DESC `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from entity:MedicalNeed medicalNeed in mnClient->execute" +
                        "(` ORDER BY quantity ASC , needId DESC `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in mnClient->execute" +
                        "(` ORDER BY quantity , needId DESC `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };"
        );

        verifyModifiedFunctions(newPackage, modifiedFunctions);
    }

    @Test
    public void whereClauseTest() {

        Package newPackage = getModifiedPackage("package_04");

        List<String> modifiedFunctions = List.of(
                "check from entity:MedicalNeed medicalNeed in " +
                        "mnClient->execute(` WHERE ( quantity < ${minQuantity} )  `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in " +
                        "mnClient->execute(` WHERE quantity < ${minQuantity}  `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };",
                "check from entity:MedicalNeed medicalNeed in " +
                        "mnClient->execute(` WHERE period = \"2022-10-10 01:02:03\" `)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in mnClient->execute(" +
                        "` WHERE quantity < ${minQuantity}  AND quantity > 0 `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in mnClient->execute(" +
                        "` WHERE quantity < ${minQuantity}  OR period = \"2022-10-10 01:02:03\" `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in mnClient->execute(" +
                        "` WHERE ( quantity < ${minQuantity}  AND quantity > 0)  " +
                        "OR period = \"2022-10-10 01:02:03\" `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };"
        );

        verifyModifiedFunctions(newPackage, modifiedFunctions);
    }

    @Test
    public void combinedClauseTest() {

        Package newPackage = getModifiedPackage("package_05");

        List<String> modifiedFunctions = List.of(
                "check from entity:MedicalNeed medicalNeed in " +
                        "mnClient->execute(` WHERE ( quantity < ${minQuantity} )  LIMIT 5`)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in " +
                        "mnClient->execute(` WHERE quantity < ${minQuantity}  ORDER BY quantity `)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };",
                "check from entity:MedicalNeed medicalNeed in " +
                        "mnClient->execute(` ORDER BY quantity LIMIT 5`)\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };",
                "check from var {needId, period, quantity} in mnClient->execute(" +
                        "` WHERE quantity < ${minQuantity}  AND quantity > 0 ORDER BY quantity LIMIT 5`)\n" +
                        "        select {\n" +
                        "            needId: needId,\n" +
                        "            period: period,\n" +
                        "            quantity: quantity\n" +
                        "        };"
        );

        verifyModifiedFunctions(newPackage, modifiedFunctions);
    }

    @Test
    public void unsupportedExpressionTest() {
        DiagnosticResult reportedDiagnostics = getDiagnosticResult("package_06");
        List<Diagnostic> errorDiagnosticsList = filterErrorDiagnostics(reportedDiagnostics);

        long availableErrors = errorDiagnosticsList.size();

        Assert.assertEquals(availableErrors, 3);

        DiagnosticInfo limitClauseError = errorDiagnosticsList.get(0).diagnosticInfo();
        Assert.assertEquals(limitClauseError.code(), DiagnosticsCodes.PERSIST_202.getCode());
        Assert.assertEquals(limitClauseError.messageFormat(), DiagnosticsCodes.PERSIST_202.getMessage());

        DiagnosticInfo orderbyClauseError = errorDiagnosticsList.get(1).diagnosticInfo();
        Assert.assertEquals(orderbyClauseError.code(), DiagnosticsCodes.PERSIST_203.getCode());
        Assert.assertEquals(orderbyClauseError.messageFormat(), DiagnosticsCodes.PERSIST_203.getMessage());

        DiagnosticInfo whereClauseError = errorDiagnosticsList.get(2).diagnosticInfo();
        Assert.assertEquals(whereClauseError.code(), DiagnosticsCodes.PERSIST_201.getCode());
        Assert.assertEquals(whereClauseError.messageFormat(), DiagnosticsCodes.PERSIST_201.getMessage());
    }

    @Test
    public void testUsageOfExecute() {
        DiagnosticResult reportedDiagnostics = getDiagnosticResult("package_07");
        List<Diagnostic> errorDiagnosticsList = filterErrorDiagnostics(reportedDiagnostics);

        long availableErrors = errorDiagnosticsList.size();

        Assert.assertEquals(availableErrors, 1);

        DiagnosticInfo limitClauseError = errorDiagnosticsList.get(0).diagnosticInfo();
        Assert.assertEquals(limitClauseError.code(), DiagnosticsCodes.PERSIST_210.getCode());
        Assert.assertEquals(limitClauseError.messageFormat(), DiagnosticsCodes.PERSIST_210.getMessage());
    }

    @Test
    public void limitClauseNegativeTest() {
        DiagnosticResult reportedDiagnostics = getDiagnosticResult("package_08");
        List<Diagnostic> errorDiagnosticsList = filterErrorDiagnostics(reportedDiagnostics);

        long availableErrors = errorDiagnosticsList.size();

        Assert.assertEquals(availableErrors, 1);

        DiagnosticInfo limitClauseError = errorDiagnosticsList.get(0).diagnosticInfo();
        Assert.assertEquals(limitClauseError.code(), DiagnosticsCodes.PERSIST_202.getCode());
        Assert.assertEquals(limitClauseError.messageFormat(), DiagnosticsCodes.PERSIST_202.getMessage());
    }

    @Test
    public void orderByClauseNegativeTest() {

        DiagnosticResult reportedDiagnostics = getDiagnosticResult("package_09");
        List<Diagnostic> errorDiagnosticsList = filterErrorDiagnostics(reportedDiagnostics);

        long availableErrors = errorDiagnosticsList.size();

        Assert.assertEquals(availableErrors, 2);

        errorDiagnosticsList.forEach(diagnostic -> {
            Assert.assertEquals(diagnostic.diagnosticInfo().code(), DiagnosticsCodes.PERSIST_203.getCode());
            Assert.assertEquals(diagnostic.diagnosticInfo().messageFormat(), DiagnosticsCodes.PERSIST_203.getMessage());
        });
    }

    @Test
    public void readFunctionCallWarnings() {

        DiagnosticResult reportedDiagnostics = getDiagnosticResult("package_10");
        List<Diagnostic> errorDiagnosticsList = filterErrorDiagnostics(reportedDiagnostics);
        Assert.assertEquals(errorDiagnosticsList.size(), 0);

        List<Diagnostic> warnings = reportedDiagnostics.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.WARNING))
                .collect(Collectors.toList());
        long availableWarnings = warnings.size();

        Assert.assertEquals(availableWarnings, 4);

        warnings.forEach(warning -> {
            Assert.assertEquals(warning.diagnosticInfo().code(), DiagnosticsCodes.PERSIST_211.getCode());
            Assert.assertEquals(warning.diagnosticInfo().messageFormat(), DiagnosticsCodes.PERSIST_211.getMessage());
        });

        // sample.bal (24:53, 36:69)
        Assert.assertEquals(warnings.get(0).location().textRange(), TextRange.from(931, 16));

        // sample.bal (36:53, 24:69)
        Assert.assertEquals(warnings.get(1).location().textRange(), TextRange.from(1332, 16));

        // sample.bal (37:53, 37:69)
        Assert.assertEquals(warnings.get(2).location().textRange(), TextRange.from(1403, 16));

        // sample.bal (49:53, 49:69)
        Assert.assertEquals(warnings.get(3).location().textRange(), TextRange.from(1817, 16));
    }

    private Package getModifiedPackage(String path) {
        Package currentPackage = loadPackage(path);
        DiagnosticResult diagnosticResult = currentPackage.getCompilation().diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
        // Running the code generation
        CodeModifierResult codeModifierResult = currentPackage.runCodeModifierPlugins();
        Assert.assertEquals(codeModifierResult.reportedDiagnostics().errorCount(), 0);
        return codeModifierResult.updatedPackage().orElse(currentPackage);
    }

    private void verifyModifiedFunctions(Package newPackage, List<String> modifiedQueryStrings) {
        for (DocumentId documentId : newPackage.getDefaultModule().documentIds()) {
            Document document = newPackage.getDefaultModule().document(documentId);

            if (document.name().equals("sample.bal")) {
                // Positive test
                modifiedQueryStrings.forEach(codeSnippet ->
                        Assert.assertTrue(document.syntaxTree().toSourceCode().contains(codeSnippet), codeSnippet));
            }
        }
    }

    private DiagnosticResult getDiagnosticResult(String packagePath) {
        Package currentPackage = loadPackage(packagePath);
        DiagnosticResult diagnosticResult = currentPackage.getCompilation().diagnosticResult();
        Assert.assertEquals(diagnosticResult.errorCount(), 0);
        return currentPackage.runCodeModifierPlugins().reportedDiagnostics();
    }

    private List<Diagnostic> filterErrorDiagnostics(DiagnosticResult reportedDiagnostics) {
        return reportedDiagnostics.diagnostics().stream()
                .filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR))
                .collect(Collectors.toList());
    }

}

