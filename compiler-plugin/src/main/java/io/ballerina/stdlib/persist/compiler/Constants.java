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

import io.ballerina.compiler.syntax.tree.LiteralValueToken;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;

import static io.ballerina.compiler.syntax.tree.AbstractNodeFactory.createEmptyMinutiaeList;

/**
 * Constants for Persist compiler plugin.
 */
public class Constants {

    /**
     * Constants for annotation names.
     */
    public static class Annotations {
        private Annotations(){
        }

        public static final String ENTITY = "persist:Entity";
        public static final String AUTO_INCREMENT = "persist:AutoIncrement";
        public static final String RELATION = "persist:Relation";
    }

    /**
     * Constant representing Entity annotation descriptor.
     */
    public static class EntityAnnotation {
        private EntityAnnotation(){
        }

        public static final String KEY = "key";
        public static final String UNIQUE_CONSTRAINTS = "uniqueConstraints";
        public static final String TABLE_NAME = "tableName";
    }

    public static final String TRUE = "true";
    public static final String EMPTY = "";
    public static final String FALSE = "false";
    public static final String UNNECESSARY_CHARS_REGEX = "\"|\\n";
    public static final String TABLE_NAME = "tableName";
    public static final String INCREMENT = "increment";
    public static final String KEY_COLUMNS = "keyColumns";
    public static final String REFERENCE = "reference";
    public static final String ONE = "1";
    public static final String ON_DELETE = "onDelete";
    public static final String ON_UPDATE = "onUpdate";
    public static final String ONE_TO_ONE = "ONE";
    public static final String ONE_TO_MANY = "MANY";
    public static final String READ_FUNCTION = "read";
    public static final String EXECUTE_FUNCTION = "execute";
    public static final String BACKTICK = "`";
    public static final String SPACE = " ";
    public static final String OPEN_BRACES = "( ";
    public static final String CLOSE_BRACES = ") ";
    public static final String ASCENDING = "ascending";
    public static final String BAL_ESCAPE_TOKEN = "'";
    public static final String PERSIST_INHERITANCE_NODE = "*persist:AbstractPersistClient;";
    /**
     * Constants related to Ballerina types.
     */
    public static final class BallerinaTypes {
        public static final String INT = "int";
        public static final String STRING = "string";
        public static final String BOOLEAN = "boolean";
        public static final String DECIMAL = "decimal";
        public static final String FLOAT = "float";
        public static final String BYTE = "byte[]";
        public static final String DATE = "time:Date";
        public static final String TIME_OF_DAY = "time:TimeOfDay";
        public static final String UTC = "time:Utc";
        public static final String CIVIL = "time:Civil";
    }

    /**
     * SQL keywords used to construct the query.
     */
    public static final class SQLKeyWords {
        public static final String WHERE = "WHERE";
        public static final String LIMIT = "LIMIT";
        public static final String ORDERBY = "ORDER BY";
        public static final String ORDER_BY_ASCENDING = "ASC";
        public static final String ORDER_BY_DECENDING = "DESC";
        public static final String NOT_EQUAL_TOKEN = "<>";
        public static final String AND = "AND";
        public static final String OR = "OR";
    }

    /**
     * Constant nodes used in code modification.
     */
    public static final class TokenNodes {
        public static final Token INTERPOLATION_START_TOKEN = NodeFactory.createLiteralValueToken(
                SyntaxKind.INTERPOLATION_START_TOKEN, "${", createEmptyMinutiaeList(), createEmptyMinutiaeList());
        public static final Token INTERPOLATION_END_TOKEN = NodeFactory.createLiteralValueToken(
                SyntaxKind.CLOSE_BRACE_TOKEN, "}", createEmptyMinutiaeList(), createEmptyMinutiaeList());
        public static final LiteralValueToken BACKTICK_TOKEN = NodeFactory.createLiteralValueToken(
                SyntaxKind.BACKTICK_TOKEN, BACKTICK, createEmptyMinutiaeList(), createEmptyMinutiaeList());
    }

}
