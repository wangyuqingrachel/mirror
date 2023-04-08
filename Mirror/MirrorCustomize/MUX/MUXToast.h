//
//  MUXToast.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MUXToast : NSObject

+ (void)show:(NSString *)message onVC:(UIViewController *)vc color:(MirrorColorType)color;


@end

NS_ASSUME_NONNULL_END
