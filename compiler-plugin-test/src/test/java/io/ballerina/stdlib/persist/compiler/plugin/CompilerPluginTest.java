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

package io.ballerina.stdlib.persist.compiler.plugin;

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.persist.compiler.DiagnosticsCodes;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Tests the persist compiler plugin.
 */
public class CompilerPluginTest {

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Path distributionPath = Paths.get("../", "target", "ballerina-runtime")
                .toAbsolutePath();
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(distributionPath).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private Package loadPackage(String path) {
        Path projectDirPath = Paths.get("src", "test", "resources", "test-src", "plugin").
                toAbsolutePath().resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    @Test
    public void testEntityAnnotation1() {
        DiagnosticResult diagnosticResult = loadPackage("package_01").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList, "invalid key: the given key is not in the record definition",
                DiagnosticsCodes.PERSIST_102.getCode(), 2);
    }

    @Test
    public void testPrimaryKeyMarkReadOnly() {
        DiagnosticResult diagnosticResult = loadPackage("package_03").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList, "invalid initialization: the field is not specified as read-only",
                DiagnosticsCodes.PERSIST_106.getCode(), 2);
    }

    @Test
    public void testMultipleAutoIncrementAnnotation() {
        DiagnosticResult diagnosticResult = loadPackage("package_04").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList, "duplicate annotation: the entity does not allow " +
                        "multiple field with auto increment annotation",
                DiagnosticsCodes.PERSIST_107.getCode(), 1);
    }

    @Test
    public void testAutoIncrementAnnotation1() {
        DiagnosticResult diagnosticResult = loadPackage("package_05").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList, "invalid value: the value only supports positive integer",
                DiagnosticsCodes.PERSIST_103.getCode(), 1);
    }

    @Test
    public void testRelationAnnotationMismatchReference() {
        DiagnosticResult diagnosticResult = loadPackage("package_06").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList, "mismatch reference: the given key count is mismatched " +
                "with reference key count", DiagnosticsCodes.PERSIST_109.getCode(), 1);
    }

    @Test
    public void testOptionalField() {
        DiagnosticResult diagnosticResult = loadPackage("package_07").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid field type: the persist client does not support the union type",
                DiagnosticsCodes.PERSIST_101.getCode(), 1);
    }

    @Test
    public void testOptionalField2() {
        DiagnosticResult diagnosticResult = loadPackage("package_08").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid field type: the persist client does not support the union type",
                DiagnosticsCodes.PERSIST_101.getCode(), 1);
    }

    @Test
    public void testOptionalField3() {
        DiagnosticResult diagnosticResult = loadPackage("package_09").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid field type: the persist client does not support the union type",
                DiagnosticsCodes.PERSIST_101.getCode(), 1);
    }

    @Test
    public void testAutoIncrementField() {
        DiagnosticResult diagnosticResult = loadPackage("package_10").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid initialization: auto increment field must be defined as a key",
                DiagnosticsCodes.PERSIST_108.getCode(), 1);
    }

    @Test
    public void testRecordType() {
        DiagnosticResult diagnosticResult = loadPackage("package_11").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid initialization: the entity should be public",
                DiagnosticsCodes.PERSIST_111.getCode(), 1);
    }

    @Test
    public void testRecordType1() {
        DiagnosticResult diagnosticResult = loadPackage("package_12").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "invalid initialization: the entity should be public",
                DiagnosticsCodes.PERSIST_111.getCode(), 1);
    }

    @Test
    public void testTableName() {
        DiagnosticResult diagnosticResult = loadPackage("package_13").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "duplicate table name: the table name is already used in another entity",
                DiagnosticsCodes.PERSIST_113.getCode(), 1);
    }

    @Test
    public void testTableName1() {
        DiagnosticResult diagnosticResult = loadPackage("package_14").getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().
                filter(r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).
                collect(Collectors.toList());
        assertValues(errorDiagnosticsList,
                "duplicate table name: the table name is already used in another entity",
                DiagnosticsCodes.PERSIST_113.getCode(), 1);
    }

    private void assertValues(List<Diagnostic> errorDiagnosticsList, String msg, String code, int count) {
        long availableErrors = errorDiagnosticsList.size();
        Assert.assertEquals(availableErrors, count);
        DiagnosticInfo error = errorDiagnosticsList.get(0).diagnosticInfo();
        Assert.assertEquals(error.code(), code);
        Assert.assertEquals(error.messageFormat(), msg);
    }
}
