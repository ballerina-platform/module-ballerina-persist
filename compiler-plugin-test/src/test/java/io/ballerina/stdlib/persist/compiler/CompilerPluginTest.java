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

import io.ballerina.projects.DiagnosticResult;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Persist compiler plugin tests.
 */
public class CompilerPluginTest {

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Path distributionPath = Paths.get("../", "target", "ballerina-runtime")
                .toAbsolutePath();
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(distributionPath).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private Package loadPackage(String path) {
        Path projectDirPath = Paths.get("src", "test", "resources", "test-src").
                toAbsolutePath().resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    @Test
    public void test17() {
        assertTest(loadPackage("package_17").getCompilation().diagnosticResult());
    }

    @Test
    public void test18() {
        assertTest(loadPackage("package_18").getCompilation().diagnosticResult());
    }

    @Test
    public void test19() {
        assertTest(loadPackage("package_19").getCompilation().diagnosticResult());
    }

    @Test
    public void test20() {
        assertTest(loadPackage("package_20").getCompilation().diagnosticResult());
    }

    @Test
    public void test21() {
        assertTest(loadPackage("package_21").getCompilation().diagnosticResult());
    }

    private void assertTest(DiagnosticResult result) {
        Assert.assertEquals(result.diagnostics().size(), 0);
        Path distributionPath = Paths.get("../", "target", "sql_script.sql")
                .toAbsolutePath();
        Assert.assertTrue(Files.exists(distributionPath), "The file doesn't exist");
        try {
            Assert.assertNotEquals(Files.readString(distributionPath), "");
        } catch (IOException e) {
            Assert.fail("Error: " + e.getMessage());
        }
    }
}
