/*
 *  Copyright (c) 2022, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.runtime.api.types.ArrayType;
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

import java.util.Map;

/**
 * TODO: add javadoc comment.
 *
 * @since 0.1.0
 */
public class Utils {
    private Utils() {
    }

    public static BStream query(Environment env, BObject client, BTypedesc recordType, BString entity) {
        RecordType streamConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());
        StreamType streamType = TypeCreator.createStreamType(streamConstraint, PredefinedTypes.TYPE_NULL);

        BFuture future = env.getRuntime().invokeMethodAsyncSequentially(
                getPersistClient(client, entity), Constants.RUN_READ_QUERY_METHOD,
                null, null, null, null, streamType,
                recordType, true, getFields(recordType), true
        );

        return (BStream) getFutureResult(future);
    }

    public static Object queryOne(Environment env, BObject client, BString key, BTypedesc recordType,
                                  BString entity) {
        RecordType recordConstraint = (RecordType) TypeUtils.getReferredType(recordType.getDescribingType());

        BFuture future = env.getRuntime().invokeMethodAsyncSequentially(
                getPersistClient(client, entity), Constants.RUN_READ_BY_KEY_QUERY_METHOD,
                null, null, null, null, recordConstraint,
                recordType, true, key, true, getFields(recordType), true
        );

        return getFutureResult(future);
    }

    private static BObject getPersistClient(BObject client, BString entity) {
        BMap<?, ?> persistClients = (BMap<?, ?>) client.get(Constants.PERSIST_CLIENTS);
        return (BObject) persistClients.get(entity);
    }
    private static BArray getFields(BTypedesc recordType) {
        ArrayType stringArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING);
        BArray fieldsArray = ValueCreator.createArrayValue(stringArrayType);

        Map<BString, BObject> fieldsMap = recordType.getDescribingType().getEmptyValue();
        BString[] fields = fieldsMap.keySet().toArray(new BString[0]);

        for (BString field : fields) {
            fieldsArray.append(field);
        }
        return fieldsArray;
    }

    private static Object getFutureResult(BFuture future) {
        while (!future.isDone()) {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                // ignore
            }
        }
        return future.getResult();
    }
}
