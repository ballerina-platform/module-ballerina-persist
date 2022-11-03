/*
 * Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.persist.compiler.codeaction.diagnostic;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 *
 */
public class FileUtils {

    private static final JsonParser JSON_PARSER = new JsonParser();

    public static final Path RES_DIR = Paths.get("src/test/resources/").toAbsolutePath();
    public static final Path BUILD_DIR = Paths.get("build/").toAbsolutePath();

    /**
     * Get the file content.
     * @param filePath path to the file
     * @return {@link JsonObject} file content as a jsonObject
     */
    public static JsonObject fileContentAsObject(String filePath) {
        String contentAsString = "";
        try {
            contentAsString = Files.readString(RES_DIR.resolve(filePath), Charset.defaultCharset());
        } catch (IOException ex) {
            //
        }
        return JSON_PARSER.parse(contentAsString).getAsJsonObject();
    }
}
