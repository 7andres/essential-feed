//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Andrés Carrillo on 25/12/24.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case error(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
