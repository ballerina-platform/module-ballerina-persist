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
 * Tests persist compiler plugin.
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
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_01", 3, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid key: the given key is not in the record definition",
                        "invalid key: the given key is not in the record definition",
                        "invalid entity initialisation: the associated entity[Item] does not have the " +
                                "field with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode(),
                });
    }

    @Test
    public void testEntityAnnotation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_02", 4, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid key: the given key is not in the record definition",
                        "invalid key: the given key is not in the record definition",
                        "invalid initialization: auto increment is only allowed for primary key field",
                        "invalid entity initialisation: the associated entity[Item] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_102.getCode(),
                        DiagnosticsCodes.PERSIST_108.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testEntityAnnotation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_35", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "duplicate key/s exist: 'key' does not allow the multiple same field/s",
                        "duplicate key/s exist: 'uniqueConstraints' does not allow the multiple same field/s"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_131.getCode(),
                        DiagnosticsCodes.PERSIST_131.getCode()
                });
    }

    @Test
    public void testEntityAnnotation4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_36", 3, DiagnosticSeverity.ERROR);
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
                });
    }

    @Test
    public void testPrimaryKeyMarkReadOnly() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_03", 3, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid initialization: the field is not specified as read-only",
                        "invalid initialization: the field is not specified as read-only",
                        "invalid entity initialisation: the associated entity[Item] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_106.getCode(),
                        DiagnosticsCodes.PERSIST_106.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    //todo: This should be a MySQL specific validation
    @Test(enabled = false)
    public void testMultipleAutoIncrementAnnotation() {
       List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_04", 1, DiagnosticSeverity.ERROR);
       testDiagnostic(
               errorDiagnosticsList,
               new String[]{
                       "duplicate annotation: the entity does not allow multiple field with auto increment annotation"
               },
               new String[]{
                       DiagnosticsCodes.PERSIST_107.getCode()
               });
    }

    @Test
    public void testAutoIncrementAnnotation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_05", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid value: the value only supports positive integer",
                        "invalid entity initialisation: the associated entity[Item] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_103.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testRelationAnnotationMismatchReference() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_06", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "mismatch reference: the given key count is mismatched with reference key count",
                        "invalid entity initialisation: the associated entity[Item] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_109.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testOptionalTypeField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_07", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field type: the persist client does not support the union type",
                        "invalid entity initialisation: the associated entity[Item] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_101.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testOptionalField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_37", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: 'id' does not support optional filed initialization"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_104.getCode()
                });
    }

    @Test
    public void testAutoIncrementField() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_10", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid initialization: auto increment is only allowed for primary key field",
                        "invalid entity initialisation: the associated entity[Item] does not have the field with " +
                                "the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_108.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testFieldInitialization() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_33", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: ''persist:Entity'' does not allow an inherited field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_129.getCode()
                });
    }

    @Test
    public void testFieldInitialization1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_34", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid field initialization: ''persist:Entity'' fields can not be initialized by " +
                                "using the rest field type definition"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_130.getCode()
                });
    }

    @Test
    public void testInvalidInitialisation() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_14", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid entity initialisation: the associated entity[Item] does not have the " +
                                "field with the relationship type",
                        "invalid entity initialisation: the associated entity[Item1] does not have the field " +
                                "with the relationship type"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_115.getCode(),
                        DiagnosticsCodes.PERSIST_115.getCode()
                });
    }

    @Test
    public void testInvalidInitialisation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_15", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be attached " +
                                "to the array entity record field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_118.getCode()
                });
    }

    @Test
    public void testInvalidInitialisation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_16", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid entity initialisation: the relation annotation should only be added to the " +
                                "relationship owner for one-to-one associations"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_116.getCode()
                });
    }

    // todo check on this after relation refactoring
    @Test(enabled = false)
    public void testInvalidInitialisation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_38", 2, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value",
                        "invalid entity initialisation: the associated record[RecordTest1] is not an entity"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode(),
                        DiagnosticsCodes.PERSIST_132.getCode()
                });
    }

    @Test
    public void testUnSupportedFeature1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_22", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: array type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_120.getCode()
                });
    }

    @Test
    public void testUnSupportedFeature2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_23", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: array type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_120.getCode()
                });
    }

    @Test
    public void testUnSupportedFeature3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_24", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: json type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_121.getCode()
                });
    }

    @Test
    public void testUnSupportedFeature4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_25", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "unsupported features: json type is not supported",
                        "unsupported features: json type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_121.getCode(),
                        DiagnosticsCodes.PERSIST_121.getCode()
                });
    }

    @Test
    public void testInvalidAnnotation() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_18", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid annotation attachment: the `one-to-many` relation annotation can not be " +
                                "attached to the array entity record field"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_118.getCode()
                });
    }

    @Test
    public void testInvalidAnnotation1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_19", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "invalid annotation attachment: this non-entity type field does not allow a relation annotation"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_117.getCode()
                });
    }

    // todo: Check on this after relation validations revamp
    @Test(enabled = false)
    public void testInvalidAnnotation2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_08", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "relation annotation can only be attached to an entity record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_125.getCode()
                });
    }

    @Test
    public void testInvalidAnnotation3() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_09", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "auto increment annotation can only be attached to an entity record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_126.getCode()
                });
    }

    @Test
    public void testInvalidAnnotation4() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_32", 3, DiagnosticSeverity.ERROR);
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
                });

    }

    @Test
    public void testEntityName1() {
        List<Diagnostic> warningDiagnosticsList = getDiagnostic("package_21", 5, DiagnosticSeverity.WARNING);
        testDiagnostic(
                warningDiagnosticsList,
                new String[]{
                        "entities are defined in more than one module, move all entities to a single module",
                        "entities are defined in more than one module, move all entities to a single module",
                        "entities are defined in more than one module, move all entities to a single module",
                        "entities are defined in more than one module, move all entities to a single module",
                        "entities are defined in more than one module, move all entities to a single module"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getCode(),
                        DiagnosticsCodes.PERSIST_119.getCode()
                });
    }

    // todo -> check if valid diagnostics
    @Test(enabled = false)
    public void testGetReferenceWithCompositeKey() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_26", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity contains composite primary keys: inferring the relation reference " +
                                "from composite keys is not supported yet. "
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_122.getCode()
                });
    }

    // Unnecessary as currently we don't support entities w/o primary key
    @Test(enabled = false)
    public void testGetReferenceWithEmptyKey() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_27", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "associated entity does not contain any keys: the 'key' should have a valid value"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_123.getCode()
                });
    }

    // Unnecessary as currently we don't support entities w/o primary key
    @Test(enabled = false)
    public void testGetReferenceWithEmptyKey1() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_28", 3, DiagnosticSeverity.ERROR);
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
                });
    }

    @Test
    public void testEntityClosedRecord() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_30", 1, DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "the entity 'MedicalNeed' should be a closed record"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_124.getCode()
                });
    }

    @Test
    public void testEntityClosedRecord2() {
        List<Diagnostic> errorDiagnosticsList = getDiagnostic("package_31", 2,
                DiagnosticSeverity.ERROR);
        testDiagnostic(
                errorDiagnosticsList,
                new String[]{
                        "the entity 'MedicalNeed2' should be a closed record",
                        "unsupported features: in-line record type is not supported"
                },
                new String[]{
                        DiagnosticsCodes.PERSIST_124.getCode(),
                        DiagnosticsCodes.PERSIST_121.getCode()
                });
    }

    private List<Diagnostic> getDiagnostic(String packageName, int count, DiagnosticSeverity diagnosticSeverity) {
        DiagnosticResult diagnosticResult = loadPackage(packageName).getCompilation().diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().filter
                (r -> r.diagnosticInfo().severity().equals(diagnosticSeverity)).collect(Collectors.toList());
        Assert.assertEquals(errorDiagnosticsList.size(), count);
        return errorDiagnosticsList;

    }

    private void testDiagnostic(List<Diagnostic> errorDiagnosticsList, String[] msg, String[] code) {
        for (int index = 0; index < errorDiagnosticsList.size(); index++) {
            DiagnosticInfo error = errorDiagnosticsList.get(index).diagnosticInfo();
            Assert.assertEquals(error.code(), code[index]);
            Assert.assertTrue(error.messageFormat().startsWith(msg[index]));
        }
    }
}
