//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 25/12/24.
//

import Foundation

internal final class FeedItemsMapper {
  private struct Root: Decodable {
    let items: [RemoteFeedItem]
  }
  
  private static var OK_STATUS_CODE: Int { 200 }
  
  internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
    guard response.statusCode == OK_STATUS_CODE,
          let root = try? JSONDecoder().decode(Root.self, from: data) else {
      throw RemoteFeedLoader.Error.invalidData
    }
    
    return root.items
  }
}
