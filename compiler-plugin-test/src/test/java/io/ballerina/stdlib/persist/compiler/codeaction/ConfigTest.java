
package io.ballerina.stdlib.persist.compiler.codeaction;

import io.ballerina.stdlib.persist.compiler.codeaction.diagnostic.AbstractCodeActionTest;
import org.testng.annotations.DataProvider;

/**
 *
 */
public class ConfigTest extends AbstractCodeActionTest {
    @DataProvider(name = "codeaction-data-provider")
    @Override
    public Object[][] dataProvider() {
        return new Object[][]{
                { "addenv1.json", "entities.bal" }
        };
    }

    @Override
    public String getResourceDir() {
        return "add_configs";
    }
}
