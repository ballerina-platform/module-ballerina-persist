import ballerina/test;
import ballerinax/mysql;

@test:BeforeSuite
function truncate() returns error? {
    mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 0`);
    _ = check dbClient->execute(`TRUNCATE Building`);
    _ = check dbClient->execute(`TRUNCATE Workspace`);
    _ = check dbClient->execute(`TRUNCATE Department`);
    _ = check dbClient->execute(`TRUNCATE Employee`);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 1`);
    check dbClient.close();
}
