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

import java.util.Arrays;
import java.util.List;

/**
 * Rules for singular to plural.
 */
public class Rules {

    private Rules() {}

    // Irregular rules.
    static final String[][] IRREGULAR_RULES = (new String[][] {
            {"i", "we"},
            {"me", "us"},
            {"he", "they"},
            {"she", "they"},
            {"them", "them"},
            {"myself", "ourselves"},
            {"yourself", "yourselves"},
            {"itself", "themselves"},
            {"herself", "themselves"},
            {"himself", "themselves"},
            {"themself", "themselves"},
            {"is", "are"},
            {"was", "were"},
            {"has", "have"},
            {"this", "these"},
            {"that", "those"},
            {"my", "our"},
            {"its", "their"},
            {"his", "their"},
            {"her", "their"},
            // Words ending in with a consonant and `o`.
            {"echo", "echoes"},
            {"dingo", "dingoes"},
            {"volcano", "volcanoes"},
            {"tornado", "tornadoes"},
            {"torpedo", "torpedoes"},
            // Ends with `us`.
            {"genus", "genera"},
            {"viscus", "viscera"},
            // Ends with `ma`.
            {"stigma", "stigmata"},
            {"stoma", "stomata"},
            {"dogma", "dogmata"},
            {"lemma", "lemmata"},
            {"schema", "schemata"},
            {"anathema", "anathemata"},
            // Other irregular rules.
            {"ox", "oxen"},
            {"axe", "axes"},
            {"die", "dice"},
            {"yes", "yeses"},
            {"foot", "feet"},
            {"eave", "eaves"},
            {"goose", "geese"},
            {"tooth", "teeth"},
            {"quiz", "quizzes"},
            {"human", "humans"},
            {"proof", "proofs"},
            {"carve", "carves"},
            {"valve", "valves"},
            {"looey", "looies"},
            {"thief", "thieves"},
            {"groove", "grooves"},
            {"pickaxe", "pickaxes"},
            {"passerby", "passersby"},
            {"canvas", "canvases"}
    });

    // Pluralization rules.
    static final String[][] PLURALIZATION_RULES = (new String[][]{
            {"[^\u0000-\u007F]$", "$0"},
            {"([^aeiou]ese)$", "$1"},
            {"(ax|test)is$", "$1es"},
            {"(alias|[^aou]us|t[lm]as|gas|ris)$", "$1es"},
            {"(e[mn]u)s?$", "$1s"},
            {"([^l]ias|[aeiou]las|[ejzr]as|[iu]am)$", "$1"},
            {"(alumn|syllab|vir|radi|nucle|fung|cact|stimul|termin|bacill|foc|uter|loc|strat)(?:us|i)$", "$1i"},
            {"(alumn|alg|vertebr)(?:a|ae)$", "$1ae"},
            {"(seraph|cherub)(?:im)?$", "$1im"},
            {"(her|at|gr)o$", "$1oes"},
            {"(agend|addend|millenni|dat|extrem|bacteri|desiderat|strat|candelabr|errat|ov|" +
                    "symposi|curricul|automat|quor)(?:a|um)$", "$1a"},
            {"(apheli|hyperbat|periheli|asyndet|noumen|phenomen|criteri|organ|prolegomen|" +
                    "hedr|automat)(?:a|on)$", "$1a"},
            {"sis$", "ses"},
            {"(?:(kni|wi|li)fe|(ar|l|ea|eo|oa|hoo)f)$", "$1$2ves"},
            {"([^aeiouy]|qu)y$", "$1ies"},
            {"([^ch][ieo][ln])ey$", "$1ies"},
            {"(x|ch|ss|sh|zz)$", "$1es"},
            {"(matr|cod|mur|sil|vert|ind|append)(?:ix|ex)$", "$1ices"},
            {"\b((?:tit)?m|l)(?:ice|ouse)$", "$1ice"},
            {"(pe)(?:rson|ople)$", "$1ople"},
            {"(child)(?:ren)?$", "$1ren"},
            {"eaux$", "$0"},
            {"m[ae]n$", "men"},
            {"thou", "you"},
            {"s?$", "s"}
    });

    // Uncountable rules.
    static final List<String> UNCOUNTABLE_RULES = Arrays.asList(
            // Singular words with no plurals.
            "adulthood", "advice", "agenda", "aid", "aircraft", "alcohol", "ammo", "analytics", "anime",
            "athletics", "audio", "bison", "blood", "bream", "buffalo", "butter", "carp", "cash", "chassis",
            "chess", "clothing", "cod", "commerce", "cooperation", "corps", "debris", "diabetes", "digestion",
            "elk", "energy", "equipment", "excretion", "expertise", "firmware", "flounder", "fun", "gallows",
            "garbage", "graffiti", "hardware", "headquarters", "health", "herpes", "highjinks", "homework",
            "housework", "information", "jeans", "justice", "kudos", "labour", "literature", "machinery",
            "mackerel", "mail", "media", "mews", "moose", "music", "mud", "manga", "news", "only", "personnel",
            "pike", "plankton", "pliers", "police", "pollution", "premises", "rain", "research", "rice",
            "salmon", "scissors", "series", "sewage", "shambles", "shrimp", "software", "staff", "swine",
            "tennis", "traffic", "transportation", "trout", "tuna", "wealth", "welfare", "whiting", "wildebeest",
            "wildlife", "you", "^[a-z]*pok[eé]mon$",
            // Regexes.
            "^[a-z]*[^aeiou]ese$", // "chinese", "japanese"
            "^[a-z]*deer$", // "deer", "reindeer"
            "^[a-z]*fish$", // "fish", "blowfish", "angelfish"
            "^[a-z]*measles$",
            "^[a-z]*o[iu]s$", // "carnivorous"
            "^[a-z]*pox$", // "chickpox", "smallpox"
            "^[a-z]*sheep$"
    );
}
