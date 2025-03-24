//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 26/12/24.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  struct UnexpectedValuesRepresentation: Error {}
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url, completionHandler: { data, response, error in
      if let error {
        completion(.failure(error))
      } else if let data, data.count > 0, let response = response as? HTTPURLResponse {
        completion(.success(data, response))
      } else {
        completion(.failure(UnexpectedValuesRepresentation()))
      }
    }).resume()
  }
}

final class URLSessionHTTPClientTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }
  
  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }
  
  func test_getFromURL_performsGETRequestWithURL() {
    let url = makeAnyURL()
    let expectation = XCTestExpectation(description: "wait for request")
    
    URLProtocolStub.observeRequests { urlRequest in
      XCTAssertEqual(urlRequest.url, url)
      XCTAssertEqual(urlRequest.httpMethod, "GET")
      expectation.fulfill()
    }
    
    makeSUT().get(from: url, completion: { _ in })
    wait(for: [expectation], timeout: 1)
  }
  
  func test_getFromURL_failsOnRequestError() {
    let requestError = makeNSError()
    
    guard let receivedError = resultErrorFor(
      data: nil,
      response: nil,
      error: requestError
    ) as? NSError else {
      XCTFail("Expected an NSError")
      return
    }
    
    XCTAssertEqual(receivedError.domain, requestError.domain)
    XCTAssertEqual(receivedError.code, requestError.code)
  }
  
  func test_getFromURL_failsOnAllInvalidRepresentationCases() {
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(
      resultErrorFor(
        data: nil,
        response: makeNonHTTPURLResponse(),
        error: nil
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: nil,
        response: makeAnyHTTPURLResponse(),
        error: nil
      )
    )
    XCTAssertNotNil(resultErrorFor(data: makeAnyData(), response: nil, error: nil))
    XCTAssertNotNil(
      resultErrorFor(
        data: makeAnyData(),
        response: nil,
        error: makeNSError()
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: nil,
        response: makeNonHTTPURLResponse(),
        error: makeNSError()
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: nil,
        response: makeAnyHTTPURLResponse(),
        error: makeNSError()
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: makeAnyData(),
        response: makeNonHTTPURLResponse(),
        error: makeNSError()
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: makeAnyData(),
        response: makeAnyHTTPURLResponse(),
        error: makeNSError()
      )
    )
    XCTAssertNotNil(
      resultErrorFor(
        data: makeAnyData(),
        response: makeNonHTTPURLResponse(),
        error: nil
      )
    )
  }
  
  func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
    let data = makeAnyData()
    let response = makeAnyHTTPURLResponse()
    URLProtocolStub.stub(data: data, response: response, error: nil)
    
    let expectation =  expectation(description: "wait for completion")
    
    makeSUT().get(from: makeAnyURL()) { result in
      switch result {
      case let .success(receivedData, receivedResponse):
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(receivedResponse.url, response.url)
        XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
      default:
        XCTFail("Expected success, got \(result) instead")
      }
      
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1)
  }
}

// MARK: Helpers
private extension URLSessionHTTPClientTests {
  func makeSUT(
    file: StaticString = #file,
    line: UInt = #line
  ) -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  func resultErrorFor(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Error? {
    URLProtocolStub.stub(data: data, response: response, error: error)
    
    let sut = makeSUT(file: file, line: line)
    let expectation = XCTestExpectation(description: "wait for completion")
    var receivedError: Error?
    
    sut.get(from: makeAnyURL()) { result in
      switch result {
      case let .failure(error):
        receivedError = error
      default:
        XCTFail("Expected failure, got \(result) instead", file: file, line: line)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1)
    return receivedError
  }
  
  func makeAnyURL() -> URL {
    URL(string: "http://any-url.com")!
  }
  
  func makeAnyData() -> Data {
    Data("any data".utf8)
  }
  
  func makeNSError() -> NSError {
    NSError(domain: "any erro", code: 0)
  }
  
  func makeAnyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(
      url: makeAnyURL(),
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
  }
  
  func makeNonHTTPURLResponse() -> URLResponse {
    URLResponse(
      url: makeAnyURL(),
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )
  }
}

private extension URLSessionHTTPClientTests {
  final class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stub = Stub(data: data, response: response, error: error)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }
    
    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
      requestObserver = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
      requestObserver?(request)
      return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }
    
    override func startLoading() {
      if let data = URLProtocolStub.stub?.data {
        client?.urlProtocol(self, didLoad: data)
      }
      
      if let response = URLProtocolStub.stub?.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      
      if let error = URLProtocolStub.stub?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      
      client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
  }
}
