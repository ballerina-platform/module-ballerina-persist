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
