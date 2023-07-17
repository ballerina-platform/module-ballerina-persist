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
