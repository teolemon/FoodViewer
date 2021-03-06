//
//  IdentificationTableViewController.swift
//  FoodViewer
//
//  Created by arnaud on 16/02/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

import UIKit

class IdentificationTableViewController: UITableViewController {

    struct TextConstants {
        static let ShowIdentificationTitle = "Image"
        static let ViewControllerTitle = "Identification"
    }
    private var tableStructureForProduct: [(SectionType, Int, String?)] = []
    
    private var identificationImage: UIImage? = nil {
        didSet {
            tableView.reloadData()
        }
    }
    
    private enum SectionType {
        case Barcode
        case Name
        case CommonName
        case Brands
        case Packaging
        case Quantity
        case Image
    }
    
    var product: FoodProduct? {
        didSet {
            if product != nil {
                identificationImage = nil
                tableStructureForProduct = analyseProductForTable(product!)
                if product!.mainUrl != nil {
                    retrieveImage(product!.mainUrl!)
                }
                tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    private struct Storyboard {
        static let BasicCellIdentifier = "Identification Basic Cell"
        static let TagListCellIdentifier = "Identification TagList Cell"
        static let PackagingCellIdentifier = "Identification Packaging Cell"
        static let ImageCellIdentifier = "Identification Image Cell"
        static let ShowIdentificationSegueIdentifier = "Show Identification Image"
        static let ShowNextSegueIdentifier = "Show Next Ingredients"
        static let ShowPreviousUnwindSegueIdentifier = "Show Previous Completion State"
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // should return all sections (7)
        return tableStructureForProduct.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let (_, numberOfRows, _) = tableStructureForProduct[section]
        return numberOfRows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let (currentProductSection, _, _) = tableStructureForProduct[indexPath.section]
        
        // we assume that product exists
        switch currentProductSection {
        case .Barcode:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.BasicCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = product!.barcode.asString()
            return cell
        case .Name:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.BasicCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = product!.name!
            return cell
        case .CommonName:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.BasicCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = product!.commonName!
            return cell
        case .Brands:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TagListCellIdentifier, forIndexPath: indexPath) as? IdentificationTagListViewTableViewCell
            cell!.tagList = product!.brandsArray
            return cell!
        case .Packaging:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TagListCellIdentifier, forIndexPath: indexPath) as? IdentificationTagListViewTableViewCell
            cell?.tagList = product!.packagingArray
            cell?.layoutIfNeeded()
            return cell!
        case .Quantity:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.BasicCellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = product!.quantity!
            return cell
        case .Image:
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.ImageCellIdentifier, forIndexPath: indexPath) as? IdentificationImageTableViewCell
            cell!.identificationImage = identificationImage
            return cell!
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let (_, _, header) = tableStructureForProduct[section]
        return header
    }

    private struct TableStructure {
        static let BarcodeSectionSize = 1
        static let NameSectionSize = 1
        static let CommonNameSectionSize = 1
        static let BrandsSectionSize = 1
        static let PackagingSectionSize = 1
        static let QuantitySectionSize = 1
        static let ImageSectionSize = 1
        static let BarcodeSectionHeader = "Barcode"
        static let NameSectionHeader = "Name"
        static let CommonNameSectionHeader = "Common Name"
        static let BrandsSectionHeader = "Brands"
        static let PackagingSectionHeader = "Packaging"
        static let QuantitySectionHeader = "Quantity"
        static let ImageSectionHeader = "Main Image"
    }

    private func analyseProductForTable(product: FoodProduct) -> [(SectionType,Int, String?)] {
        // This function analyses to product in order to determine
        // the required number of sections and rows per section
        // The returnValue is an array with sections
        // And each element is a tuple with the section type and number of rows
        //
        //  The order of each element determines the order in the table
        var sectionsAndRows: [(SectionType,Int, String?)] = []
        
        // 1: barcode section always exists
        sectionsAndRows.append((SectionType.Barcode, TableStructure.BarcodeSectionSize, TableStructure.BarcodeSectionHeader))
        
        // 2:  name section
        if product.name != nil {
            sectionsAndRows.append((
                SectionType.Name,
                TableStructure.NameSectionSize,
                TableStructure.NameSectionHeader))
        }
        
        // 3: common name section
        if product.commonName != nil {
            sectionsAndRows.append((
                SectionType.CommonName,
                TableStructure.CommonNameSectionSize,
                TableStructure.CommonNameSectionHeader))
        }
        
        // 4: brands section
        if product.nutritionScore != nil {
            sectionsAndRows.append((
                SectionType.Brands,
                TableStructure.BrandsSectionSize,
                TableStructure.BrandsSectionHeader))
        }
        
        // 5: packaging section
        if product.categories != nil {
            sectionsAndRows.append((
                SectionType.Packaging,
                TableStructure.PackagingSectionSize,
                TableStructure.PackagingSectionHeader))
        }
        
        // 6: quantity section
        if product.countries != nil {
            sectionsAndRows.append((
                SectionType.Quantity,
                TableStructure.QuantitySectionSize,
                TableStructure.QuantitySectionHeader))
        }
        
        // 7: image section
        if product.mainUrl != nil {
            sectionsAndRows.append((
                SectionType.Image,
                TableStructure.ImageSectionSize,
                TableStructure.ImageSectionHeader))
        }
                
        // print("\(sectionsAndRows)")
        return sectionsAndRows
    }
    
    private func retrieveImage(url: NSURL?) {
        if let imageURL = url {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
                do {
                    // This only works if you add a line to your Info.plist
                    // See http://stackoverflow.com/questions/31254725/transport-security-has-blocked-a-cleartext-http
                    //
                    let imageData = try NSData(contentsOfURL: imageURL, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                    if imageData.length > 0 {
                        // if we have the image data we can go back to the main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            // set the received image
                            self.identificationImage = UIImage(data: imageData)
                            // print("image bounds \(self.productImageView.image?.size)")
                        })
                    }
                }
                catch {
                    print(error)
                }
            })
        }
    }
    
    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if product != nil {
            tableView.reloadData()
        }
        title = TextConstants.ViewControllerTitle
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // suggested by http://useyourloaf.com/blog/self-sizing-table-view-cells/
        if product != nil {
            tableView.reloadData()
        }

    }
    
    // MARK: Gestures
    
    @IBAction func leftSwipeGestureRecognizer(sender: UISwipeGestureRecognizer) {
        // left swipe should move to the completion state VC
        if (sender.direction == .Left) {
            performSegueWithIdentifier(Storyboard.ShowPreviousUnwindSegueIdentifier, sender: self)
        }
    }
    
    @IBAction func rightSwipeGestureRecognizer(sender: UISwipeGestureRecognizer) {
        // right swipe should move to the Ingredients VC
        if (sender.direction == .Right) {
            performSegueWithIdentifier(Storyboard.ShowNextSegueIdentifier, sender: self)
        }
    }
    
    // MARK: - Navigation

    @IBAction func returnToIdentificationVC(segue:UIStoryboardSegue) {
        if let _ = segue.sourceViewController as? IngredientsTableViewController {
            if product != nil {
                tableView.reloadData()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowIdentificationSegueIdentifier:
                if let vc = segue.destinationViewController as? imageViewController {
                    vc.image = identificationImage
                    vc.imageTitle = TextConstants.ShowIdentificationTitle
                }
            case Storyboard.ShowNextSegueIdentifier:
                if let vc = segue.destinationViewController as? IngredientsTableViewController {
                    vc.product = product
                }
            default: break
            }
        }
    }

}
