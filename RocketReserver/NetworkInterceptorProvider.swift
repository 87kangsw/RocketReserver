//
//  NetworkInterceptorProvider.swift
//  RocketReserver
//
//  Created by Kanz on 2021/04/04.
//

import Foundation

import Apollo

class NetworkInterceptorProvider: LegacyInterceptorProvider {
    override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(TokenAddingInterceptor(), at: 0)
        return interceptors
    }
}


 
