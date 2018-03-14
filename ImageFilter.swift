//
//  ImageFilter.swift
//  ImageApp
//
//  Created by kle on 2018-03-13.
//

import Foundation

class ImageFilter: NSObject {
    
    var mImage: CGImage?
    var mCIImage: CIImage?
    
    var mProfile: Profile?
    
    var mCIExposure: CIFilter?
    var mCIColorControls: CIFilter?
    var mCIColorCube: CIFilter?
    
    init(image inImage: CGImage) {
        super.init()
        mImage = inImage
        mCIImage = CIImage.init(cgImage: inImage)
    }
    
    //
    // Build a 3D lookup texture for use with soft-proofing
    // The resulting table is suitable for use in OpenGL to accelerate
    // color management in hardware.
    //
    func setColorCubeFilterDataForGridPoints(gridPoints: size_t) -> Void {
        var data: NSData? = nil
        var success = true;
        var count: Int = (gridPoints*gridPoints*gridPoints) * 4;
        var size: Int = count * MemoryLayout<Float>.size;
        // var floatData: Float?
        
        //var linRGB: Profile? = Profile.
        

        //        var data: CFData? = nil
        //        //CFDataRef   data = NULL;
        //
        //        var success = true
        //        var count: size_t = (gridPoints*gridPoints*gridPoints) * 4
        //        var size: size_t = count * MemoryLayout<Float>.size
        //        var floatData: Float// = (float*) malloc (size)
    }
    
    
    // specify profile for use with image effect transform
    func setProfile(profile: Profile) -> Void {
        mProfile = profile;
        
        if (mProfile == nil)
        {
            mCIColorCube = nil;
        }
        else
        {
            // Use the CIColorCube filter three-dimensional color table
            // to transform the source image pixels
            if (mCIColorCube == nil)
            {
                mCIColorCube = CIFilter.init(name: "CIColorCube")
            }
            // Get the transformed data
            let kSoftProofGrid = 32
            
            // Specify Cube Data for the CIColorCube filter
            self.setColorCubeFilterDataForGridPoints(gridPoints: kSoftProofGrid)
            
            mCIColorCube?.setValue(kSoftProofGrid, forKey: "inputCubeDimension")
        }
    }
    
    // Use CIExposureAdjust Color adjustment filter change color values.
    // The CIExposureAdjust filter adjusts the exposure setting for an image by mimicking
    // a camera’s F-stop adjustment.
    //
    func setExposure(exposure: Float) -> Void {
        if (mCIExposure == nil)
        {
            mCIExposure = CIFilter.init(name: "CIExposureAdjust")
        }
        mCIExposure?.setValue(exposure, forKey: "inputEV")
    }
    
    // Use the CIColorControls filter to adjust saturation
    //
    func setSaturation(saturation: Float) -> Void {
        if (mCIColorControls == nil)
        {
            mCIColorControls = CIFilter.init(name: "CIColorControls")
        }
        
        // set new saturation value
        mCIColorControls?.setValue(saturation, forKey: "inputSaturation")
        
        // hold brightness unchanged. kCIAttributeIdentity = A value that results
        // in no effect on the input image.
        let brightness = mCIColorControls?.attributes["inputBrightness"] as! NSDictionary
        let brightnessVal = brightness["CIAttributeIdentity"]
        mCIColorControls?.setValue(brightnessVal, forKey: "inputBrightness")
        
        // hold contrast unchanged. kCIAttributeIdentity = A value that results
        // in no effect on the input image.
        let contrast = mCIColorControls?.attributes["inputContrast"] as! NSDictionary
        let contrastVal = contrast["CIAttributeIdentity"]
        mCIColorControls?.setValue(contrastVal, forKey: "inputBrightness")
    }
    
    func imageWithTransform(ctm: CGAffineTransform) -> CIImage {
        
        // Returns a new image representing the original image with the transform
        // 'ctm' appended to it.
        var ciimg: CIImage = mCIImage!.applying(ctm)
        
        // exposure adjustment
        if (mCIExposure != nil)
        {
            mCIExposure?.setValue(ciimg, forKey: "inputImage")
            ciimg = mCIExposure?.value(forKey: "outputImage") as! CIImage
        }
        
        // saturation adjustment
        if (mCIColorControls != nil)
        {
            mCIColorControls?.setValue(ciimg, forKey: "inputImage")
            ciimg = mCIColorControls?.value(forKey: "outputImage") as! CIImage
        }
        
        // three-dimensional color table adjustment
        if ((mCIColorCube) != nil)
        {
            mCIColorCube?.setValue(ciimg, forKey: "inputImage")
            ciimg = mCIColorCube?.value(forKey: "outputImage") as! CIImage
        }
        
        return ciimg;
    }
    
    
    func imageBytesPerRow(colorSpace: icColorSpaceSignature) -> size_t {
        
        var bytesPerRow: size_t = 0
        let width: size_t = mImage!.width
        
        switch (colorSpace) {
        case icSigGrayData:
            bytesPerRow = width
            break
        case icSigRgbData:
            bytesPerRow = width*4
            break
        case icSigCmykData:
            bytesPerRow = width*4
            break
        default:
            break
        }
        
        return (bytesPerRow)
    }
    
    func imageAlphaInfo(colorSpace: icColorSpaceSignature) -> CGImageAlphaInfo {
        
        var alphaInfo: CGImageAlphaInfo = CGImageAlphaInfo.none
        
        switch (colorSpace) {
        case icSigGrayData:
            alphaInfo = CGImageAlphaInfo.none /* RGB. */
            break
        case icSigRgbData:
            alphaInfo = CGImageAlphaInfo.premultipliedLast/* premultiplied RGBA */
            break
        case icSigCmykData:
            alphaInfo = CGImageAlphaInfo.none/* RGB. */
            break
        default:
            break
        }
        
        return (alphaInfo)
    }
    
    func fillContextWithWhite(context: CGContext, fillRect: CGRect) -> Void {
        
        let graySpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let whiteColor: CGColor? = CGColor(colorSpace: graySpace, components: [1.0, 1.0])
        
        context.setFillColor(whiteColor!)
        context.fill(fillRect)
    }
    
    func renderImageWithExposureAdjustment(ciimg: CIImage, context: CIContext, rect: CGRect) -> Void {
        
        var outputImage: CIImage? = nil
        // exposure adjustment
        if (mCIExposure != nil)
        {
            mCIExposure?.setValue(ciimg, forKey: "inputImage")
            outputImage = mCIExposure?.value(forKey: "outputImage") as? CIImage
        }
        
        // three-dimensional color table adjustment
        if (mCIColorControls != nil)
        {
            mCIColorControls?.setValue(outputImage, forKey: "inputImage")
            outputImage = mCIExposure?.value(forKey: "outputImage") as? CIImage
        }
        let extent: CGRect = ciimg.extent
        
        context.draw(ciimg, in: rect, from: extent)
    }
    
    func drawFilteredImage(drawContext: CGContext, imageRect drawImageRect: CGRect) -> Void {
        
        if mImage == nil {
            return
        }
        
        // calculate bits per pixel and row bytes and alphaInfo
        let bitsPerComponent: size_t = 8
        
        var prof: Profile? = mProfile
        if prof == nil {
            prof = Profile.withSRGB()
        }
        
        let bytesPerRow: size_t = self.imageBytesPerRow(colorSpace: (prof?.spaceType())!)
        let alphaInfo: CGImageAlphaInfo = self.imageAlphaInfo(colorSpace: (prof?.spaceType())!)
        let context: CGContext = CGContext(data: nil, width: (mImage?.width)!, height: (mImage?.height)!,
                                           bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow,
                                           space: prof?.colorspace() as! CGColorSpace, bitmapInfo: alphaInfo.rawValue)!
        
        let cicontext: CIContext = CIContext.init(cgContext: context, options: nil)
        let rect: CGRect = CGRect(origin: CGPoint(x:0, y: 0), size: CGSize(width:(mImage?.width)!, height: (mImage?.height)!))
        
        // If context doesn't support alpha then first fill it with white.
        // That is most likely to be desireable.
        if (alphaInfo == CGImageAlphaInfo.none)
        {
            self.fillContextWithWhite(context: context, fillRect: rect)
        }
        
        self.renderImageWithExposureAdjustment(ciimg: mCIImage!, context: cicontext, rect: rect)
        
        // create filtered image
        let image: CGImage = context.makeImage()!
        
        // draw image to destination context
        drawContext.draw(image, in: drawImageRect)
    }
    
    func writeImageToURL(absURL: NSURL, ofType typeName: NSString, properties: NSDictionary, error outError: inout NSError) -> Bool {
        var success = true
        var dest: CGImageDestination? = nil
        
        if mImage == nil {
            success = false
        }
        
        if success
        {
            // Create an image destination writing to `url'
            dest = CGImageDestinationCreateWithURL(absURL, typeName, 1, nil)
            if dest == nil {
                success = false
            }
        }
        
        if success
        {
            // calculate bits per pixel and row bytes and alphaInfo
            let bitsPerComponent: size_t = 8
            
            var prof: Profile? = mProfile
            if prof == nil {
                prof = Profile.withSRGB()
            }
            
            let bytesPerRow: size_t = self.imageBytesPerRow(colorSpace: (prof?.spaceType())!)
            let alphaInfo: CGImageAlphaInfo = self.imageAlphaInfo(colorSpace: (prof?.spaceType())!)
            let context: CGContext = CGContext(data: nil, width: (mImage?.width)!, height: (mImage?.height)!,
                                               bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow,
                                               space: prof?.colorspace() as! CGColorSpace, bitmapInfo: alphaInfo.rawValue)!
            
            let cicontext: CIContext = CIContext.init(cgContext: context, options: nil)
            let rect: CGRect = CGRect(origin: CGPoint(x:0, y: 0), size: CGSize(width:(mImage?.width)!, height: (mImage?.height)!))
            
            
            // If context doesn't support alpha then first fill it with white.
            // That is most likely to be desireable.
            if (alphaInfo == CGImageAlphaInfo.none)
            {
                self.fillContextWithWhite(context: context, fillRect: rect)
            }
            
            self.renderImageWithExposureAdjustment(ciimg: mCIImage!, context: cicontext, rect: rect)
            
            // create filtered image
            let image: CGImage = context.makeImage()!
            
            
            // Set the image in the image destination to be `image' with
            // optional properties specified in saved properties dict.
            CGImageDestinationAddImage(dest!, image, properties);
            
            success = CGImageDestinationFinalize(dest!);
        }
        
        if (!success)
        {
            outError = NSError.init(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: nil)
        }
        return success
    }
    
    
}

