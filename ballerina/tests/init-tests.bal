import ballerina/test;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable int port = ?;
configurable string host = ?;
configurable string user = ?;
configurable string database = ?;
configurable string password = ?;
configurable mysql:Options connectionOptions = {};

@test:BeforeSuite
function truncate() returns error? {
    mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 0`);
    _ = check dbClient->execute(`SET GLOBAL time_zone = '+09:00'`);
    _ = check dbClient->execute(`SET @@session.time_zone = "+09:00"`);
    _ = check dbClient->execute(`TRUNCATE Employee`);
    _ = check dbClient->execute(`TRUNCATE Workspace`);
    _ = check dbClient->execute(`TRUNCATE Building`);
    _ = check dbClient->execute(`TRUNCATE Department`);
    _ = check dbClient->execute(`TRUNCATE OrderItem`);
    _ = check dbClient->execute(`TRUNCATE AllTypes`);
    _ = check dbClient->execute(`TRUNCATE FloatIdRecord`);
    _ = check dbClient->execute(`TRUNCATE StringIdRecord`);
    _ = check dbClient->execute(`TRUNCATE DecimalIdRecord`);
    _ = check dbClient->execute(`TRUNCATE BooleanIdRecord`);
    _ = check dbClient->execute(`TRUNCATE IntIdRecord`);
    _ = check dbClient->execute(`TRUNCATE AllTypesIdRecord`);
    _ = check dbClient->execute(`TRUNCATE CompositeAssociationRecord`);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 1`);
    check dbClient.close();
}
