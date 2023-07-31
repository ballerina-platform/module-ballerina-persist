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
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.directory.SingleFileProject;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_101;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_102;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_201;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_202;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_301;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_302;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_303;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_304;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_305;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_306;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_307;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_308;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_401;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_402;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_403;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_404;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_405;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_406;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_420;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_422;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_501;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_502;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.TestUtils.getEnvironmentBuilder;

/**
 * Tests persist compiler plugin.
 */
public class CompilerPluginTest {

    private Package loadPersistModelFile(String directory, String name) {
        Path projectDirPath = Paths.get("src", "test", "resources", directory, "persist").
                toAbsolutePath().resolve(name);
        SingleFileProject project = SingleFileProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    @Test
    public void identifyModelFileFailure1() {
        Path projectDirPath = Paths.get("src", "test", "resources", "persist").
                toAbsolutePath().resolve("single-bal.bal");
        SingleFileProject project = SingleFileProject.load(getEnvironmentBuilder(), projectDirPath);
        DiagnosticResult diagnosticResult = project.currentPackage().getCompilation().diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 0);
    }

    @Test
    public void identifyModelFileFailure2() {
        Path projectDirPath = Paths.get("src", "test", "resources", "project_1", "resources").
                toAbsolutePath().resolve("single-bal.bal");
        SingleFileProject project = SingleFileProject.load(getEnvironmentBuilder(), projectDirPath);
        DiagnosticResult diagnosticResult = project.currentPackage().getCompilation().diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 0);
    }

    @Test
    public void skipValidationsForBalProjectFiles() {
        Path projectDirPath = Paths.get("src", "test", "resources", "project_1").
                toAbsolutePath();
        BuildProject project2 = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        DiagnosticResult diagnosticResult = project2.currentPackage().getCompilation().diagnosticResult();
        Assert.assertEquals(diagnosticResult.diagnosticCount(), 0);
    }

    @Test
    public void identifyModelFileSuccess() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "valid-persist-model-path.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_101.getCode()
                },
                new String[]{
                        "persist model definition only supports record and enum definitions"
                },
                new String[]{
                        "(2:0,3:1)"
                }
        );
    }

    @Test
    public void validateEntityRecordProperties() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "record-properties.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_201.getCode()
                },
                new String[]{
                        "an entity should be a closed record"
                },
                new String[]{
                        "(17:25,23:1)"
                }
        );
    }

    @Test
    public void validateEntityFieldProperties() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "field-properties.bal", 4);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_302.getCode(),
                        PERSIST_303.getCode(),
                        PERSIST_304.getCode(),
                        PERSIST_301.getCode()
                },
                new String[]{
                        "an entity does not support defaultable field",
                        "an entity does not support inherited field",
                        "an entity does not support optional field",
                        "an entity does not support rest descriptor field"
                },
                new String[]{
                        "(4:4,4:28)",
                        "(12:4,12:17)",
                        "(13:4,13:35)",
                        "(22:4,22:11)"
                }
        );
    }

    @Test
    public void validateEntityFieldTypeForMysql() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "field-types.bal", 10);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                },
                new String[]{
                        "an entity does not support boolean array field type",
                        "an entity does not support json-typed field",
                        "an entity does not support json array field type",
                        "an entity does not support time:Civil array field type",
                        "an entity does not support union-typed field",
                        "an entity does not support error-typed field",
                        "an entity does not support error array field type",
                        "an entity does not support mysql:Client-typed field",
                        "an entity does not support mysql:Client array field type",
                        "an entity does not support enum array field type"
                },
                new String[]{
                        "(18:4,18:13)",
                        "(20:4,20:8)",
                        "(21:4,21:10)",
                        "(24:4,24:16)",
                        "(25:4,25:21)",
                        "(27:4,27:9)",
                        "(28:4,28:11)",
                        "(30:4,30:16)",
                        "(31:4,31:18)",
                        "(34:4,34:12)"
                }
        );
    }

    @Test
    public void validateEntityFieldTypeForMssql() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_5", "field-types.bal", 10);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                },
                new String[]{
                        "an entity does not support boolean array field type",
                        "an entity does not support json-typed field",
                        "an entity does not support json array field type",
                        "an entity does not support time:Civil array field type",
                        "an entity does not support union-typed field",
                        "an entity does not support error-typed field",
                        "an entity does not support error array field type",
                        "an entity does not support mysql:Client-typed field",
                        "an entity does not support mysql:Client array field type",
                        "an entity does not support enum array field type"
                },
                new String[]{
                        "(18:4,18:13)",
                        "(20:4,20:8)",
                        "(21:4,21:10)",
                        "(24:4,24:16)",
                        "(25:4,25:21)",
                        "(27:4,27:9)",
                        "(28:4,28:11)",
                        "(30:4,30:16)",
                        "(31:4,31:18)",
                        "(34:4,34:12)"
                }
        );
    }

    @Test
    public void validateEntityFieldTypeForGoogleSheets() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_3", "field-types.bal", 12);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_308.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_306.getCode()
                },
                new String[]{
                        "an entity does not support nillable field",
                        "an entity does not support byte array field type",
                        "an entity does not support boolean array field type",
                        "an entity does not support json-typed field",
                        "an entity does not support json array field type",
                        "an entity does not support time:Civil array field type",
                        "an entity does not support union-typed field",
                        "an entity does not support error-typed field",
                        "an entity does not support error array field type",
                        "an entity does not support mysql:Client-typed field",
                        "an entity does not support mysql:Client array field type",
                        "an entity does not support enum array field type"
                },
                new String[]{
                        "(13:4,13:10)",
                        "(16:4,16:10)",
                        "(18:4,18:13)",
                        "(20:4,20:8)",
                        "(21:4,21:10)",
                        "(24:4,24:16)",
                        "(25:4,25:21)",
                        "(27:4,27:9)",
                        "(28:4,28:11)",
                        "(30:4,30:16)",
                        "(31:4,31:18)",
                        "(34:4,34:12)"
                }
        );
    }

    @Test
    public void validateEntityFieldTypeForInMemory() {
        getErrorDiagnostics("project_4", "field-types.bal", 0);
    }

    @Test
    public void validateReadonlyFieldCount() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "readonly-field.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_501.getCode()
                },
                new String[]{
                        "'MedicalNeed' entity must have at least one identity readonly field"
                },
                new String[]{
                        "(3:12,3:23)"
                }
        );
    }

    @Test
    public void validateIdentityFieldProperties() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "identifier-field-properties.bal", 3);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_502.getCode(),
                        PERSIST_503.getCode(),
                        PERSIST_503.getCode()
                },
                new String[]{
                        "an identity field cannot be nillable",
                        "only 'int', 'string', 'float', 'boolean', 'decimal' types " +
                                "are supported as identity fields, found 'time:Civil'",
                        "only 'int', 'string', 'float', 'boolean', 'decimal' types " +
                                "are supported as identity fields, found 'MedicalNeed'"
                },
                new String[]{
                        "(4:13,4:17)",
                        "(16:13,16:23)",
                        "(18:13,18:24)"
                }
        );
    }

    @Test
    public void validateSelfReferencedEntity() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "self-referenced-entity.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_401.getCode()
                },
                new String[]{
                        "an entity cannot reference itself in a relation field"
                },
                new String[]{
                        "(8:4,8:26)"
                }
        );
    }

    @Test
    public void validateNillableRelationField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "nillable-relation-field.bal", 6);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_406.getCode(),
                        PERSIST_406.getCode(),
                        PERSIST_404.getCode(),
                        PERSIST_404.getCode(),
                        PERSIST_405.getCode(),
                        PERSIST_405.getCode()
                },
                new String[]{
                        "1-n relationship does not support nillable relation field",
                        "1-n relationship does not support nillable relation field",
                        "1-1 relationship should have at least one relation field nillable " +
                                "to indicate non-owner of the relationship",
                        "1-1 relationship should have at least one relation field nillable " +
                                "to indicate non-owner of the relationship",
                        "1-1 relationship should have only one nillable relation field",
                        "1-1 relationship should have only one nillable relation field"
                },
                new String[]{
                        "(14:4,14:23)",
                        "(29:4,29:29)",
                        "(44:4,44:23)",
                        "(38:4,38:26)",
                        "(59:4,59:27)",
                        "(50:4,50:24)"
                }
        );
    }

    @Test
    public void validateManyToManyRelationship() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "many-to-many.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_420.getCode(),
                        PERSIST_420.getCode()
                },
                new String[]{
                        "many-to-many relation is not supported yet",
                        "many-to-many relation is not supported yet"
                },
                new String[]{
                        "(14:4,14:24)",
                        "(8:4,8:27)"
                }
        );
    }

    @Test
    public void validateMandatoryRelationField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "mandatory-relation-field.bal", 4);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode()
                },
                new String[]{
                        "the related entity 'Workspace' does not have the corresponding relation field",
                        "the related entity 'Building1' does not have the corresponding relation field",
                        "the related entity 'Building3' does not have the corresponding relation field",
                        "the related entity 'Workspace4' does not have the corresponding relation field"
                },
                new String[]{
                        "(8:4,8:27)",
                        "(27:4,27:23)",
                        "(58:4,58:24)",
                        "(68:4,68:27)"
                }
        );
    }

    @Test
    public void validateMandatoryMultipleRelationField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "mandatory-relation-multiple-field.bal", 6);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode()
                },
                new String[]{
                        "the related entity 'Workspace' does not have the corresponding relation field",
                        "the related entity 'Workspace' does not have the corresponding relation field",
                        "the related entity 'Building1' does not have the corresponding relation field",
                        "the related entity 'Building1' does not have the corresponding relation field",
                        "the related entity 'Building3' does not have the corresponding relation field",
                        "the related entity 'Workspace4' does not have the corresponding relation field"
                },
                new String[]{
                        "(8:4,8:27)",
                        "(9:4,9:24)",
                        "(28:4,28:23)",
                        "(29:4,29:23)",
                        "(64:4,64:27)",
                        "(75:4,75:28)"
                }
        );
    }

    @Test
    public void validatePresenceOfForeignKeyField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "foreign-key-present.bal", 4);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_422.getCode(),
                        PERSIST_422.getCode(),
                        PERSIST_422.getCode(),
                        PERSIST_422.getCode()
                },
                new String[]{
                        "the entity should not contain foreign key field " +
                                "'buildingBuildingCode' for relation 'Building'",
                        "the entity should not contain foreign key field " +
                                "'locationBuildingCode' for relation 'Building2'",
                        "the entity should not contain foreign key field " +
                                "'workspacesWorkspaceId' for relation 'Workspace3'",
                        "the entity should not contain foreign key field " +
                                "'workspacesWorkspaceId' for relation 'Workspace4'"
                },
                new String[]{
                        "(15:4,15:32)",
                        "(22:4,22:32)",
                        "(42:4,42:33)",
                        "(66:4,66:33)"
                }
        );
    }

    @Test
    public void validateInvalidRelations() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "invalid-relation.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_101.getCode(),
                        PERSIST_306.getCode()
                },
                new String[]{
                        "persist model definition only supports record and enum definitions",
                        "an entity does not support Integer array field type"
                },
                new String[]{
                        "(2:0,2:17)",
                        "(10:4,10:13)"
                }
        );
    }

    @Test
    public void validateDifferentOwners() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "different-owners.bal", 10);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode()
                },
                new String[]{
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner",
                        "All relation between two entities should have a single owner"
                },
                new String[]{
                        "(15:4,15:22)",
                        "(8:4,8:27)",
                        "(16:4,16:23)",
                        "(9:4,9:24)",
                        "(33:4,33:23)",
                        "(25:4,25:27)",
                        "(34:4,34:25)",
                        "(26:4,26:25)",
                        "(35:4,35:24)",
                        "(27:4,27:28)",

                }
        );
    }

    @Test
    public void validateUseOfEscapeCharacters() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "usage-of-escape-characters.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_422.getCode()
                },
                new String[]{
                        "the entity should not contain foreign key field 'locationBuildingCode' for relation 'Building'"
                },
                new String[]{
                        "(18:4,18:33)"
                }
        );
    }

    @Test
    public void validateUseOfImportPrefix() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "usage-of-import-prefix.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_305.getCode(),
                        PERSIST_102.getCode()
                },
                new String[]{
                        "an entity does not support time2:Date-typed field",
                        "persist model definition does not support import prefix"
                },
                new String[]{
                        "(9:4,9:14)",
                        "(0:22,0:30)"
                }
        );
    }

    @Test
    public void validateEntityNamesCaseSensitivity() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("project_2", "case-sensitive-entities.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_202.getCode(),
                        PERSIST_307.getCode()
                },
                new String[]{
                        "redeclared entity 'building'",
                        "redeclared field 'Location'"
                },
                new String[]{
                        "(12:5,12:13)",
                        "(27:11,27:19)"
                }
        );
    }

    private List<Diagnostic> getErrorDiagnostics(String modelDirectory, String modelFileName, int count) {
        DiagnosticResult diagnosticResult = loadPersistModelFile(modelDirectory, modelFileName).getCompilation()
                .diagnosticResult();
        List<Diagnostic> errorDiagnosticsList = diagnosticResult.diagnostics().stream().filter
                (r -> r.diagnosticInfo().severity().equals(DiagnosticSeverity.ERROR)).collect(Collectors.toList());
        Assert.assertEquals(errorDiagnosticsList.size(), count);
        return errorDiagnosticsList;
    }


    private void testDiagnostic(List<Diagnostic> errorDiagnosticsList, String[] codes, String[] messages,
                                String[] locations) {
        for (int index = 0; index < errorDiagnosticsList.size(); index++) {
            Diagnostic diagnostic = errorDiagnosticsList.get(index);
            DiagnosticInfo diagnosticInfo = diagnostic.diagnosticInfo();
            Assert.assertEquals(diagnosticInfo.code(), codes[index]);
            Assert.assertTrue(diagnosticInfo.messageFormat().startsWith(messages[index]));
            String location = diagnostic.location().lineRange().toString();
            Assert.assertEquals(location, locations[index]);
        }
    }
}
