#include <math.h>
#include <GraphicsUtilities.h>
#import <UIKit/UIImage.h>

CGImageRef GUImageCreateByConcatSubimages (CGImageRef img,
										   CGRect subrect1,
										   CGRect subrect2,
										   bool tileVertically) {
	CGRect imgRect = CGRectZero;
	if (tileVertically)
		imgRect.size = CGSizeMake(subrect1.size.width, subrect1.size.height + subrect2.size.height);
	else
		imgRect.size = CGSizeMake(subrect1.size.width + subrect2.size.width, subrect1.size.height);
	
	CGImageRef subimg1 = CGImageCreateWithImageInRect(img, subrect1);
	CGImageRef subimg2 = CGImageCreateWithImageInRect(img, subrect2);
	
	GUCreateContext(c, imgRect.size.width, imgRect.size.height);
	if (tileVertically) {
		CGContextDrawImage(c, CGRectMake(0, 0, subrect2.size.width, subrect2.size.height), subimg2);
		CGContextDrawImage(c, CGRectMake(0, subrect2.size.height, subrect1.size.width, subrect1.size.height), subimg1);
	} else {
		CGContextDrawImage(c, CGRectMake(0, 0, subrect1.size.width, subrect1.size.height), subimg1);
		CGContextDrawImage(c, CGRectMake(subrect1.size.width, 0, subrect2.size.width, subrect2.size.height), subimg2);
	}
	
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	
	CGImageRelease(subimg1);
	CGImageRelease(subimg2);
	
	CGContextRelease(c);
	
	return finalImg;
}

CGImageRef GUImageCreateByComposition (CGImageRef foreground,
									   CGImageRef background,
									   CGRect fgRect,
									   CGRect bgSubRect) {
	GUCreateContext(c, bgSubRect.size.width, bgSubRect.size.height);
	CGImageRef subimage = NULL;
	if (background != NULL) {
		if (bgSubRect.size.width == CGImageGetWidth(background) && bgSubRect.size.height == CGImageGetHeight(background))
			subimage = CGImageRetain(background);
		else
			subimage = CGImageCreateWithImageInRect(background, bgSubRect);
		CGContextDrawImage(c, CGRectMake(0, 0, bgSubRect.size.width, bgSubRect.size.height), subimage);
	}
	CGContextDrawImage(c, fgRect, foreground);
	
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	
	CGImageRelease(subimage);
	CGContextRelease(c);
	
	return finalImg;
}

CGImageRef GUImageCreateWithPatching(CGImageRef img, CGRect src, CGRect target) {
	CGRect imgRect = CGRectMake(0, 0, CGImageGetWidth(img), CGImageGetHeight(img));
	GUCreateContext(c, imgRect.size.width, imgRect.size.height);
	
	CGContextDrawImage(c, imgRect, img);
	CGImageRef subImg = CGImageCreateWithImageInRect(img, src);
	CGContextSetBlendMode(c, kCGBlendModeCopy);
	CGContextDrawImage(c, target, subImg);
	
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	
	CGImageRelease(subImg);
	CGContextRelease(c);
	return finalImg;
}

CGImageRef GUImageCreateWithMask(CGImageRef src, CGImageRef mask) {
	CGRect imgRect = CGRectMake(0, 0, CGImageGetWidth(src), CGImageGetHeight(src));
	GUCreateContext(c, imgRect.size.width, imgRect.size.height);
	CGContextClipToMask(c, imgRect, mask);
	CGContextDrawImage(c, imgRect, src);
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	CGContextRelease(c);
	return finalImg;
}

CGImageRef GUImageCreateWithCappedMask(CGImageRef src, CGImageRef mask, GUCaps caps) {
	CGRect imgRect = CGRectMake(0, 0, CGImageGetWidth(src), CGImageGetHeight(src));
	GUCreateContext(c, imgRect.size.width, imgRect.size.height);
	GUDrawImageWithCaps(c, imgRect, mask, caps);
	CGContextSetBlendMode(c, kCGBlendModeSourceIn);
	CGContextDrawImage(c, imgRect, src);
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	CGContextRelease(c);
	return finalImg;
}
 
CGImageRef GUImageCreateWithCaps(CGImageRef img, CGRect rect, GUCaps caps) {
	GUCreateContext(c, rect.size.width, rect.size.height);
	GUDrawImageWithCaps(c, rect, img, caps);
	CGImageRef finalImg = CGBitmapContextCreateImage(c);
	CGContextRelease(c);
	return finalImg;
}

void GUDrawImageWithCaps(CGContextRef c, CGRect rect, CGImageRef img, GUCaps caps) {
	// assert: img.width > caps.left+caps.right && img.height > caps.top+caps.bottom.
	bool scaleDownX = rect.size.width <= caps.left + caps.right + 1,
		scaleDownY = rect.size.height <= caps.top + caps.bottom + 1;
	size_t imgWidth = CGImageGetWidth(img), imgHeight = CGImageGetHeight(img);
	
	if (scaleDownX && scaleDownY) {
		// the caps are bigger than the image: just draw the image.
		CGContextDrawImage(c, rect, img);
	} else if (scaleDownX) {
		// create a 3-part image vertically.
		CGImageRef top = CGImageCreateWithImageInRect(img,
													  CGRectMake(0, 0,
																 imgWidth, caps.top));
		CGImageRef middle = CGImageCreateWithImageInRect(img,
														 CGRectMake(0, caps.top,
																	imgWidth, imgHeight-caps.top-caps.bottom));
		CGImageRef bottom = CGImageCreateWithImageInRect(img,
														 CGRectMake(0, imgHeight-caps.bottom,
																	imgWidth, caps.bottom));
		
		CGContextDrawImage(c, CGRectMake(rect.origin.x, rect.origin.y,
										 rect.size.width, caps.top), top);
		CGContextDrawImage(c, CGRectMake(rect.origin.x, rect.origin.y+caps.top,
										 rect.size.width, rect.size.height-caps.top-caps.bottom), middle);
		CGContextDrawImage(c, CGRectMake(rect.origin.x, rect.origin.y+rect.size.height-caps.bottom,
										 rect.size.width, caps.bottom), bottom);
		
		CGImageRelease(top);
		CGImageRelease(middle);
		CGImageRelease(bottom);
	} else if (scaleDownY) {
		// create a 3-part image horizontally.
		CGImageRef left = CGImageCreateWithImageInRect(img, CGRectMake(0, 0,
																	   caps.left, imgHeight));
		CGImageRef middle = CGImageCreateWithImageInRect(img, CGRectMake(caps.left, 0,
																		 imgWidth-caps.left-caps.right, imgHeight));
		CGImageRef right = CGImageCreateWithImageInRect(img, CGRectMake(imgWidth-caps.right, 0,
																		caps.right, imgHeight));
		
		CGContextDrawImage(c, CGRectMake(rect.origin.x, rect.origin.y,
										 caps.left, rect.size.height), left);
		CGContextDrawImage(c, CGRectMake(rect.origin.x+caps.left, rect.origin.y,
										 rect.size.width-caps.left-caps.right, rect.size.height), middle);
		CGContextDrawImage(c, CGRectMake(rect.origin.x+rect.size.width-caps.right, rect.origin.y,
										 caps.right, rect.size.height), right);
		
		CGImageRelease(left);
		CGImageRelease(middle);
		CGImageRelease(right);
	} else {
		// create a 9-part image.
		/*
		 
		 +---+---+---+ ^
		 | Q | W | E | | w3
		 +---+---+---+ x
		 | A | S | D | | w2
		 +---+---+---+ x
		 | Z | X | C | | w1
		 +---+---+---+ v
          <-> <-> <->
		   w1  w2  w3
		 
		*/
		
		CGFloat w1 = caps.left, w2 = imgWidth-caps.left-caps.right, w3 = caps.right;
		CGFloat h1 = caps.top, h2 = imgHeight-caps.top-caps.bottom, h3 = caps.bottom;
		
		CGFloat x1 = 0, x2 = w1, x3 = w1+w2;
		CGFloat y1 = 0, y2 = h1, y3 = h1+h2;
		
		CGImageRef Q = CGImageCreateWithImageInRect(img, CGRectMake(x1, y1, w1, h1));
		CGImageRef W = CGImageCreateWithImageInRect(img, CGRectMake(x2, y1, w2, h1));
		CGImageRef E = CGImageCreateWithImageInRect(img, CGRectMake(x3, y1, w3, h1));
		CGImageRef A = CGImageCreateWithImageInRect(img, CGRectMake(x1, y2, w1, h2));
		CGImageRef S = CGImageCreateWithImageInRect(img, CGRectMake(x2, y2, w2, h2));
		CGImageRef D = CGImageCreateWithImageInRect(img, CGRectMake(x3, y2, w3, h2));
		CGImageRef Z = CGImageCreateWithImageInRect(img, CGRectMake(x1, y3, w1, h3));
		CGImageRef X = CGImageCreateWithImageInRect(img, CGRectMake(x2, y3, w2, h3));
		CGImageRef C = CGImageCreateWithImageInRect(img, CGRectMake(x3, y3, w3, h3));
		
		w2 = rect.size.width-w1-w3;
		h2 = rect.size.height-h1-h3;
		
		x1 = rect.origin.x;
		x2 = rect.origin.x+w1;
		x3 = x2+w2;
		y3 = rect.origin.y;
		y2 = rect.origin.y+h3;
		y1 = y2+h2;
		
		CGContextDrawImage(c, CGRectMake(x1, y1, w1, h1), Q);
		CGContextDrawImage(c, CGRectMake(x2, y1, w2, h1), W);
		CGContextDrawImage(c, CGRectMake(x3, y1, w3, h1), E);
		CGContextDrawImage(c, CGRectMake(x1, y2, w1, h2), A);
		CGContextDrawImage(c, CGRectMake(x2, y2, w2, h2), S);
		CGContextDrawImage(c, CGRectMake(x3, y2, w3, h2), D);
		CGContextDrawImage(c, CGRectMake(x1, y3, w1, h3), Z);
		CGContextDrawImage(c, CGRectMake(x2, y3, w2, h3), X);
		CGContextDrawImage(c, CGRectMake(x3, y3, w3, h3), C);
		
		CGImageRelease(Q);
		CGImageRelease(W);
		CGImageRelease(E);
		CGImageRelease(A);
		CGImageRelease(S);
		CGImageRelease(D);
		CGImageRelease(Z);
		CGImageRelease(X);
		CGImageRelease(C);
	}
}

float GUAverageLuminance (CGImageRef image) {
	// Ref: http://developer.apple.com/qa/qa2007/qa1509.html on getting bitmap data
	
	float retval = NAN;
	
	size_t imgWidth = CGImageGetWidth(image), imgHeight = CGImageGetHeight(image);
	GUCreateContext(c, imgWidth, imgHeight);
	if (c == NULL)
		return retval;
	
	CGContextDrawImage(c, CGRectMake(0, 0, imgWidth, imgHeight), image);
	
	// the total RGBA components
	UInt32 A = 0, R = 0, G = 0, B = 0;
	struct{char a,r,g,b; }* data = CGBitmapContextGetData(c);
	size_t area = imgWidth * imgHeight;
	
	if (data != NULL) {
		for (ptrdiff_t i = 0; i < area; ++ i) {
			A += data[i].a;
			R += data[i].r;
			G += data[i].g;
			B += data[i].b;
		}
		
		free(data);
	}
	
	if (A != 0) {
		retval = (0.2126*R + 0.7152*G + 0.0722*B)/A;
	}
	
	CGContextRelease(c);
	return retval;
}

CGImageRef GUImageCreateWithPNG(const char* filename) {
	CGDataProviderRef data = CGDataProviderCreateWithFilename(filename);
	if (data == NULL)
		return NULL;
	else {
		CGImageRef retimg = CGImageCreateWithPNGDataProvider(data, NULL, false, kCGRenderingIntentDefault);
		CGDataProviderRelease(data);
		return retimg;
	}
}

UIImage* GUCreateUIImageAndRelease(CGImageRef img) {
	UIImage* retval = [UIImage imageWithCGImage:img];
	CGImageRelease(img);
	return retval;
}