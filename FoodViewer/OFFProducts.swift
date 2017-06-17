 //
//  ProductsArray.swift
//  FoodViewer
//
//  Created by arnaud on 07/04/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import Foundation
import UIKit

class OFFProducts {
    
    // This class is implemented as a singleton
    // The productsArray is only needed by the ProductsViewController
    // Unfortunately moving to another VC deletes the products, so it must be stored somewhere more permanently.
    // A singleton limits however the number of file loads
    
    internal struct Notification {
        static let BarcodeDoesNotExistKey = "OFFProducts.Notification.BarcodeDoesNotExist.Key"
    }
    
    static let manager = OFFProducts()
    
    var mostRecentProduct = MostRecentProduct()

    //  Contains all the fetch results for all product types
    private var allProductFetchResultList: [ProductFetchStatus?] = []
    
    // This list contains the product fetch results for the current product type
    //TODO: - make this a fixed variable that is changed when something is added to the allProductFetchResultList
    var fetchResultList: [ProductFetchStatus] = []
    
    private var currentProductType: ProductType {
        let test = Preferences.manager.showProductType
        return test
    }

    private func setCurrentProducts() {
        var list: [ProductFetchStatus] = []
        for fetchResult in allProductFetchResultList {
            if fetchResult != nil {
                switch fetchResult! {
                case .success(let product):
                    if let producttype = product.type?.rawValue {
                        if producttype == currentProductType.rawValue {
                            list.append(fetchResult!)
                        }
                    }
                default: break
                }
            }
        }
        // no product avalaible for current product category
        if list.isEmpty {
            loadSampleProduct()
            if let sample = sampleProduct {
                list.append(sample)
            }
        }
        self.fetchResultList = list
    }

    init() {
        // Initialize the products, multiple options are possible:
        // - there is no history, the user usese the app the first time for instance -> show a sample product
        // - there are products in the history file
        //      check first if the most recent product has been stored and load that one
        //      then load the rest of the history products
        loadAll()
        // NotificationCenter.default.addObserver(self, selector:#selector(OFFProducts.reset(_:)), name:.ShowProductTypeSet, object:nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func resetCurrentProducts() {
        setCurrentProducts()
    }
    
    var sampleProduct: ProductFetchStatus? = nil
    
    private func loadSampleProduct() {
        // If the user runs for the first time, then there is no history available
        // Then a sample product will be shown, which is stored with the app
        // historyLoadCount = nil
        if sampleProduct == nil {
            sampleProduct = ProductFetchStatus.loading
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                let fetchResult = OpenFoodFactsRequest().fetchSampleProduct()
                DispatchQueue.main.async(execute: { () -> Void in
                    self.sampleProduct = fetchResult
                    self.setCurrentProducts()
                    switch fetchResult {
                    case .success:
                        self.loadSampleImages()
                        NotificationCenter.default.post(name: .FirstProductLoaded, object:nil)
                    case .loadingFailed(let error):
                        let userInfo = ["error":error]
                        self.handleLoadingFailed(userInfo)
                    case .productNotAvailable(let error):
                        let userInfo = ["error":error]
                        self.handleProductNotAvailable(userInfo)
                    default: break
                    }
                })
            })
        }
    }
    
    func loadSampleImages() {

        // The images are read from the assets catalog as UIImage
        // this ensure that the right resolution will be read
        // and then they are internally stored as PNG data
        
        if let validFetchResult = allProductFetchResultList[0] {
            switch validFetchResult {
            case .success(let sampleProduct):
                let languageCode = sampleProduct.primaryLanguageCode ?? "en"
                
                if let image = UIImage(named: "SampleMain") {
                    if let data = UIImagePNGRepresentation(image) {
                        sampleProduct.frontImages?.small[languageCode]?.fetchResult = .success(data)
                        sampleProduct.frontImages?.display[languageCode]?.fetchResult = .success(data)
                    }
                } else {
                    sampleProduct.frontImages?.small[languageCode]?.fetchResult = .noData
                    sampleProduct.frontImages?.display[languageCode]?.fetchResult = .noData
                }
                
                if let image = UIImage(named: "SampleIngredients") {
                    if let data = UIImagePNGRepresentation(image) {
                        sampleProduct.ingredientsImages?.small[languageCode]?.fetchResult = .success(data)
                    }
                } else {
                    sampleProduct.ingredientsImages?.small[languageCode]?.fetchResult = .noData
                }
                
                if let image = UIImage(named: "SampleNutrition") {
                    if let data = UIImagePNGRepresentation(image) {
                        sampleProduct.nutritionImages?.small[languageCode]?.fetchResult = .success(data)
                    }
                } else {
                    sampleProduct.nutritionImages?.small[languageCode]?.fetchResult = .noData
                }
                
                sampleProduct.nameLanguage["en"] = NSLocalizedString("Sample Product for Demonstration, the globally known M&M's", comment: "Product name of the product shown at first start")
                sampleProduct.genericNameLanguage["en"] = NSLocalizedString("This sample product shows you how a product is presented. Slide to the following pages, in order to see more product details. Once you start scanning barcodes, you will no longer see this sample product.", comment: "An explanatory text in the common name field.")
                
            default: break
            }
        }
        
            }
    
    fileprivate func initList() {
        // I need a nillified list of the correct size, because I want to access items through the index.
        if allProductFetchResultList.isEmpty {
            for _ in 0..<storedHistory.barcodeTuples.count {
                allProductFetchResultList.append(nil)
            }
        }
    }
    
    func removeAll() {
            storedHistory = History()
            allProductFetchResultList = []
            loadSampleProduct()
    }
    
    var storedHistory = History()

    fileprivate func fetchHistoryProduct(_ product: FoodProduct?, index: Int) {
        
        // only fetch if we do not started the loading yet
        if allProductFetchResultList[index] == nil {
            allProductFetchResultList[index] = .loading
            if let barcodeToFetch = product?.barcode {
                let request = OpenFoodFactsRequest()
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                // loading the product from internet will be done off the main queue
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                    let fetchResult = request.fetchProductForBarcode(barcodeToFetch)
                    DispatchQueue.main.async(execute: { () -> Void in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.allProductFetchResultList[index] = fetchResult
                        self.setCurrentProducts()
                        switch fetchResult {
                        case .success:
                            if self.historyLoadCount != nil {
                                self.historyLoadCount! += 1
                                // This is a bit over the top
                                // I should add the barcode of the product that has been loaded
                                NotificationCenter.default.post(name: .ProductLoaded, object:nil)
                            }
                        case .loadingFailed(let error):
                            self.historyLoadCount! += 1
                            let userInfo = ["error":error]
                            self.handleLoadingFailed(userInfo)
                        case .productNotAvailable:
                            // product barcode no longer exists
                            self.historyLoadCount! += 1
                            // let userInfo = ["error":error]
                        // self.handleProductNotAvailable(userInfo)
                        default: break
                        }
                    })
                })
            }
        }
        /*} else {
            if let errorString = ProductType.onServer(storedHistory.barcodeTuples[index].1) {
                allProductFetchResultList[index] = .other(errorString)
            } else {
                allProductFetchResultList[index] = .other("Error")
            }
            self.historyLoadCount! += 1
        }*/

    }

    // This function manages the loading of the history products. A load batch is never larger than 5 simultaneous threads
    fileprivate var historyLoadCount: Int? = nil {
        didSet {
            if let currentLoadHistory = historyLoadCount {
                let batchSize = 5
                if currentLoadHistory == storedHistory.barcodeTuples.count - 1 {
                    // all products have been loaded from history
                    NotificationCenter.default.post(name: .ProductLoaded, object:nil)
                } else if (currentLoadHistory >= 4) && ((currentLoadHistory + 1 ) % batchSize == 0) {
                    NotificationCenter.default.post(name: .ProductLoaded, object:nil)
                    // load next batch
                    let startIndex = currentLoadHistory + 1 <= storedHistory.barcodeTuples.count - 1 ? currentLoadHistory + 1 : storedHistory.barcodeTuples.count - 1
                    let endIndex = startIndex + batchSize - 1 <= storedHistory.barcodeTuples.count - 1 ? startIndex + batchSize - 1 : storedHistory.barcodeTuples.count - 1
                    for index in startIndex...endIndex {
                        fetchHistoryProduct(FoodProduct(withBarcode: BarcodeType(barcodeTuple: storedHistory.barcodeTuples[index])), index:index)
                    }
                } else if (currentLoadHistory == 0) {
                    // the first product is already there, so can be shown
                    NotificationCenter.default.post(name:  .FirstProductLoaded, object:nil)
                    // load first batch up to product 4
                    let startIndex = 1 <= storedHistory.barcodeTuples.count ? 1 : storedHistory.barcodeTuples.count - 1
                    let endIndex = startIndex + batchSize - 1 <= storedHistory.barcodeTuples.count - 1 ? batchSize - 1 : storedHistory.barcodeTuples.count - 1
                    for index in startIndex...endIndex {
                        print(storedHistory.barcodeTuples[index].1, currentProductType.rawValue)
                        fetchHistoryProduct(FoodProduct(withBarcode: BarcodeType(barcodeTuple: storedHistory.barcodeTuples[index])), index:index)
                    }
                }
            }
        }
    }

    func fetchProduct(_ barcode: BarcodeType?) -> Int? {
        
        if let newBarcode = barcode {
            // is the product already in the history list?
            if let productIndexInHistory = isProductinList(newBarcode) {
                return productIndexInHistory
            } else {
                // retrieve this new product
                let request = OpenFoodFactsRequest()
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                // loading the product from internet will be done off the main queue
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    let fetchResult = request.fetchProductForBarcode(newBarcode)
                    DispatchQueue.main.async(execute: { () -> Void in
                        switch fetchResult {
                        case .success(let newProduct):
                        // add product barcode to history
                            self.allProductFetchResultList.insert(fetchResult, at:0)
                            self.setCurrentProducts()
                            // try to get the product type out the json
                            self.storedHistory.add((newProduct.barcode.asString(), newProduct.type?.rawValue ?? self.currentProductType.rawValue) )
                            // self.loadMainImage(newProduct)
                            self.saveMostRecentProduct(barcode!)
                            NotificationCenter.default.post(name: .FirstProductLoaded, object:nil)
                        case .loadingFailed(let error):
                            self.allProductFetchResultList.insert(fetchResult, at:0)
                            self.setCurrentProducts()
                            let userInfo = ["error":error]
                            self.handleLoadingFailed(userInfo)
                        case .productNotAvailable(let error):
                            let userInfo = [Notification.BarcodeDoesNotExistKey:newBarcode.asString(), "error":error]
                            self.handleProductNotAvailable(userInfo)
                        default: break
                        }
                    })
                })
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func isProductinList(_ barcode: BarcodeType) -> Int? {
        for (index, fetchResult) in allProductFetchResultList.enumerated() {
            guard fetchResult != nil else { return nil }
            switch fetchResult! {
            case .success(let product):
                if product.barcode.asString() == barcode.asString() {
                    return index
                }
            default:
                break
            }
        }
        return nil
    }
    
    func saveMostRecentProduct(_ barcode: BarcodeType?) {
        if barcode != nil {
            let request = OpenFoodFactsRequest()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            // loading the product from internet will be done off the main queue
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                let fetchResult = request.fetchJsonForBarcode(barcode!)
                DispatchQueue.main.async(execute: { () -> Void in
                    switch fetchResult {
                    case .success(let newData):
                        // This will store the data in the user defaults file
                        self.mostRecentProduct.addMostRecentProduct(newData)
                    case .error(let error):
                        let userInfo = ["error":error]
                        self.handleLoadingFailed(userInfo)
                    }
                })
            })
        }
    }
    
    // MARK: - Create notifications

    func handleProductNotAvailable(_ userInfo: [String:String]) {
        NotificationCenter.default.post(name: .ProductNotAvailable, object:nil, userInfo: userInfo)
    }

    func handleLoadingFailed(_ userInfo: [String:String]) {
        NotificationCenter.default.post(name: .ProductLoadingError, object:nil, userInfo: userInfo)
    }

    fileprivate func isProductInList(_ newBarcode: BarcodeType) -> Int? {
        for (index, fetchResult) in allProductFetchResultList.enumerated() {
            if let validFetchResult = fetchResult {
                switch validFetchResult {
                case .success(let product):
                    if product.barcode.asString() == newBarcode.asString() {
                        return index
                    }
                default:
                    break
                }

            }
        }
        return nil
    }
    
    func reload(_ product: FoodProduct) {
        let request = OpenFoodFactsRequest()
        var fetchResult = ProductFetchStatus.loading
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
            // loading the product from internet will be done off the main queue
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
            fetchResult = request.fetchProductForBarcode(product.barcode)
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch fetchResult {
                case .success(let newProduct):
                    self.update(newProduct)
                    NotificationCenter.default.post(name: .ProductUpdated, object:nil)
                case .loadingFailed(let error):
                    let userInfo = ["error":error]
                    self.handleLoadingFailed(userInfo)
                case .productNotAvailable(let error):
                    let userInfo = ["error":error]
                    self.handleProductNotAvailable(userInfo)
                default:
                    break
                }
            })
        })
    }
    
    func reloadAll() {
        // allProductFetchResultList = []
        // get the latest history file
        // storedHistory = History()
        sampleProduct = nil
        // reset the current list of products
        // the product type might have changed
        setCurrentProducts()
        // historyLoadCount = nil
        loadAll()
    }
    
    private func loadAll() {
        // If there is no history, we are in the cold start case
        if !storedHistory.barcodeTuples.isEmpty {
            initList()
            // load the most recent product from the local storage
            if let data = mostRecentProduct.jsonData {
                var fetchResult = ProductFetchStatus.loading
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                    fetchResult = OpenFoodFactsRequest().fetchStoredProduct(data)
                    DispatchQueue.main.async(execute: { () -> Void in
                        switch fetchResult {
                        case .success(let product):
                            // the stored product might not correspond to the first product in the history
                            // so it should be stored in the right spot
                            if let index = self.storedHistory.index(for:product.barcode) {
                                self.allProductFetchResultList[index] = fetchResult
                                self.setCurrentProducts()
                                NotificationCenter.default.post(name: .FirstProductLoaded, object:nil)
                            } else {
                                print("OFFProducts - stored product not in history file")
                            }
                        case .loadingFailed(let error):
                            let userInfo = ["error":error]
                            self.handleLoadingFailed(userInfo)
                        case .productNotAvailable:
                            // if the product is not available there is an error in storage
                            // and can be removed
                            self.mostRecentProduct.removeForCurrentProductType()
                            // let userInfo = ["error":error]
                            // self.handleProductNotAvailable(userInfo)
                        default: break
                        }
                        self.historyLoadCount = 0
                        self.historyLoadCount! += 1
                    })
                })
            } else {
                // the data is not available
                // has to be loaded from the OFF-servers
                _ = fetchProduct(BarcodeType(value: storedHistory.barcodeTuples[0].0))
                historyLoadCount = 0
            }
        } else {
            // The cold start case when the user has not yet used the app
            loadSampleProduct()
            NotificationCenter.default.post(name: .FirstProductLoaded, object:nil)
        }
    }
    
    fileprivate func update(_ updatedProduct: FoodProduct) {
        // only update the updated product
        // need to find it first in the history.
        var index = 0
        for fetchResult in allProductFetchResultList {
            if let validFetchResult = fetchResult {
                switch validFetchResult {
                case .success(let product):
                    if product.barcode.asString() == updatedProduct.barcode.asString() {
                        // replace the existing product with the data of the new product
                        product.updateDataWith(updatedProduct)
                        // i sthis the first product in the list
                        if index == 0 {
                            // then the stored version must also be updated with this new product
                            saveMostRecentProduct(product.barcode)
                        }
                    }
                    index += 1
                default:
                    break
                }
            } 
        }
    }
    
    func flushImages() {
        print("error: OFFProducts.flushImages - flushing")
        for fetchResult in allProductFetchResultList {
            if let validFetchResult = fetchResult {
                switch validFetchResult {
                case .success(let product):
                    if product.nutritionImages != nil {
                        product.nutritionImages!.reset()
                    }
                    if product.frontImages != nil {
                        product.frontImages!.reset()
                    }
                    if product.ingredientsImages != nil {
                        product.ingredientsImages!.reset()
                    }
                default:
                    break
                }
            } else {
                print("error: OFFProducts.flushImages - fetchResult is nil")
            }
        }
    }
}

// Notification definitions

extension Notification.Name {
    static let ProductNotAvailable = Notification.Name("OFFProducts.Notification.Product Not Available")
    static let ProductLoaded = Notification.Name("OFFProducts.Notification.Product Loaded")
    static let FirstProductLoaded = Notification.Name("OFFProducts.Notification.First Product Loaded")
    static let HistoryIsLoaded = Notification.Name("OFFProducts.Notification.History Is Loaded")
    static let ProductUpdated = Notification.Name("OFFProducts.Notification.Product Updated")
    static let ProductLoadingError = Notification.Name("OFFProducts.Notification.Product Loading Error")
}


