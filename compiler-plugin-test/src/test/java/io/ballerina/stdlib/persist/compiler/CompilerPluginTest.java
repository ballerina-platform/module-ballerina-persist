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
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_401;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_402;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_403;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_420;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_421;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_422;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_501;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_502;
import static io.ballerina.stdlib.persist.compiler.DiagnosticsCodes.PERSIST_503;
import static io.ballerina.stdlib.persist.compiler.TestUtils.getEnvironmentBuilder;

/**
 * Tests persist compiler plugin.
 */
public class CompilerPluginTest {

    private Package loadPersistModelFile(String name) {
        Path projectDirPath = Paths.get("src", "test", "resources", "project_2", "persist").
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
        List<Diagnostic> diagnostics = getErrorDiagnostics("valid-persist-model-path.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_101.getCode()
                },
                new String[]{
                        "persist model definition only supports record definitions"
                },
                new String[]{
                        "(2:0,3:1)"
                }
        );
    }

    @Test
    public void validateEntityRecordProperties() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("record-properties.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_201.getCode()
                },
                new String[]{
                        "an entity should be a closed record"
                },
                new String[]{
                        "(11:25,17:1)"
                }
        );
    }

    @Test
    public void validateEntityFieldProperties() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("field-properties.bal", 4);
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
    public void validateEntityFieldType() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("field-types.bal", 5);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_305.getCode(),
                        PERSIST_306.getCode(),
                        PERSIST_305.getCode()
                },
                new String[]{
                        "an entity does not support boolean array field type",
                        "an entity does not support json-typed field",
                        "an entity does not support json[]-typed field",
                        "an entity does not support time:Civil array field type",
                        "an entity does not support union-typed field"
                },
                new String[]{
                        "(12:4,12:13)",
                        "(14:4,14:8)",
                        "(15:4,15:10)",
                        "(18:4,18:16)",
                        "(19:4,19:21)"
                }
        );
    }

    @Test
    public void validateReadonlyFieldCount() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("readonly-field.bal", 1);
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
        List<Diagnostic> diagnostics = getErrorDiagnostics("identifier-field-properties.bal", 3);
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
        List<Diagnostic> diagnostics = getErrorDiagnostics("self-referenced-entity.bal", 1);
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
    public void validateManyToManyRelationship() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("many-to-many.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_420.getCode()
                },
                new String[]{
                        "many-to-many relation is not supported yet"
                },
                new String[]{
                        "(14:4,14:24)"
                }
        );
    }

    @Test
    public void validateMandatoryRelationField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("mandatory-relation-field.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_402.getCode(),
                        PERSIST_402.getCode()
                },
                new String[]{
                        "the related entity 'Workspace' does not have the Building-typed relation field",
                        "the related entity 'Building1' does not have the Workspace2-typed relation field"
                },
                new String[]{
                        "(8:4,8:27)",
                        "(27:4,27:23)"
                }
        );
    }

    @Test
    public void validateDuplicatedRelationField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("duplicated-relations-field.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_403.getCode(),
                        PERSIST_403.getCode()
                },
                new String[]{
                        "the entity does not support duplicated relations to 'Workspace' entity",
                        "the entity does not support duplicated relations to 'Building1' entity"
                },
                new String[]{
                        "(9:4,9:28)",
                        "(31:4,31:24)"
                }
        );
    }

    @Test
    public void validatePresenceOfForeignKeyField() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("foreign-key-present.bal", 4);
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
                                "'building2BuildingCode' for relation 'Building2'",
                        "the entity should not contain foreign key field " +
                                "'workspace3WorkspaceId' for relation 'Workspace3'",
                        "the entity should not contain foreign key field " +
                                "'building4BuildingCode' for relation 'Building4'"
                },
                new String[]{
                        "(15:4,15:32)",
                        "(22:4,22:33)",
                        "(42:4,42:33)",
                        "(56:4,56:33)"
                }
        );
    }

    @Test
    public void validateInvalidRelations() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("invalid-relation.bal", 2);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_101.getCode(),
                        PERSIST_305.getCode()
                },
                new String[]{
                        "persist model definition only supports record definitions",
                        "an entity does not support Integer[]-typed field"
                },
                new String[]{
                        "(2:0,2:17)",
                        "(10:4,10:13)"
                }
        );
    }

    @Test
    public void validateOptionalAssociation() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("optional-association.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_421.getCode()
                },
                new String[]{
                        "an entity does not support nillable relations"
                },
                new String[]{
                        "(14:4,14:13)"
                }
        );
    }

    @Test
    public void validateUseOfEscapeCharacters() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("usage-of-escape-characters.bal", 1);
        testDiagnostic(
                diagnostics,
                new String[]{
                        PERSIST_422.getCode()
                },
                new String[]{
                        "the entity should not contain foreign key field 'buildingBuildingCode' for relation 'Building'"
                },
                new String[]{
                        "(18:4,18:33)"
                }
        );
    }

    @Test
    public void validateUseOfImportPrefix() {
        List<Diagnostic> diagnostics = getErrorDiagnostics("usage-of-import-prefix.bal", 2);
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
        List<Diagnostic> diagnostics = getErrorDiagnostics("case-sensitive-entities.bal", 2);
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

    private List<Diagnostic> getErrorDiagnostics(String modelFileName, int count) {
        DiagnosticResult diagnosticResult = loadPersistModelFile(modelFileName).getCompilation().diagnosticResult();
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
