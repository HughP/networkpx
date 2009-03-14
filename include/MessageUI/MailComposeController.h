#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

// TODO: Check ABI compatibility

@class UIView, MessageTextAttachment;

@interface MailComposeController : NSObject
+(BOOL)isSetupForDelivery;
@property(readonly,nonatomic) UIView* view;
-(id)initForContentSize:(CGSize)size;
-(id)initForContentSize:(CGSize)size showKeyboardImmediately:(BOOL)showKeyboardImmediately;
-(void)setDelegate:(id)delegate;
-(BOOL)needsDelivery;
-(BOOL)deliverMessage;
-(NSString*)errorTitle;
-(NSString*)errorDescription;

-(void)setSubject:(NSString*)subject;
-(void)setToRecipients:(NSArray*)recipients;	// NSArray of NSStrings beings email addresses.
-(void)setCcRecipients:(NSArray*)recipients;
-(void)setBccRecipients:(NSArray*)recipients;

-(void)addAttachment:(MessageTextAttachment*)attachment;
-(void)addInlineAttachmentAtPath:(NSString*)path includeDirectoryContents:(BOOL)includeDirectoryContents;
-(void)addInlineAttachmentWithData:(NSData*)data preferredFilename:(NSString*)filename mimeType:(NSString*)mineType;

-(void)autosaveImmediately;
-(void)cancelAutosave;

-(oneway void)releaseOnMainThread;

@end