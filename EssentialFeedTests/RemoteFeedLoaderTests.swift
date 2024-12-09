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
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_loads_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
}

private extension RemoteFeedLoaderTests {
    func makeSUT(
        url: URL = URL(string: "https://a-given-url.com")!
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: URL(string: "https://a-given-url.com")!, client: client)
        return (sut, client)
    }
}

private extension RemoteFeedLoaderTests {
    class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
}
