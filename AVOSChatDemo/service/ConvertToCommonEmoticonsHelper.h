#import <Foundation/Foundation.h>

@interface ConvertToCommonEmoticonsHelper : NSObject

@property NSArray* namesToPictures;

+ (NSString *)convertToCommonEmoticons:(NSString *)text;
+ (NSString *)convertToSystemEmoticons:(NSString *)text;
@end
