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
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_01");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid key: the given key is not in the record definition",
                        "invalid key: the given key is not in the record definition"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_102.getCode()
                },
                2);
    }

    @Test
    public void testEntityAnnotation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_02");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid key: the given key is not in the record definition",
                        "invalid key: the given key is not in the record definition",
                        "invalid initialization: auto increment is only allowed for primary key field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_108.getCode()
                },
                3);
    }

    @Test
    public void testEntityAnnotation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_35");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "duplicate key/s exist: 'key' does not allow the multiple same field/s",
                        "duplicate key/s exist: 'uniqueConstraints' does not allow the multiple same field/s"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_131.getCode(),
                        DiagnosticsCodes.PERSIST_131.getCode()
                },
                2);
    }

    @Test
    public void testEntityAnnotation4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_36");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value",
                        "associated entity does not contain any keys: the 'uniqueConstraints' " +
                                "should have a valid value",
                        "associated entity does not contain any keys: the 'uniqueConstraints' " +
                                "should have a valid value",
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_123.getCode()
                },
                3);
    }

    @Test
    public void testPrimaryKeyMarkReadOnly() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_03");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid initialization: the field is not specified as read-only",
                        "invalid initialization: the field is not specified as read-only"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_106.getCode(),
                        DiagnosticsCodes.PERSIST_106.getCode()
                },
                2);
    }

    //todo: Should this be a validation
    @Test(enabled = false)
    public void testMultipleAutoIncrementAnnotation() {
       List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_04");
       testDiagnostic(
               errorDiagnosticsList,
               new String[]{
                       "duplicate annotation: the entity does not allow multiple field with auto increment annotation"
               },
               new String[]{
                       DiagnosticsCodes.PERSIST_107.getCode()
               },
               1);
    }

    @Test
    public void testAutoIncrementAnnotation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_05");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid value: the value only supports positive integer"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_103.getCode()
                },
                1);
    }

    @Test
    public void testRelationAnnotationMismatchReference() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_06");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "mismatch reference: the given key count is mismatched with reference key count"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_109.getCode()
                },
                1);
    }

    @Test
    public void testOptionalTypeField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_07");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field type: the persist client does not support the union type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_101.getCode()
                },
                1);
    }

    @Test
    public void testOptionalField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_37");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: 'id' does not support optional filed initialization"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_104.getCode()
                },
                1);
    }

    @Test
    public void testAutoIncrementField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_10");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid initialization: auto increment is only allowed for primary key field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_108.getCode()
                },
                1);
    }

    @Test
    public void testFieldInitialization() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_33");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: ''persist:Entity'' does not allow an inherited field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_129.getCode()
                },
                1);
    }

    @Test
    public void testFieldInitialization1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_34");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: ''persist:Entity'' fields can not be initialized by " +
                                "using the rest field type definition"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_130.getCode()
                },
                1);
    }

    @Test
    public void testTableName() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_13");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "duplicate table name: the table name is already used in another entity in"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_113.getCode()
                },
                1);
    }

    @Test
    public void testTableName1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_20");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "duplicate table name: the table name is already used in another entity in "
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_113.getCode()
                },
                1);
    }

    @Test
    public void testInvalidInitialisation() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_14");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid entity initialisation: the associated entity[Item] does not have the " +
                                "field with the relationship type",
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be " +
                                "attached to the array entity record field",
                        "invalid entity initialisation: the associated entity[Item1] does not have the " +
                                "field with the relationship type",
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be attached " +
                                "to the array entity record field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_115.getCode(),
                        DiagnosticsCodes.PERSIST_118.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode(),
                        DiagnosticsCodes.PERSIST_118.getCode()
                },
                4);
    }

    @Test
    public void testInvalidInitialisation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_15");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid entity initialisation: the relation annotation should only be added to the " +
                                "relationship owner for one-to-one and one-to-many associations",
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be attached " +
                                "to the array entity record field",
                        "invalid entity initialisation: the relation annotation should only be added to the " +
                                "relationship owner for one-to-one and one-to-many associations"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_116.getCode(),
                        DiagnosticsCodes.PERSIST_118.getCode(),
                        DiagnosticsCodes.PERSIST_116.getCode()
                },
                3);
    }

    @Test
    public void testInvalidInitialisation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_16");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid entity initialisation: the relation annotation should only be added to the " +
                                "relationship owner for one-to-one and one-to-many associations",
                        "invalid entity initialisation: the relation annotation should only be added to " +
                                "the relationship owner for one-to-one and one-to-many associations"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_116.getCode(),
                        DiagnosticsCodes.PERSIST_116.getCode()
                },
                2);
    }

    // todo check on this after relation refactoring
    @Test(enabled = false)
    public void testInvalidInitialisation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_38");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value",
                        "invalid entity initialisation: the associated entity[RecordTest1] is not an entity"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_132.getCode()
                },
                2);
    }

    @Test
    public void testUnSupportedFeature() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_17");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: many-to-many association is not supported yet",
                        "invalid entity initialisation: the relation annotation should only be " +
                                "added to the relationship owner for one-to-one and one-to-many associations",
                        "unsupported features: many-to-many association is not supported yet",
                        "invalid entity initialisation: the relation annotation should only be added " +
                                "to the relationship owner for one-to-one and one-to-many associations"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_114.getCode(),
                        DiagnosticsCodes.PERSIST_116.getCode(),
                        DiagnosticsCodes.PERSIST_114.getCode(),
                        DiagnosticsCodes.PERSIST_116.getCode()
                },
                4);
    }

    @Test
    public void testUnSupportedFeature1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_22");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: array type is not supported",
                        "unsupported features: array type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_120.getCode(),
                        DiagnosticsCodes.PERSIST_120.getCode()
                },
                2);
    }

    @Test
    public void testUnSupportedFeature2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_23");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: array type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_120.getCode()
                },
                1);
    }

    @Test
    public void testUnSupportedFeature3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_24");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: json type is not supported",
                        "unsupported features: json type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_121.getCode(),
                        DiagnosticsCodes.PERSIST_121.getCode()
                },
                2);
    }

    @Test
    public void testUnSupportedFeature4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_25");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: json type is not supported",
                        "unsupported features: json type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_121.getCode(),
                        DiagnosticsCodes.PERSIST_121.getCode()
                },
                2);
    }

    @Test
    public void testInvalidAnnotation() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_18");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be " +
                                "attached to the array entity record field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_118.getCode()
                },
                1);
    }

    @Test
    public void testInvalidAnnotation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_19");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid annotation attachment: this non-entity type field does not allow a relation annotation"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_117.getCode()
                },
                1);
    }

    // todo: Check on this after relation validations revamp
    @Test(enabled = false)
    public void testInvalidAnnotation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_08");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "relation annotation can only be attached to an entity record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_125.getCode()
                },
                1);
    }

    @Test
    public void testInvalidAnnotation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_09");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "auto increment annotation can only be attached to an entity record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_126.getCode()
                },
                1);
    }

    @Test
    public void testInvalidAnnotation4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_32");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid attachment: ''persist:Entity'' annotation is only allowed on record type description",
                        "invalid attachment: ''persist:Entity'' annotation is only allowed on record type description",
                        "invalid attachment: ''persist:Entity'' annotation is only allowed on record type description"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_128.getCode(),
                        DiagnosticsCodes.PERSIST_128.getCode(),
                        DiagnosticsCodes.PERSIST_128.getCode()
                },
                3);

    }

    @Test
    public void testEntityName1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_21");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "duplicate entity names are not allowed: the specified name is already " +
                                "used in another entity in ",
                        "duplicate entity names are not allowed: the specified name is already " +
                                "used in another entity in "
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getCode()
                },
                2);
    }

    @Test
    public void testGetReferenceWithCompositeKey() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_26");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity contains composite primary keys: inferring the relation reference " +
                                "from composite keys is not supported yet. "
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_122.getCode()
                },
                1);
    }

    @Test
    public void testGetReferenceWithEmptyKey() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_27");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode()
                },
                1);
    }

    @Test
    public void testGetReferenceWithEmptyKey1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_28");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value",
                        "associated entity does not contain any keys: the 'key' should have a valid value",
                        "associated entity does not contain any keys: the 'key' should have a valid value"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_123.getCode()
                },
                3);
    }

    @Test
    public void testEntityClosedRecord() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_30");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "the entity 'MedicalNeed' should be a closed record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_124.getCode()
                },
                1);
    }

    @Test
    public void testEntityClosedRecord2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_31");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: in-line record type is not supported",
                        "the entity 'MedicalNeed2' should be a closed record",
                        "unsupported features: in-line record type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_121.getCode(),
                        DiagnosticsCodes.PERSIST_124.getCode(),
                        DiagnosticsCodes.PERSIST_121.getCode()
                },
                3);
    }

    @Test
    public void testFieldInitialisation() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_12");
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "'keyColumns' field only allows inline initialisation",
                        "'reference' field only allows inline initialisation",
                        "'key' field only allows inline initialisation",
                        "'uniqueConstraints' field only allows inline initialisation",
                        "'tableName' field only allows inline initialisation",
                        "invalid initialization: auto increment is only allowed for primary key field",
                        "'startValue ' field only allows inline initialisation",
                        "'increment' field only allows inline initialisation"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_108.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode(),
                        DiagnosticsCodes.PERSIST_127.getCode()
                },
                8);
    }

    private List<Diagnostic> getDiagnostic(String packageName) {
        DiagnosticResult diagnosticResult = loadPackage(packageName).getCompilation().diagnosticResult();
        return diagnosticResult.diagnostics().stream().filter(r -> r.diagnosticInfo().severity().
                        equals(DiagnosticSeverity.ERROR)).collect(Collectors.toList());

    }

    private void testDiagnostic(List<Diagnostic> errorDiagnosticsList, String[] msg, String[] code, int count) {
        Assert.assertEquals(errorDiagnosticsList.size(), count);
        for (int index = 0; index < errorDiagnosticsList.size(); index++) {
            DiagnosticInfo error = errorDiagnosticsList.get(index).diagnosticInfo();
            Assert.assertEquals(error.code(), code[index]);
            Assert.assertTrue(error.messageFormat().startsWith(msg[index]));
        }
    }
}
