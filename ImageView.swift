//
//  ImageView.swift
//  ImageApp
//
//  Created by cli mini on 2018-03-09.
//

import Foundation

let kMargin: Float = 10;


@objc class ImageView: NSView {
    //var mImageDoc: ImageDoc?
    
    @IBOutlet weak var mImageDoc: ImageDoc!
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect);
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newScreenProfile(n:)), name:NSNotification.Name.NSWindowDidChangeScreenProfile, object: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // This view completely covers its frame rectangle when drawing so return YES.
    //
    func opaque() -> ObjCBool {
        return true
    }

    
    override func draw(_ dirtyRect: NSRect) {
        
        // drawBackground
        let bgColor = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
        bgColor.set()
        
        let bPath = NSBezierPath(rect: self.bounds)
        bPath.fill()
        
        guard let doc = mImageDoc else {
            return
        }
        
        if doc.switchState()
        {
            self.drawCIImage()
        }
        else
        {
            self.drawImage()
        }
    }
    
    // Return a image transformation matrix that will fit the image in the view
    //
    func imageTransformToFitView() -> CGAffineTransform {

        let imageRect = CGRect(origin: CGPoint(x:0, y: 0), size: (mImageDoc?.imageSize())!)
        var ctm: CGAffineTransform = mImageDoc!.imageTransform()
    
        let ctmdSize: CGSize = imageRect.applying(ctm).size;
        let destSize: NSSize = NSInsetRect(self.bounds, CGFloat(kMargin), CGFloat(kMargin)).size
    
        // scale to fit in view rect
        let scale: CGFloat = min(destSize.width/ctmdSize.width, destSize.height/ctmdSize.height)
        ctm = ctm.concatenating(CGAffineTransform(scaleX: scale,y: scale));
    
        return ctm;
    }
    
    func drawImage() -> Void {
        
        let viewBounds: NSRect = self.bounds
        let imageRect: CGRect = CGRect(origin: CGPoint(x:0, y: 0), size: mImageDoc!.imageSize())
        
        // get transform matrix to fit image to view
        var ctm: CGAffineTransform = self.imageTransformToFitView();
        
        // center in view rect
        let ctmdSize = imageRect.applying(ctm).size
        ctm.tx += viewBounds.origin.x + (viewBounds.size.width - ctmdSize.width)/2;
        ctm.ty += viewBounds.origin.y + (viewBounds.size.height - ctmdSize.height)/2;
        
        let context = NSGraphicsContext.current()?.cgContext
        if (context==nil)
        {
            return;
        }
        
        // Concatenate the current graphics state's transformation matrix (the CTM)
        // with the affine transform `ctm'
        context?.concatenate(ctm);
        
        // use low quality interpolation while live resizing
        var q: CGInterpolationQuality = CGInterpolationQuality.high
        if self.inLiveResize {
            q = CGInterpolationQuality.none
        }
        
        context?.interpolationQuality = q
        
        // now draw using updated transform
        mImageDoc?.drawImage(context, imageRect: imageRect)
    }
    
    
    func drawCIImage() -> Void {
        
        let context = NSGraphicsContext.current()?.cgContext
        if (context==nil)
        {
            return;
        }
    
        // scale to fit in view rect
        let image: CIImage? = mImageDoc?.currentCIImage(with: self.imageTransformToFitView())
        if (image==nil)
        {
            return;
        }
    
        // center in view rect
        let viewBounds: NSRect = self.bounds
        let sRect: CGRect = image!.extent
        var dRect: CGRect = sRect
        
        dRect.origin.x = viewBounds.origin.x + (viewBounds.size.width - sRect.size.width)/2;
        dRect.origin.y = viewBounds.origin.y + (viewBounds.size.height - sRect.size.height)/2;
    
        let ciContext: CIContext = CIContext(cgContext: context!, options: nil)
        ciContext.draw(image!, in: dRect, from: sRect)
    }
    
    
    // Force a high quality update after live resizing
    override func viewDidEndLiveResize() -> Void {
    
        if !(mImageDoc?.switchState())!{//([mImageDoc switchState]==NO)
            
            self.needsDisplay = true
            //[self setNeedsDisplay:YES];
        }
    }
    
    func newScreenProfile(n: NSNotification) -> Void {
   
    }
}
