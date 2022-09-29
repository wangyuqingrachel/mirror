//
//  MirrorLanguage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import "MirrorLanguage.h"

static MirrorLanguageType _languageType = MirrorLanguageTypeEnglish;

@implementation MirrorLanguage

+ (void)switchLanguage
{
    if (_languageType == MirrorLanguageTypeEnglish) {
        _languageType = MirrorLanguageTypeChinese;
    } else {
        _languageType = MirrorLanguageTypeEnglish;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MirrorSwitchLanguageNotification" object:nil];
}

+ (NSString *)mirror_stringWithKey:(NSString *)key
{
    NSMutableDictionary *mirrorDict = [NSMutableDictionary new];
    // tabs
    [mirrorDict setValue:@[@"Me", @"我的"] forKey:@"me"];
    [mirrorDict setValue:@[@"Start", @"冲鸭"] forKey:@"start"];
    [mirrorDict setValue:@[@"Data", @"数据"] forKey:@"data"];
    // time tracker cell
    [mirrorDict setValue:@[@"Tap to start", @"点击开始"] forKey:@"tap_to_start"];
    // nickname
    [mirrorDict setValue:@[@"nickname", @"你的昵称"] forKey:@"nickname"];
    
    return [mirrorDict valueForKey:key][_languageType];
}



@end
