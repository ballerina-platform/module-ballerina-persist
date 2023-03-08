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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BFuture;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BStream;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerina.stdlib.persist.Utils.getFieldsAndIncludes;
import static io.ballerina.stdlib.persist.Utils.getFutureResult;
import static io.ballerina.stdlib.persist.Utils.getPersistClient;

/**
 * This class provides the query processing implementations for persistence.
 *
 * @since 0.5.6
 */
public class QueryProcessor {

    private QueryProcessor() {
    }

    public static BStream query(Environment env, BObject client, BTypedesc recordType, BString entity) {
        BObject persistClient = getPersistClient(client, entity);

        RecordType streamConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());
        StreamType streamType = TypeCreator.createStreamType(streamConstraint, PredefinedTypes.TYPE_NULL);

        BArray[] fieldsAndIncludes = getFieldsAndIncludes((RecordType) recordType.getDescribingType());
        BArray fields = fieldsAndIncludes[0];
        BArray includes = fieldsAndIncludes[1];

        BFuture future = env.getRuntime().invokeMethodAsyncSequentially(
                persistClient, Constants.RUN_READ_QUERY_METHOD,
                null, null, null, null, streamType,
                recordType, true, fields, true, includes, true
        );

        BStream sqlStream = (BStream) getFutureResult(future);
        BObject persistStream = ValueCreator.createObjectValue(ModuleUtils.getModule(),
                Constants.PERSIST_STREAM, sqlStream, null, includes, persistClient);

        return ValueCreator.createStreamValue(TypeCreator.createStreamType(streamConstraint,
                PredefinedTypes.TYPE_NULL), persistStream);
    }

    public static Object queryOne(Environment env, BObject client, BString key, BTypedesc recordType,
                                  BString entity) {
        RecordType recordConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());

        BArray[] fieldsAndIncludes = getFieldsAndIncludes((RecordType) recordType.getDescribingType());

        BFuture future = env.getRuntime().invokeMethodAsyncSequentially(
                getPersistClient(client, entity), Constants.RUN_READ_BY_KEY_QUERY_METHOD,
                null, null, null, null, recordConstraint,
                recordType, true, key, true, fieldsAndIncludes[0], true
        );

        return getFutureResult(future);
    }

    public static Object queryOne2(Environment env, BObject client, BArray key, BTypedesc recordType,
                                  BString entity) {
        RecordType recordConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());

        BArray[] fieldsAndIncludes = getFieldsAndIncludes((RecordType) recordType.getDescribingType());

        BMap<BString, Object> filterMap = ValueCreator.createMapValue();
        filterMap.put(fromString("orderId"), fromString(key.get(0).toString()));
        filterMap.put(fromString("itemId"), fromString(key.get(1).toString()));

        BFuture future = env.getRuntime().invokeMethodAsyncSequentially(
                getPersistClient(client, entity), Constants.RUN_READ_BY_KEY_QUERY_METHOD,
                null, null, null, null, recordConstraint,
                recordType, true, filterMap, true, fieldsAndIncludes[0], true
        );

        return getFutureResult(future);
    }

}
