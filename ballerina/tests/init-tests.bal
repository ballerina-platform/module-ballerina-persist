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
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 0`);
    _ = check dbClient->execute(`TRUNCATE MedicalNeeds`);
    _ = check dbClient->execute(`TRUNCATE MedicalItems`);
    _ = check dbClient->execute(`TRUNCATE ComplexTypes`);
    _ = check dbClient->execute(`TRUNCATE Departments`);
    _ = check dbClient->execute(`TRUNCATE Users`);
    _ = check dbClient->execute(`TRUNCATE Profiles`);
    _ = check dbClient->execute(`TRUNCATE MultipleAssociations`);
    _ = check dbClient->execute(`TRUNCATE Companies`);
    _ = check dbClient->execute(`TRUNCATE Employees`);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 1`);
    check dbClient.close();
}
