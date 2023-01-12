import ballerina/test;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string user = ?;
configurable string password = ?;
configurable string host = ?;
configurable string database = ?;
configurable int port = ?;

@test:BeforeSuite
function truncate() returns error? {
    mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
    _ = check dbClient->execute(`TRUNCATE Building`);
    check dbClient.close();
}
