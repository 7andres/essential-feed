//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 20/11/25.
//

import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
  
  func assertThatRetrieveDeliversFailureOnRetrievalError(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
  }

  func assertThatRetrieveHasNoSideEffectsOnFailure(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    expect(sut, toRetrieveTwice: .failure(anyNSError()), file: file, line: line)
  }
}
