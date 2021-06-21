// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;
import ballerina/url;

service /graphql on new Listener(9092) {
    isolated resource function get name() returns string {
        return "James Moriarty";
    }

    isolated resource function get birthdate() returns string {
        return "15-05-1848";
    }
}

@test:Config {
    groups: ["listener", "unit"]
}
isolated function testGetRequest() returns error? {
    string document = "query getPerson { profile(id: 1) { address { city } } }";
    string encodedDocument = check url:encode(document, "UTF-8");
    json expectedPayload = {
        data: {
            profile: {
                address: {
                    city: "Albuquerque"
                }
            }
        }
    };
    http:Client httpClient = check new("http://localhost:9095");
    string path = "/graphql?query=" + encodedDocument;
    json actualPayload = check httpClient->get(path);
    test:assertEquals(actualPayload, expectedPayload);
}

@test:Config {
    groups: ["listener", "unit"]
}
isolated function testInvalidGetRequestWithoutQuery() returns error? {
    http:Client httpClient = check new("http://localhost:9095");
    http:Response response = check httpClient->get("/graphql");
    assertResponseForBadRequest(response);
    test:assertEquals(response.getTextPayload(), "Query not found");
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testInvalidJsonPayload() returns error? {
    http:Request request = new;
    request.setJsonPayload({});
    string payload = check getTextPayloadFromBadRequest("http://localhost:9092/graphql", request);
    test:assertEquals(payload, "Invalid request body");
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testInvalidContentType() returns error? {
    http:Request request= new;
    request.setPayload("invalid");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9092/graphql", request);
    test:assertEquals(payload, "Invalid 'Content-type' received");
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testContentTypeGraphql() returns error? {
    http:Request request = new;
    request.setHeader("Content-Type", "application/graphql");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9092/graphql", request);
    test:assertEquals(payload, "Content-Type 'application/graphql' is not yet supported");
}

@test:Config {
    groups: ["listener", "negative"]
}
isolated function testInvalidRequestBody() returns error? {
    http:Client httpClient = check new("http://localhost:9092/graphql");
    http:Request request = new;
    request.setTextPayload("Invalid");
    request.setHeader("Content-Type", "application/json");
    string payload = check getTextPayloadFromBadRequest("http://localhost:9092/graphql", request);
    test:assertEquals(payload, "Invalid request body");
}
