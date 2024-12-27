//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 26/12/24.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask
}

protocol HTTPSessionDataTask {
    func resume()
}

final class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url, completionHandler: { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }).resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        let error = NSError(domain: "any error", code: 1)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        let expectation = XCTestExpectation(description: "wait for completion")
        
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

private extension URLSessionHTTPClientTests {
    final class URLSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            let task: HTTPSessionDataTask
            let error: Error?
        }
        
        func stub(url: URL, task: HTTPSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> HTTPSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Could not find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    final class FakeURLSessionDataTask: HTTPSessionDataTask {
        func resume() {}
    }
    
    final class URLSessionDataTaskSpy: HTTPSessionDataTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
