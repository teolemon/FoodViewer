//
//  ProductFetchStatus.swift
//  FoodViewer
//
//  Created by arnaud on 11/05/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import Foundation

enum ProductFetchStatus {
    // The productFetchStatus describes the prossible status changes of the remoteProduct
    // nothing is known at the moment
    case initialized
    // the barcode is set, but no load is initialised
    case productNotLoaded(String) // (barcodeString)
    // loading indicates that it is tried to load the product
    case loading(String) // The string indicates the barcodeString
    // the product has been loaded successfully and can be set.
    case success(FoodProduct)
    // available implies that the product has been retrieved and is available for usage
    case available(String)
    // when the user has successfully uploaded a new version
    case updating(String)
    // the product is not available on the off servers
    case productNotAvailable(String) // (barcodeString)
    // the loading did not succeed
    case loadingFailed(String) // (barcodeString)
    
    
    // TOD:
    // The searchList returns a facet of the search result,
    // as a tuple (searchResultSize, pageNumber, pageSize, products for pageNumber)
    case noSearchDefined
    case searchLoading
    case searchQuery(SearchTemplate)
    case searchList((Int, Int, Int, [FoodProduct]))
    // The more parameter defines the search next page to retrieve
    case more(Int)

    var description: String {
        switch self {
        case .initialized: return TranslatableStrings.Initialized
        case .productNotLoaded: return TranslatableStrings.ProductNotLoaded
        case .loading: return TranslatableStrings.ProductLoading
        case .success: return TranslatableStrings.ProductIsLoaded
        case .available: return TranslatableStrings.ProductIsLoaded
        case .updating: return TranslatableStrings.ProductIsUpdated
        case .loadingFailed: return TranslatableStrings.ProductLoadingFailed
        case .productNotAvailable: return TranslatableStrings.ProductNotAvailable
            
        case .noSearchDefined: return TranslatableStrings.NoSearchDefined
        case .searchLoading: return TranslatableStrings.SearchLoading
        case .searchQuery: return TranslatableStrings.SearchQuery
        case .searchList: return TranslatableStrings.ProductListIsLoaded
        case .more: return TranslatableStrings.LoadMoreResults
        }
    }
    
    var rawValue: Int {
        switch self {
        case .initialized: return 0
        case .productNotLoaded: return 1
        case .loading: return 2
        case .success: return 3
        case .available: return 3
        case .updating: return 4
        case .productNotAvailable: return 5
        case .loadingFailed: return 6

        case .noSearchDefined: return 10
        case .searchLoading: return 11
        case .searchQuery: return 12
        case .searchList: return 13
        case .more: return 14
        }
    }
}
