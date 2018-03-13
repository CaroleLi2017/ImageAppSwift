//
//  ImageDocController.swift
//  ImageApp
//
//  Created by Darya Ismailova on 2018-03-13.
//

import Foundation

func ImageIOLocalizedString (key: String) -> String?{
    let b: Bundle! = Bundle(identifier: "com.apple.ImageIO.framework")
    
    return b.localizedString(forKey: key, value: key, table: "CGImageSource")
}

@objc class ImageDocController : NSDocumentController{
    
    override public var defaultType: String {
        get {
            return "public.tiff"
        }
    }
    
    // Return the names of NSDocument subclasses supported by this application.
    // In this app, the only class is "ImageDoc".
    //
    override var documentClassNames:[String]{
        get {
            return ["ImageDoc"]
        }
    }
    
    // Given a document type name, return the subclass of NSDocument
    // that should be instantiated when opening a document of that type.
    // In this app, the only class is "ImageDoc".
    //
    // REMOVED
//    - (Class)documentClassForType:(NSString *)typeName
//    {
//    return [[NSBundle mainBundle] classNamed:@"ImageDoc"];
//    }

    // Given a document type name, return a string describing the document
    // type that is fit to present to the user.
    //
    func displayNameForType(typeName: String) -> String?{
        return ImageIOLocalizedString(key: typeName)
    }
    
    // Return the name of the document type that should be used when opening a URL
    // In this app, we return the UTI type returned by CGImageSourceGetType.
    
    func typeForContentsOfURL(absURL: NSURL, outError error:inout NSError ) -> String
    {
        guard let isrc: CGImageSource = CGImageSourceCreateWithURL(absURL, nil) else {
            return ""
        }
        guard let type = CGImageSourceGetType(isrc) else {
            return ""
        }
        return type as String
    }

    // Given a document type, return an array of corresponding file name extensions
    // and HFS file type strings of the sort returned by NSFileTypeForHFSTypeCode().
    // In this app, 'typeName' is a UTI type so we can call UTTypeCopyDeclaration().
    //
    //    func fileExtensionsFromType(typeName: String)-> NSArray {
//      REMOVED
//        }
    
    
//    - (NSArray*) fileExtensionsFromType:(NSString *)typeName;
//    {
//      REMOVED
//    }
    
}
