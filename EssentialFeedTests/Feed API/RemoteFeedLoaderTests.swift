//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 8/12/24.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestedURLs.count, 0)
    }
    
    func test_loads_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWith: failure(.connectivity),
            when: {
                let clientError = NSError(domain: "", code: 0)
                client.complete(with: clientError, at: 0)
            }
        )
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(
                sut,
                toCompleteWith: failure(.invalidData),
                when: {
                    let json = makeItemsJSON([])
                    client.complete(withStatusCode: code, data: json, at: index)
                }
            )
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWith: failure(.invalidData),
            when: {
                client.complete(withStatusCode: 200, data: Data("invalid data".utf8))
            }
        )
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWith: .success([]),
            when: {
                let emptyListJSON = makeItemsJSON([])
                client.complete(withStatusCode: 200, data: emptyListJSON)
            }
        )
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            description: "A description",
            location: "A location",
            imageURL: URL(string: "http://another-url.com")!
        )
        let items = [item1.model, item2.model]
        
        expect(
            sut,
            toCompleteWith: .success(items),
            when: {
                let json = makeItemsJSON([item1.json, item2.json])
                client.complete(withStatusCode: 200, data: json)
            }
        )
    }
    
    func test_load_doesNotDeliversResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil
        
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

private extension RemoteFeedLoaderTests {
    func makeSUT(
        url: URL = URL(string: "https://a-given-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: URL(string: "https://a-given-url.com")!, client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        
        return (sut, client)
    }
    
    func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should be deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
    
    func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail(
                    "Expectec result \(expectedResult), but got \(receivedResult) instead",
                    file: file,
                    line: line
                )
            }
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1)
    }
}

private extension RemoteFeedLoaderTests {
    class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.error(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
}
