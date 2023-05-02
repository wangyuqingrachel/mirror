//
//  GridViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/2.
//

#import "GridViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import "GridCollectionViewCell.h"
#import "MirrorMacro.h"
#import "MirrorLanguage.h"
#import "MirrorDataModel.h"
#import "MirrorDataManager.h"
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "GridComponent.h"
#import "SpanLegend.h"
#import "MirrorPiechart.h"

static CGFloat const kLeftRightSpacing = 20;
static CGFloat const kCellWidth = 30;
static CGFloat const kCellSpacing = 3;

@interface GridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) SpanLegend *legendView;
@property (nonatomic, strong) MirrorPiechart *piechartView;
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, assign) NSInteger startTimestamp;
@property (nonatomic, assign) NSInteger selectedCellIndex;

@end

@implementation GridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithNaviController:self.navigationController title:[MirrorLanguage mirror_stringWithKey:@"activities"] leftButton:nil rightButton:nil];
}


- (void)p_setupUI
{
    // collection view
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.height.mas_equalTo(kCellWidth*7 + kCellSpacing*6);
    }];
    [self.view addSubview:self.legendView];
    [self.legendView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(20);
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.view addSubview:self.piechartView];
    CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
    [self.piechartView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (width == [[self leftWidthLeftHeight][0] floatValue]) { // 宽度小于高度
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(10 + ([[self leftWidthLeftHeight][1] floatValue]-[[self leftWidthLeftHeight][0] floatValue])/2);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        } else {
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(10);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        }
    }];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == _selectedCellIndex) {
        _selectedCellIndex = NSIntegerMin; // 取消选择
    } else {
        _selectedCellIndex = indexPath.item; // 选择
    }
    long timestamp = _startTimestamp + indexPath.item * 86400;
    NSMutableArray<MirrorDataModel *> *data = [MirrorDataManager getDataWithStart:timestamp end:timestamp+86400];
    [self.legendView updateWithData:data];
    [self.legendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.piechartView updateWithData:data width:MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]) enableInteractive:YES];
    [collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return  self.data.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GridCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[GridCollectionViewCell identifier] forIndexPath:indexPath];
    NSInteger targetTimestamp = _startTimestamp + indexPath.item * 86400;
    GridComponent *grid = self.data[[@(targetTimestamp) stringValue]];
    BOOL isSelected = indexPath.item==_selectedCellIndex;
    [cell configWithGridComponent:grid isSelected:isSelected];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCellWidth, kCellWidth);
}



#pragma mark - Getters

- (SpanLegend *)legendView
{
    if (!_legendView) {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
        components.timeZone = [NSTimeZone systemTimeZone];
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        long timestamp = [[gregorian dateFromComponents:components] timeIntervalSince1970];
        _legendView = [[SpanLegend alloc] initWithData:[MirrorDataManager getDataWithStart:timestamp end:timestamp+86400]];
    }
    return _legendView;
}

- (MirrorPiechart *)piechartView
{
    if (!_piechartView) {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
        components.timeZone = [NSTimeZone systemTimeZone];
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        long timestamp = [[gregorian dateFromComponents:components] timeIntervalSince1970];
        CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
        _piechartView = [[MirrorPiechart alloc] initWithData:[MirrorDataManager getDataWithStart:timestamp end:timestamp+86400] width:width enableInteractive:YES];
    }
    return _piechartView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = kCellSpacing;
        layout.minimumInteritemSpacing = kCellSpacing;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        [_collectionView registerClass:[GridCollectionViewCell class] forCellWithReuseIdentifier:[GridCollectionViewCell identifier]];
    }
    return _collectionView;
}

// key是00:00的timestamp，value是GridComponent
- (NSMutableDictionary *)data
{
    if (!_data) {
        _data = [NSMutableDictionary new];
        NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
        NSInteger minTimestamp = NSIntegerMax;
        NSInteger maxTimestamp = NSIntegerMin;
        for (id key in mirrorDict.allKeys) {
            MirrorDataModel *task = mirrorDict[key];
            for (int i=0; i<task.periods.count; i++) {
                NSInteger timestamp = [task.periods[i][0] integerValue];
                if (task.periods[i].count == 2 && timestamp < minTimestamp) {
                    minTimestamp = timestamp;
                }
                if (task.periods[i].count == 2 && timestamp > maxTimestamp) {
                    maxTimestamp = timestamp;
                }
            }
        }
        // 2023.5.1 3:00 到 2023.5.3 19:00 算三天
        if (maxTimestamp != NSIntegerMin && minTimestamp != NSIntegerMax) { // 有 有效数据
            NSDate *minDate = [NSDate dateWithTimeIntervalSince1970:minTimestamp];
            NSDate *maxDate = [NSDate dateWithTimeIntervalSince1970:maxTimestamp];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *minComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:minDate];
            minComponents.timeZone = [NSTimeZone systemTimeZone];
            NSDateComponents *maxComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:maxDate];
            maxComponents.timeZone = [NSTimeZone systemTimeZone];
            
            minComponents.hour = 0;
            minComponents.minute = 0;
            minComponents.second = 0;
            maxComponents.hour = 0;
            maxComponents.minute = 0;
            maxComponents.second = 0;
            
            minDate = [gregorian dateFromComponents:minComponents];// 2023.5.1 00:00
            maxDate = [gregorian dateFromComponents:maxComponents]; // 2023.5.3 00:00
            NSTimeInterval time= [maxDate timeIntervalSinceDate:minDate];
            NSInteger dateNum = (time / 86400) + 1; // time/86400 = 2天，因为都算了零点。所以后面还要加上一天
            
            
            NSInteger numOfInvalidCell = 0;
            if ([MirrorSettings appliedWeekStarsOnMonday]) {
                if (minComponents.weekday > 1) {
                    numOfInvalidCell = minComponents.weekday - 1;
                } else {
                    numOfInvalidCell = 6;
                }
            } else {
                numOfInvalidCell = minComponents.weekday;
            }
            _startTimestamp = [minDate timeIntervalSince1970] - numOfInvalidCell*86400; // 第一个cell(可能是invalid的)
            // 今天的0点
            NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
            components.timeZone = [NSTimeZone systemTimeZone];
            components.hour = 0;
            components.minute = 0;
            components.second = 0;
            long timestamp = [[gregorian dateFromComponents:components] timeIntervalSince1970];
            _selectedCellIndex = (timestamp-_startTimestamp)/86400;
            // 添加前面的空cell
            for (int i=0; i<numOfInvalidCell; i++) {
                NSInteger invalidDateTimestamp = [minDate timeIntervalSince1970] - (numOfInvalidCell-i)*86400;
                GridComponent *grid = [[GridComponent alloc] initWithValid:NO thatDayTasks:[NSMutableArray new]];
                [_data setValue:grid forKey:[@(invalidDateTimestamp) stringValue]];
            }
            // 添加valid cell
            for (int i=0; i<dateNum; i++) {
                NSInteger validDateTimestamp = [minDate timeIntervalSince1970] + i*86400;
                GridComponent *grid = [[GridComponent alloc] initWithValid:YES thatDayTasks:[MirrorDataManager getDataWithStart:validDateTimestamp end:validDateTimestamp+86400]];
                [_data setValue:grid forKey:[@(validDateTimestamp) stringValue]];
            }
        }
    }
    return _data;
}

#pragma mark - Privates

- (NSArray *)leftWidthLeftHeight
{
    CGFloat leftHeight = kScreenHeight - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height - (kCellWidth*7 + kCellSpacing*6) - 20 - [self.legendView legendViewHeight] - 10 - 20 -  kTabBarHeight;
    CGFloat leftWidth = kScreenWidth - 2*kLeftRightSpacing;

    return @[@(leftWidth), @(leftHeight)];
}



@end
