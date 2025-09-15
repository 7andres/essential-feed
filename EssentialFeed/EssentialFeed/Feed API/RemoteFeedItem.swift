//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 12/09/25.
//

import Foundation

struct RemoteFeedItem: Decodable {
  internal let id: UUID
  internal let description: String?
  internal let location: String?
  internal let image: URL
}
