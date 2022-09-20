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

package io.ballerina.stdlib.persist.compiler.script;

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
 * Tests for sql script generator.
 */
public class CompilerPluginTest {

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Path distributionPath = Paths.get("../", "target", "ballerina-runtime")
                .toAbsolutePath();
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(distributionPath).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private Package loadPackage(String path) {
        Path projectDirPath = Paths.get("src", "test", "resources", "test-src", "sql_script").
                toAbsolutePath().resolve(path);
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        return project.currentPackage();
    }

    @Test
    public void testGenerateSqlScript() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS Medical_Need;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 15;\n" +
                "\n" +
                "CREATE TABLE Medical_Need (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191),\n" +
                "\turgency VARCHAR(191),\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICAL_NEED_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(needId)\n" +
                ")\tAUTO_INCREMENT = 12;";
        testSqlScript("package_01", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript1() throws IOException {
        String content = "DROP TABLE IF EXISTS MedicalNeed;\n" +
                "CREATE TABLE MedicalNeed (\n" +
                "\tneedId INT NOT NULL,\n" +
                "\titemId INT NOT NULL,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL\n" +
                ");";
        testSqlScript("package_02", content, 0, "");
    }

    @Test
    public void testGenerateSqlScript2() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS Medical_Need;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Medicine;\n" +
                "CREATE TABLE Medicine (\n" +
                "\tid INT NOT NULL,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tUNIQUE KEY(id)\n" +
                ");\n" +
                "\n" +
                "CREATE TABLE Medical_Need (\n" +
                "\tneedId INT NOT NULL,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191),\n" +
                "\turgency VARCHAR(191),\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICAL_NEED_MEDICINE_0 FOREIGN KEY(itemId) REFERENCES Medicine(id) ON " +
                "DELETE CASCADE\n" +
                ");";
        testSqlScript("package_03", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript3() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS Medical_Need2;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Medicine2;\n" +
                "CREATE TABLE Medicine2 (\n" +
                "\tid INT NOT NULL,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tUNIQUE KEY(id)\n" +
                ");\n" +
                "\n" +
                "CREATE TABLE Medical_Need2 (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191),\n" +
                "\turgency VARCHAR(191),\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICAL_NEED2_MEDICINE2_0 FOREIGN KEY(itemId) REFERENCES Medicine2(id) " +
                "ON DELETE CASCADE ON UPDATE CASCADE,\n" +
                "\tPRIMARY KEY(needId)\n" +
                ")\tAUTO_INCREMENT = 12;";
        testSqlScript("package_04", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript4() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS EMPLOYEE;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "CREATE TABLE Item (\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tPRIMARY KEY(id)\n" +
                ");\n" +
                "\n" +
                "CREATE TABLE EMPLOYEE (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_EMPLOYEE_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId)\n" +
                ");";
        testSqlScript("package_05", fileContent, 1,
                "mysql db only allow increment value by one in auto generated field");
    }

    @Test
    public void testGenerateSqlScript5() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item1;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item2;\n" +
                "CREATE TABLE Item2 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id),\n" +
                "\tUNIQUE KEY(name)\n" +
                ")\tAUTO_INCREMENT = 2;\n" +
                "\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_ITEM1_ITEM2_0 FOREIGN KEY(itemId) REFERENCES Item2(id) ON DELETE CASCADE,\n" +
                "\titemName VARCHAR(191),\n" +
                "\tCONSTRAINT FK_ITEM1_ITEM2_1 FOREIGN KEY(itemName) REFERENCES Item2(name) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(id),\n" +
                "\tUNIQUE KEY(name)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id),\n" +
                "\tUNIQUE KEY(name)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tname VARCHAR(191),\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_1 FOREIGN KEY(name) REFERENCES Item(name) ON DELETE CASCADE,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tname1 VARCHAR(191),\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM1_1 FOREIGN KEY(name1) REFERENCES Item1(name) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_06", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript6() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item1;\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_07", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript7() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS Item1;\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_ITEM_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_08", fileContent, 0, "");
    }

    //@Test
    public void testGenerateSqlScript8() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item1;\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_ITEM_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_09", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript9() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS MedicalItem;\n" +
                "CREATE TABLE MedicalItem (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\titemId INT NOT NULL,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\tPRIMARY KEY(needId)\n" +
                ");\n" +
                "\n" +
                "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item1;\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_ITEM_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_10", fileContent, 0, "");
    }

    @Test
    public void testGenerateSqlScript91() throws IOException {
        String fileContent = "DROP TABLE IF EXISTS MedicalItem;\n" +
                "CREATE TABLE MedicalItem (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\titemId INT NOT NULL,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\tPRIMARY KEY(needId)\n" +
                ");\n" +
                "\n" +
                "DROP TABLE IF EXISTS MedicalItem1;\n" +
                "CREATE TABLE MedicalItem1 (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\titemId INT NOT NULL,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\tPRIMARY KEY(needId)\n" +
                ");\n" +
                "\n" +
                "DROP TABLE IF EXISTS MedicalNeeds;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item;\n" +
                "\n" +
                "DROP TABLE IF EXISTS Item1;\n" +
                "CREATE TABLE Item1 (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 5;\n" +
                "\n" +
                "CREATE TABLE Item (\n" +
                "\tid INT NOT NULL AUTO_INCREMENT,\n" +
                "\tname VARCHAR(191) NOT NULL,\n" +
                "\titemId1 INT,\n" +
                "\tCONSTRAINT FK_ITEM_ITEM1_0 FOREIGN KEY(itemId1) REFERENCES Item1(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(id)\n" +
                ")\tAUTO_INCREMENT = 3;\n" +
                "\n" +
                "CREATE TABLE MedicalNeeds (\n" +
                "\tneedId INT NOT NULL AUTO_INCREMENT,\n" +
                "\tbeneficiaryId INT NOT NULL,\n" +
                "\tperiod VARCHAR(191) NOT NULL,\n" +
                "\turgency VARCHAR(191) NOT NULL,\n" +
                "\tquantity INT NOT NULL,\n" +
                "\titemId INT,\n" +
                "\tCONSTRAINT FK_MEDICALNEEDS_ITEM_0 FOREIGN KEY(itemId) REFERENCES Item(id) ON DELETE CASCADE,\n" +
                "\tPRIMARY KEY(needId),\n" +
                "\tUNIQUE KEY(beneficiaryId, urgency)\n" +
                ");";
        testSqlScript("package_11", fileContent, 0, "");
    }

    private void testSqlScript(String packagePath, String fileContent, int count,
                               String warningMsg) throws IOException {
        Package currentPackage = loadPackage(packagePath);
        Path directoryPath = currentPackage.project().targetDir().toAbsolutePath();
        Path filePath = Path.of(directoryPath + "/persist_db_scripts.sql");
        assertTest(currentPackage.getCompilation().diagnosticResult(), filePath, fileContent, count, warningMsg);
        Files.deleteIfExists(filePath);
        Files.deleteIfExists(directoryPath);
    }

    private void assertTest(DiagnosticResult result, Path path, String fileContent, int count, String warningMsg) {
        Assert.assertEquals(result.diagnostics().size(), count);
        if (count > 0) {
            Assert.assertTrue(result.warnings().toArray()[0].toString().contains(warningMsg));
        }
        Assert.assertTrue(Files.exists(path), "The file doesn't exist");
        try {
            Assert.assertSame(Files.readString(path), fileContent, "The file content mismatched");
        } catch (IOException e) {
            Assert.fail("Error: " + e.getMessage());
        }
    }
}
