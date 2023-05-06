//
//  TaskRecordsViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/15.
//

#import "TaskRecordsViewController.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"
#import "TaskPeriodCollectionViewCell.h"
#import "MirrorStorage.h"
#import "TaskTotalHeader.h"
#import "MirrorLanguage.h"
#import "MirrorNaviManager.h"

static CGFloat const kCellSpacing = 20; // cell之间的上下间距

@interface TaskRecordsViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VCForPeriodCellProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSString *taskName;

@end

@implementation TaskRecordsViewController

- (instancetype)initWithTaskname:(NSString *)taskName
{
    self = [super init];
    if (self) {
        self.taskName = taskName;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitleAndArchive) name:MirrorTaskArchiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateTitle];
}

- (void)updateTitleAndArchive
{
    [self updateTitle];
    [self updateArchive];
}

- (void)updateTitle
{
    NSString *title = self.taskName;
    if ([MirrorStorage getTaskModelFromDB:self.taskName].isArchived) {
        title = [[MirrorLanguage mirror_stringWithKey:@"archived_tag"] stringByAppendingString:title];
    }
    [[MirrorNaviManager sharedInstance] updateNaviItemWithNaviController:self.navigationController title:title leftButton:nil rightButton:nil];
}

- (void)updateArchive
{
    if ([MirrorStorage getTaskModelFromDB:self.taskName].isArchived) {
        UIImage *image = [[UIImage systemImageNamed:@"archivebox.fill"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIBarButtonItem *cancelArchiveItem = [[UIBarButtonItem alloc]  initWithImage:imageWithRightColor style:UIBarButtonItemStylePlain target:self action:@selector(cancelArchive)];
        cancelArchiveItem.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [self.navigationItem setRightBarButtonItem:cancelArchiveItem];
    } else {
        UIImage *image = [[UIImage systemImageNamed:@"archivebox"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIBarButtonItem *archiveItem = [[UIBarButtonItem alloc]  initWithImage:imageWithRightColor style:UIBarButtonItemStylePlain target:self action:@selector(archive)];
        archiveItem.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [self.navigationItem setRightBarButtonItem:archiveItem];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI
{
    // navibar
    [self updateArchive];
    // collection view
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCellSpacing);
        make.right.mas_equalTo(self.view).offset(-kCellSpacing);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view);
    }];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [MirrorStorage getAllTaskRecords:self.taskName].count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TaskPeriodCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TaskPeriodCollectionViewCell identifier] forIndexPath:indexPath];
    [cell configWithTaskname:self.taskName periodIndex:[MirrorStorage getAllTaskRecords:self.taskName][indexPath.item].originalIndex];
    cell.delegate = self;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kScreenWidth - 2*kCellSpacing, 80);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *header;
    if (kind == UICollectionElementKindSectionHeader) {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        TaskTotalHeader* taskHeader = (TaskTotalHeader *)header;
        [taskHeader configWithTaskname:self.taskName];
        
    }
    return header;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(kScreenWidth, 40);
}

#pragma mark - Actions

- (void)cancelArchive
{
    [MirrorStorage cancelArchiveTask:self.taskName];
}

- (void)archive
{
    [MirrorStorage archiveTask:self.taskName];
}


#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 10;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        
        [_collectionView registerClass:[TaskPeriodCollectionViewCell class] forCellWithReuseIdentifier:[TaskPeriodCollectionViewCell identifier]];
        [_collectionView registerClass:[TaskTotalHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    }
    return _collectionView;
}


@end
