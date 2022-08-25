import ballerina/test;
import ballerinax/mysql;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

@test:BeforeSuite
function truncate() returns error? {
    mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 0`);
    _ = check dbClient->execute(`TRUNCATE MedicalNeeds`);
    _ = check dbClient->execute(`TRUNCATE MedicalItems`);
    _ = check dbClient->execute(`TRUNCATE Departments`);
    _ = check dbClient->execute(`TRUNCATE Users`);
    _ = check dbClient->execute(`TRUNCATE Profiles`);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 1`);
    check dbClient.close();
}
