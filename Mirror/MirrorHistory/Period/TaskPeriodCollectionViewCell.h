//
//  TaskPeriodCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/15.
//

#import <UIKit/UIKit.h>
#import "MirrorDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EditPeriodForTaskProtocol <NSObject>

- (void)pushEditPeriodSheet:(UIViewController *)editVC;

@end

@interface TaskPeriodCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) UIViewController<EditPeriodForTaskProtocol> *delegate;
+ (NSString *)identifier;
- (void)configWithTaskname:(NSString *)taskName periodIndex:(NSInteger)index;


@end

NS_ASSUME_NONNULL_END