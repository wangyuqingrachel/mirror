//
//  HistogramCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/14.
//

#import "HistogramCollectionViewCell.h"
#import "MirrorTool.h"
#import <Masonry/Masonry.h>

@interface HistogramCollectionViewCell ()

@property (nonatomic, strong) UIView *coloredView;

@end

@implementation HistogramCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithData:(NSMutableArray<MirrorDataModel *> *)data index:(NSInteger)index
{
    float percentage = [self percentageFromData:data index:index];
    // 每次update都重新init coloredView以保证实时更新，先removeFromSuperview再设置为nil才是正确的顺序！
    [self.coloredView removeFromSuperview];
    self.coloredView = nil;
    [self addSubview:self.coloredView];
    self.coloredView.backgroundColor = [UIColor mirrorColorNamed:data[index].color];
    [self.coloredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0);
        make.height.mas_equalTo(self.frame.size.height * percentage);
    }];
}

- (float)percentageFromData:(NSMutableArray<MirrorDataModel *> *)data index:(NSInteger)index
{
    MirrorDataModel *task = data[index];
    long maxTime = 0;
    for (int i=0; i<data.count; i++) {
        long taskiTime = [MirrorTool getTotalTimeOfPeriods:data[i].periods]; // 第i个task的总时间
        if (taskiTime > maxTime) maxTime = taskiTime;
    }
    float percentage = maxTime ? [MirrorTool getTotalTimeOfPeriods:task.periods]/(double)maxTime : 0;
    return percentage;
}

- (UIView *)coloredView
{
    if (!_coloredView) {
        _coloredView = [UIView new];
        // cell自己的圆角
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){14., 14.}].CGPath;
        _coloredView.layer.mask = maskLayer;
    }
    return _coloredView;
}

@end
