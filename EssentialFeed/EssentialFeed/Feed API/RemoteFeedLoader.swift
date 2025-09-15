//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 8/12/24.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
  private let url: URL
  private let client: HTTPClient
  
  public typealias Result = LoadFeedResult
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  public init(
    url: URL,
    client: HTTPClient
  ) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url) { [weak self] result in
      guard let self else { return }
      switch result {
      case .success(let data, let response):
        completion(RemoteFeedLoader.map(data, from: response))
      case .failure:
        completion(.failure(Error.connectivity))
      }
    }
  }
  
  private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
    do {
      let items = try FeedItemsMapper.map(data, from: response)
      return .success(items.toModels())
    } catch {
      return .failure(error)
    }
  }
}

private extension Array where Element == RemoteFeedItem {
  func toModels() -> [FeedImage] {
    return map {
      FeedImage(
        id: $0.id,
        description: $0.description,
        location: $0.location,
        url: $0.image
      )
    }
  }
}
