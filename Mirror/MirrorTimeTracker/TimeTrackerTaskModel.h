//
//  TimeTrackerTaskModel.h
//  Mirror
//
//  Created by wangyuqing on 2022/9/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeTrackerTaskModel : NSObject

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, strong) NSString *timeInfo;
@property (nonatomic, strong) UIColor *color;

- (instancetype)initWithTitle:(NSString *)taskName color:(UIColor *)color;
- (void)didStartTask;
- (void)didStopTask;

@end

NS_ASSUME_NONNULL_END
