//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 20/11/25.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
	public init() {}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		completion(.empty)
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

	}
}
