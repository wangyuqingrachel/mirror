//
//  DataViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/4.
//

#import "DataViewController.h"
#import "MirrorTabsManager.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"
#import "DataEntranceCollectionViewCell.h"
#import "OneDayHistogram.h"
#import "OneDayLegend.h"
#import "MirrorSettings.h"

static CGFloat const kLeftRightSpacing = 20;

@interface DataViewController () <OneDayLegendDelegate, OneDayHistogramDelegate>

@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) OneDayLegend *legendView;
@property (nonatomic, strong) OneDayHistogram *histogramView;

@end

@implementation DataViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskArchiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
    }
    return self;
}

- (void)restartVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.datePicker = nil;
    self.legendView = nil;
    self.histogramView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateDataTabItemWithTabController:self.tabBarController];
    [self viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData
{
    // 当页面没有出现在屏幕上的时候reloaddata不会触发UICollectionViewDataSource的几个方法，所以需要上面viewWillAppear做一个兜底。
    [self.legendView.collectionView reloadData];
    [self.legendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.histogramView.collectionView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self p_setupUI];
}

- (void)p_setupUI
{
    /*
     If a custom bar button item is not specified by either of the view controllers, a default back button is used and its title is set to the value of the title property of the previous view controller—that is, the view controller one level down on the stack.
     */
    self.navigationController.navigationBar.topItem.title = @""; //给父vc一个空title，让所有子vc的navibar返回文案都为空
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    
    CGFloat heightWeightRatio = self.datePicker.frame.size.height / self.datePicker.frame.size.width;
    [self.view addSubview:self.datePicker];
    [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.offset(kLeftRightSpacing);
        make.width.mas_equalTo(self.view.frame.size.width - 2*kLeftRightSpacing);
        make.height.mas_equalTo((self.view.frame.size.width - 2*kLeftRightSpacing) * heightWeightRatio);
    }];
    
    [self.view addSubview:self.legendView];
    [self.legendView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.datePicker.mas_bottom);
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.view addSubview:self.histogramView];
    [self.histogramView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(20);
        make.bottom.mas_equalTo(self.view).offset(-kTabBarHeight - 20);
    }];
}

#pragma mark - Getters

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        _datePicker.timeZone = [NSTimeZone systemTimeZone];
        _datePicker.preferredDatePickerStyle = UIDatePickerStyleInline;
        _datePicker.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _datePicker.overrideUserInterfaceStyle = [MirrorSettings appliedDarkMode] ? UIUserInterfaceStyleDark:UIUserInterfaceStyleLight;
        _datePicker.date = [NSDate now];
        [_datePicker addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
}


- (OneDayHistogram *)histogramView
{
    if (!_histogramView) {
        _histogramView = [[OneDayHistogram alloc] initWithDatePicker:self.datePicker];
        _histogramView.delegate = self;
    }
    return _histogramView;
}

- (OneDayLegend *)legendView
{
    if (!_legendView) {
        _legendView = [[OneDayLegend alloc] initWithDatePicker:self.datePicker];
        _legendView.delegate = self;
    }
    return _legendView;
}


@end
