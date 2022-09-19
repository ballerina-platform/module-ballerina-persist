/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
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

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BTypedesc;

/**
 * This class has the utility methods.
 *
 * @since 1.0.0
 */
public class Utils {
    private Utils() {
    }

    public static BArray convertToArray(BTypedesc recordType, BArray arr) {
        ArrayType array = TypeCreator.createArrayType(recordType.getDescribingType());
        BArray returnArray = ValueCreator.createArrayValue(array);
        for (Object element: arr.getValues()) {
            if (element == null) {
                break;
            }
            returnArray.append(element);
        }
        return returnArray;
    }

}
