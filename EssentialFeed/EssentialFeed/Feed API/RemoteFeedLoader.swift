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
                completion(FeedItemsMapper.map(data, response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
