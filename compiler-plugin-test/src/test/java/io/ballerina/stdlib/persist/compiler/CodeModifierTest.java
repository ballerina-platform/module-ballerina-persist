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
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

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

        Package currentPackage = loadPackage("package_01");

        //  Running the compilation
        currentPackage.getCompilation();

        // Running the code generation
        CodeModifierResult codeModifierResult = currentPackage.runCodeModifierPlugins();
        Package newPackage = codeModifierResult.updatedPackage().orElse(currentPackage);

        for (DocumentId documentId : newPackage.getDefaultModule().documentIds()) {
            Document document = newPackage.getDefaultModule().document(documentId);

            if (document.name().equals("sample.bal")) {
                String specificFunction =
                        "check from entity:MedicalNeed medicalNeed in mnClient->read()\n" +
                        "        where medicalNeed.quantity > 5\n" +
                        "        limit 5\n" +
                        "        order by medicalNeed.quantity descending\n" +
                        "        select {\n" +
                        "            needId: medicalNeed.needId,\n" +
                        "            period: medicalNeed.period,\n" +
                        "            quantity: medicalNeed.quantity\n" +
                        "        };";
                Assert.assertTrue(document.syntaxTree().toSourceCode().contains(specificFunction));
            }
        }
    }
}

