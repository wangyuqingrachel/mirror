//
//  SettingsViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "SettingsViewController.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"

#import "AvatarCollectionViewCell.h"
#import "ThemeCollectionViewCell.h"
#import "LanguageCollectionViewCell.h"
#import "ImmersiveCollectionViewCell.h"
#import "WeekStartsOnCollectionViewCell.h"
#import "MirrorTabsManager.h"
#import "MirrorLanguage.h"
#import "SettingsAnimation.h"

static CGFloat const kCellSpacing = 20; // cell之间的上下间距
static CGFloat const kCollectionViewPadding = 20; // 左右留白

typedef NS_ENUM(NSInteger, MirrorSettingType) {
    MirrorSettingTypeAvatar,
    MirrorSettingTypeTheme,
    MirrorSettingTypeLanguage,
    MirrorSettingTypeImmersive,
    MirrorSettingTypeWeekStartsOn,
};

@interface SettingsViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation SettingsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)restartVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.collectionView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self  p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    // 手势
    [super viewDidAppear:animated];
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    tapRecognizer.delegate = self;
    [self.view.superview addGestureRecognizer:tapRecognizer];
    
    UIPanGestureRecognizer *panRecognizer = [UIPanGestureRecognizer new];
    panRecognizer.delegate = self;
    [self.view.superview addGestureRecognizer:panRecognizer];
    
    // 动画
    self.transitioningDelegate = self;
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view).offset(-kTabBarHeight);
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class]) {
        CGPoint touchPoint = [touch locationInView:self.view];
        if (touchPoint.x <= self.view.frame.size.width) {
            // 点了view里面
        } else {
            [self dismiss];// 点了view外面
        }
    }
    if ([gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:gestureRecognizer.view];
        if (translation.x < 0) {
            [self dismiss];// 向左滑
        } else {
            // 向右滑
        }
    }
    
    return NO;
}


# pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.dataSource.count) {
        return;
    } else if (indexPath.item == MirrorSettingTypeAvatar) {
        // glick avatar cell
    } else if (indexPath.item == MirrorSettingTypeTheme) {
        // Do nothing (use toggle to switch theme)
    } else if (indexPath.item == MirrorSettingTypeLanguage) {
        // Do nothing (use toggle to switch language)
    } else if (indexPath.item == MirrorSettingTypeImmersive) {
        // Do nothing (use toggle to switch language)
    } else if (indexPath.item == MirrorSettingTypeWeekStartsOn) {
        // Do nothing (use toggle to switch weekStartsOn)
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.dataSource.count) {
        return [UICollectionViewCell new];
    } else if (indexPath.item == MirrorSettingTypeAvatar) {
        AvatarCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[AvatarCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeTheme){
        ThemeCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ThemeCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeLanguage) {
        LanguageCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[LanguageCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeImmersive) {
        ImmersiveCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ImmersiveCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeWeekStartsOn) {
        WeekStartsOnCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[WeekStartsOnCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    }
    
    return [UICollectionViewCell new];
   
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.item) {
        case MirrorSettingTypeAvatar:
            return CGSizeMake(collectionView.frame.size.width, 140*kLeftSheetRatio);
        case MirrorSettingTypeTheme:
            return CGSizeMake(collectionView.frame.size.width, 52*kLeftSheetRatio);
        case MirrorSettingTypeLanguage:
            return CGSizeMake(collectionView.frame.size.width, 52*kLeftSheetRatio);
        case MirrorSettingTypeImmersive:
            return CGSizeMake(collectionView.frame.size.width, 52*kLeftSheetRatio);
        case MirrorSettingTypeWeekStartsOn:
            return CGSizeMake(collectionView.frame.size.width, 52*kLeftSheetRatio);
        default:
            break;
    }
    return CGSizeMake(collectionView.frame.size.width, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
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
        [_collectionView registerClass:[AvatarCollectionViewCell class] forCellWithReuseIdentifier:[AvatarCollectionViewCell identifier]];
        [_collectionView registerClass:[ThemeCollectionViewCell class] forCellWithReuseIdentifier:[ThemeCollectionViewCell identifier]];
        [_collectionView registerClass:[LanguageCollectionViewCell class] forCellWithReuseIdentifier:[LanguageCollectionViewCell identifier]];
        [_collectionView registerClass:[ImmersiveCollectionViewCell class] forCellWithReuseIdentifier:[ImmersiveCollectionViewCell identifier]];
        [_collectionView registerClass:[WeekStartsOnCollectionViewCell class] forCellWithReuseIdentifier:[WeekStartsOnCollectionViewCell identifier]];
        
    }
    return _collectionView;
}

- (NSArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = @[@(MirrorSettingTypeAvatar), @(MirrorSettingTypeTheme), @(MirrorSettingTypeLanguage), @(MirrorSettingTypeImmersive), @(MirrorSettingTypeWeekStartsOn)];
    }
    return _dataSource;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    SettingsAnimation *animation = [SettingsAnimation new];
    animation.isPresent = NO;
    return animation;
}


@end