//
//  TimeTrackerViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "TimeTrackerViewController.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "TimeTrackerTaskCollectionViewCell.h"
#import "TimeTrackerAddTaskCollectionViewCell.h"
#import "TimeTrackerDataManager.h"
#import "MirrorMacro.h"
#import "MirrorTabsManager.h"
#import "EditTaskViewController.h"
#import "AddTaskViewController.h"
#import "TimeTrackingView.h"
#import "MirrorStorage.h"

static CGFloat const kCellSpacing = 16; // cell之间的上下间距
static CGFloat const kCollectionViewPadding = 20; // 左右留白

@interface TimeTrackerViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EditTaskProtocol, AddTaskProtocol, TimeTrackingViewProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) TimeTrackerDataManager *dataManager;
@property (nonatomic, assign) BOOL applyImmersiveMode;

@end

@implementation TimeTrackerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVC) name:@"MirrorSwitchThemeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVC) name:@"MirrorSwitchLanguageNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadVC) name:@"MirrorSwitchImmersiveModeNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.collectionView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新tab item
    [MirrorTabsManager updateTimeTabItemWithTabController:self.tabBarController];
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.applyImmersiveMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredImmersiveMode"];
    [self  p_setupUI];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
            make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
            make.top.mas_equalTo(self.view).offset(kNavBarAndStatusBarHeight);
            make.bottom.mas_equalTo(self.view).offset(-kTabBarHeight);
    }];
}

#pragma mark - Actions

// 长按唤起task编辑页面
- (void)cellGetsLongPressed:(UISwipeGestureRecognizer *)swipeRecognizer
{
    CGPoint touchPoint = [swipeRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    if (indexPath == nil) {
        return;
    }
    TimeTrackerTaskModel *task = self.dataManager.tasks[indexPath.item];
    if (task.isAddTaskModel) {
        // 长按[+]均可以像点击一样唤起add task
        AddTaskViewController *addVC = [AddTaskViewController new];
        addVC.delegate = self;
        [self.navigationController presentViewController:addVC animated:YES completion:nil];
    }
    EditTaskViewController *editVC = [[EditTaskViewController alloc]initWithTasks:self.dataManager.tasks[indexPath.item]];
    editVC.delegate = self;
    [self.navigationController presentViewController:editVC animated:YES completion:nil];
}

# pragma mark - EditTaskProtocol

- (void)updateTasks
{
    [self.collectionView reloadData];
}

- (void)deleteTask:(TimeTrackerTaskModel *)model
{
    [[MirrorStorage sharedInstance] deleteTask:model];
    [self.collectionView reloadData];
}

# pragma mark - AddTaskProtocol

- (void)addNewTask:(TimeTrackerTaskModel *)newTask
{
    [[MirrorStorage sharedInstance] createTask:newTask];
    [self.collectionView reloadData];
}

#pragma mark - TimeTrackingViewProtocol

- (void)closeTimeTrackingView
{
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:TimeTrackingView.class]) {
            [view removeFromSuperview];
        }
    }
    [self p_stopAllTasks];
}

- (void)openTimeTrackingViewWithTask:(TimeTrackerTaskModel *)task
{
    TimeTrackingView *timeTrackingView = [[TimeTrackingView alloc]initWithTask:task];
    timeTrackingView.delegate = self;
    [self.view addSubview:timeTrackingView];
    [timeTrackingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.offset(0);
    }];
}

#pragma mark - Private methods

- (void)p_stopAllTasks
{
    [[MirrorStorage sharedInstance] stopAllTasks];
    [self.collectionView reloadData];
}


# pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)selectedIndexPath
{
    TimeTrackerTaskModel *selectedModel = self.dataManager.tasks[selectedIndexPath.item];
    // 点击了[+]
    if (selectedModel.isAddTaskModel) {
        AddTaskViewController *addVC = [AddTaskViewController new];
        addVC.delegate = self;
        [self.navigationController presentViewController:addVC animated:YES completion:nil];
        return;
    }
    // 点击了task model
    if (selectedModel.isOngoing) { // 点击了正在计时的selectedCell，停止selectedCell的计时
        [[MirrorStorage sharedInstance] stopTask:selectedModel];
        if (self.applyImmersiveMode) {
            [self closeTimeTrackingView];
        }
    } else { // 点击了未开始计时的selectedCell，停止所有其他计时cell，再开始selectedCell的计时
        [self p_stopAllTasks];
        [[MirrorStorage sharedInstance] startTask:selectedModel];
        if (self.applyImmersiveMode) {
            [self openTimeTrackingViewWithTask:selectedModel];
        }
    }
    [self.collectionView reloadData];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TimeTrackerTaskModel *taskModel = self.dataManager.tasks[indexPath.item];
    if (taskModel.isAddTaskModel) {
        TimeTrackerAddTaskCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TimeTrackerAddTaskCollectionViewCell identifier] forIndexPath:indexPath];
        [cell setupAddTaskCell];
        return cell;
    } else {
        TimeTrackerTaskCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TimeTrackerTaskCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configWithModel:taskModel];
        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataManager.tasks.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((kScreenWidth - kCollectionViewPadding - kCollectionViewPadding -kCellSpacing)/2, 90);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kCellSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kCellSpacing;
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        
        [_collectionView registerClass:[TimeTrackerTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerTaskCollectionViewCell identifier]];
        [_collectionView registerClass:[TimeTrackerAddTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerAddTaskCollectionViewCell identifier]];
        
        // 长按手势
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(cellGetsLongPressed:)];
        longPressRecognizer.minimumPressDuration = 0.5;
        [_collectionView addGestureRecognizer:longPressRecognizer];
        
    }
    return _collectionView;
}

- (TimeTrackerDataManager *)dataManager
{
    if (!_dataManager) {
        _dataManager = [[TimeTrackerDataManager alloc]init];
    }
    return _dataManager;
}

@end
