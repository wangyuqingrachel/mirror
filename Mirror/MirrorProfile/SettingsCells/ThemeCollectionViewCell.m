//
//  ThemeCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/28.
//

#import "ThemeCollectionViewCell.h"
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"

static MirrorColorType const themeColorType = MirrorColorTypeCellPink;

@implementation ThemeCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCell
{
    [super configCellWithTitle:@"apply_darkmode" color:themeColorType];
    [self.toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if ([MirrorSettings appliedDarkMode]) {
        [self.toggle setOn:YES animated:YES];
    } else {
        [self.toggle setOn:NO animated:YES];
    }
}

- (void)switchChanged:(UISwitch *)sender {
    [MirrorSettings switchTheme];
}
    

@end