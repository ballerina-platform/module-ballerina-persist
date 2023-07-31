/*
 * Copyright (c) 2023, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
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
package io.ballerina.stdlib.persist.plural;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Transforms english words from singular to plural form.
 */
public class Pluralizer {

    private Pluralizer() {}

    public static String pluralize(String word) {
        for (String rule : Rules.UNCOUNTABLE_RULES) {
            if (Pattern.matches(rule, word)) {
                return word;
            }
        }
        for (String[] irregularRule: Rules.IRREGULAR_RULES) {
            if (irregularRule[1].equals(word)) {
                return word;
            }
            if (irregularRule[0].equals(word)) {
                return irregularRule[1];
            }
        }
        for (String[] pluralizationRule: Rules.PLURALIZATION_RULES) {
            Matcher matcher = Pattern.compile(pluralizationRule[0]).matcher(word);
            if (matcher.find()) {
                return matcher.replaceFirst(pluralizationRule[1]);
            }
        }
        return word;
    }
}
