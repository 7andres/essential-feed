//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 26/12/24.
//

import XCTest

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url, completionHandler: { _, _, _ in })
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
}

private extension URLSessionHTTPClientTests {
    final class URLSessionSpy: URLSession {
        var receivedURLs: [URL] = []
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }
    
    final class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }
}
