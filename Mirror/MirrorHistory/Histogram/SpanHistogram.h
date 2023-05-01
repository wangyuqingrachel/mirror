//
//  SpanHistogram.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SpanHistogramDelegate <NSObject>  // push viewcontroller用

@end

@interface SpanHistogram : UIView

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) UIViewController<SpanHistogramDelegate> *delegate;

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data;

@end

NS_ASSUME_NONNULL_END
