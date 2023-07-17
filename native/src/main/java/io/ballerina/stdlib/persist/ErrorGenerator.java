/*
 *  Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.persist;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.stdlib.persist.Constants.ERROR;
import static io.ballerina.stdlib.persist.ModuleUtils.getModule;

/**
 * This class provides the error generator methods for persistence.
 *
 * @since 1.1.0
 */
public class ErrorGenerator {

    private ErrorGenerator() {
    }

    private static BError generatePersistError(BString message, BError cause, BMap<BString, Object> details) {
        return ErrorCreator.createError(getModule(), ERROR, message, cause, details);
    }

    public static BError getBasicPersistError(String message) {
        return generatePersistError(StringUtils.fromString(message), null, null);
    }

    public static BError wrapError(BError error) {
        return generatePersistError(error.getErrorMessage(), error.getCause(), null);
    }
}
