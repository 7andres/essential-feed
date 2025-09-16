//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Andrés Carrillo on 16/09/25.
//

import Foundation

func anyURL() -> URL {
  return URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
  NSError(domain: "any erro", code: 0)
}
