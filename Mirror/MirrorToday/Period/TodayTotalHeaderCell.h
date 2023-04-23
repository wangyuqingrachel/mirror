//
//  TodayTotalHeaderCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UpdateCrownDelegate <NSObject>

- (void)showCrown;
- (void)hideCrown;

@end

@interface TodayTotalHeaderCell : UICollectionViewCell

@property (nonatomic, weak) id<UpdateCrownDelegate> crownDelegate;
- (void)configWithTasknames:(NSArray<NSString *> *)taskNames periodIndexes:(NSArray *)indexes;

@end

NS_ASSUME_NONNULL_END
