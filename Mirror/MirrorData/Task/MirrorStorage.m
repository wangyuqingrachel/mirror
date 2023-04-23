//
//  MirrorStorage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/10/24.
//

#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorTool.h"
#import "MirrorMacro.h"

static NSString *const kMirrorDict = @"mirror_dict";

@implementation MirrorStorage

#pragma mark - Public

+ (void)createTask:(MirrorDataModel *)task
{
    // 在本地取出mirror dict
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 新增一个task
    [mirrorDict setValue:task forKey:task.taskName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][task.taskName] info:@"Create"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskCreateNotification object:nil userInfo:nil];
}

+ (void)deleteTask:(NSString *)taskName
{
    // 在本地取出词典
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 通过taskname删除task
    [mirrorDict removeObjectForKey:taskName];
    // 将mirror dict存回本地
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Delete"];
    [MirrorStorage saveMirrorData:mirrorDict];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskDeleteNotification object:nil userInfo:nil];
}

+ (void)archiveTask:(NSString *)taskName
{
    [MirrorStorage stopTask:taskName at:[NSDate now] periodIndex:0];
    // 在本地取出task
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task以便作修改
    MirrorDataModel *task = mirrorDict[taskName];
    // stop task first
    // 更新task的archive状态
    task.isArchived = YES;
    // 保存更新好的task到本地
    [mirrorDict setValue:task forKey:taskName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Archive"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskArchiveNotification object:nil userInfo:nil];
}

+ (void)editTask:(NSString *)oldName color:(MirrorColorType)newColor name:(NSString *)newName
{
    // 在本地取出task
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task以便作修改
    MirrorDataModel *task = mirrorDict[oldName];
    // 更新task的color和taskname
    [mirrorDict removeObjectForKey:oldName];
    task.color = newColor;
    task.taskName = newName;
    // 保存更新好的task到本地
    [mirrorDict setValue:task forKey:newName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][newName] info:@"Edit"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskEditNotification object:nil userInfo:nil];
}

// 如果是计时，accurateDate为[NSDate now]，periodIndex为0
+ (void)startTask:(NSString *)taskName at:(NSDate *)accurateDate periodIndex:(NSInteger)index
{
    NSDate *date = [self dateWithoutSeconds:accurateDate];
    // 在本地取出task
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task以便作修改
    MirrorDataModel *task = mirrorDict[taskName];
    // 给task创建一个新的period，并给出这个period的起始时间
    NSMutableArray *allPeriods = [[NSMutableArray alloc] initWithArray:task.periods];
    NSMutableArray *newPeriod = [[NSMutableArray alloc] initWithArray:@[@(round([date timeIntervalSince1970]))]];
    [allPeriods insertObject:newPeriod atIndex:index];
    task.periods = allPeriods;
    // 保存更新好的task到本地
    [mirrorDict setValue:task forKey:taskName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Start"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStartNotification object:nil userInfo:nil];
}

// 如果是计时，accurateDate为[NSDate now]，periodIndex为0
+ (void)stopTask:(NSString *)taskName at:(NSDate *)accurateDate periodIndex:(NSInteger)index
{
    NSDate *date = [self dateWithoutSeconds:accurateDate];
    TaskSavedType savedType = TaskSavedTypeNone;
    // 在本地取出mirror dict
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task以便作修改
    MirrorDataModel *task = mirrorDict[taskName];
    // 将最后一个period取出来，给它一个结束时间
    NSMutableArray *allPeriods = [[NSMutableArray alloc] initWithArray:task.periods];
    if (allPeriods.count > index) {
        NSMutableArray *latestPeriod = [[NSMutableArray alloc] initWithArray:allPeriods[index]];
        long start = [latestPeriod[0] longValue];
        long end = [date timeIntervalSince1970];
        long length = end - start;
        NSLog(@"%@计时结束 %ld",[UIColor getEmoji:task.color], length);
        if (latestPeriod.count == 1 &&  length >= kMinSeconds) { // 一分钟以上开始记录（在00:00处切割）
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:start];
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:end];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *startComponents = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:startDate];
            NSDateComponents *endComponents = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:endDate];
            startComponents.timeZone = [NSTimeZone systemTimeZone];
            endComponents.timeZone = [NSTimeZone systemTimeZone];
            
            if (startComponents.year == endComponents.year && startComponents.month == endComponents.month && startComponents.day == endComponents.day) { // 开始和结束在同一天，直接记录 (存在原处)
                [latestPeriod addObject:@(round([date timeIntervalSince1970]))];
                allPeriods[index] = latestPeriod;
                savedType = TaskSavedTypeSaved;
            } else { //开始和结束不在同一天，在00:00处切割分段
                NSDateComponents *endComponent0 = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:startDate];
                endComponent0.hour = 23;
                endComponent0.minute = 59;
                long endTime0 = [[gregorian dateFromComponents:endComponent0] timeIntervalSince1970];
                [latestPeriod addObject:@(round(endTime0))];  // 第一个分段 (存在原处)
                allPeriods[index] = latestPeriod;
                long startTimei = endTime0 + 1;
                long endTimei = startTimei + 86400 -1;
                while (endTimei < end) {
                    NSArray *newPeriod = @[@(startTimei), @(endTimei)]; // 第i个分段（新插入）
                    [allPeriods insertObject:newPeriod atIndex:index];
                    startTimei = startTimei + 86400;
                    endTimei = startTimei + 86400 -1;
                }
                NSArray *newPeriod = @[@(startTimei), @(endTimei)]; // 最后一个分段（新插入）
                [allPeriods insertObject:newPeriod atIndex:index];
            }
        } else { // 错误格式或者n秒以下，丢弃这个task
            [allPeriods removeObjectAtIndex:0];
            savedType = (length < kMinSeconds && length >= 0) ? TaskSavedTypeTooShort : TaskSavedTypeError;
        }
        task.periods = allPeriods;
    }
    // 保存更新好的task到本地
    [mirrorDict setValue:task forKey:taskName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Stop"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStopNotification object:nil userInfo:@{@"taskName":taskName, @"TaskSavedType" : @(savedType)}];
}

+ (void)stopAllTasksExcept:(NSString *)exceptTaskName
{
    // 在本地取出mirror dict
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 大循环
    for (id taskName in mirrorDict.allKeys) {
        // 取出这个task以便作修改
        MirrorDataModel *task = mirrorDict[taskName];
        if ([task.taskName isEqualToString:exceptTaskName]) { // 被点击的task不要动
            continue;
        }
        if (!task.isOngoing) { // 不在计时中的task不要动
            continue;
        }
        [MirrorStorage stopTask:taskName at:[NSDate now] periodIndex:0];
    }
}

+ (TaskNameExistsType)taskNameExists:(NSString *)newTaskName
{
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    for (id taskName in mirrorDict.allKeys) {
        if ([taskName isEqualToString:newTaskName]) {
            MirrorDataModel *task = mirrorDict[taskName];
            if (task.isArchived) {
                return TaskNameExistsTypeExistsInArchivedTasks;
            } else {
                return TaskNameExistsTypeExistsInCurrentTasks;
            }
        }
    }
    return TaskNameExistsTypeValid;
}

+ (void)deletePeriodWithTaskname:(NSString *)taskName periodIndex:(NSInteger)index
{
    // 在本地取出mirror dict
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task以便作修改
    MirrorDataModel *task = mirrorDict[taskName];
    [task.periods removeObjectAtIndex:index];
    // 保存更新好的task到本地
    [mirrorDict setValue:task forKey:taskName];
    // 将mirror dict存回本地
    [MirrorStorage saveMirrorData:mirrorDict];
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Period is deleted"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodDeleteNotification object:nil userInfo:nil];
}

+ (void)editPeriodIsStartTime:(BOOL)isStartTime to:(long)timestamp withTaskname:(NSString *)taskName periodIndex:(NSInteger)index
{
    // 在本地取出mirror dict
    NSMutableDictionary *mirrorDict = [MirrorStorage retriveMirrorData];
    // 取出这个task，直接使用start/stop task进行修改。
    MirrorDataModel *task = mirrorDict[taskName];
    [MirrorStorage deletePeriodWithTaskname:taskName periodIndex:index];
    long oldStartTime = [task.periods[index][0] longValue];
    long oldEndTime = [task.periods[index][1] longValue];
    if (isStartTime) {
        [MirrorStorage startTask:taskName at:[NSDate dateWithTimeIntervalSince1970:timestamp] periodIndex:index];
        [MirrorStorage stopTask:taskName at:[NSDate dateWithTimeIntervalSince1970:oldEndTime] periodIndex:index];
    } else {
        [MirrorStorage startTask:taskName at:[NSDate dateWithTimeIntervalSince1970:oldStartTime] periodIndex:index];
        [MirrorStorage stopTask:taskName at:[NSDate dateWithTimeIntervalSince1970:timestamp] periodIndex:index];
    }
    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][taskName] info:@"Period is edited"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodEditNotification object:nil userInfo:nil];
}



+ (MirrorDataModel *)getTaskFromDB:(NSString *)taskName
{
    NSMutableDictionary *tasks = [MirrorStorage retriveMirrorData];
    MirrorDataModel *task = tasks[taskName];
//    [MirrorStorage printTask:[MirrorStorage retriveMirrorData][task.taskName] info:@"-------Getting one task-------"];
    return task;
}

+ (MirrorDataModel *)getOngoingTaskFromDB
{
    NSMutableDictionary *tasks = [MirrorStorage retriveMirrorData];
    for (id taskName in tasks.allKeys) {
        MirrorDataModel *task = tasks[taskName];
        if (task.isOngoing) {
//            [MirrorStorage printTask:[MirrorStorage retriveMirrorData][task.taskName] info:@"-------Getting ongoing task-------"];
            return task;
        }
    }
    return nil;
}

#pragma mark - Local database

+ (void)saveMirrorData:(NSMutableDictionary *)mirrorDict // 归档
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mirrorDict requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setValue:data forKey:kMirrorDict];
}

+ (NSMutableDictionary *)retriveMirrorData // 解档
{
    NSData *storedEncodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:kMirrorDict];
    NSMutableDictionary *mirrorDict = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[MirrorDataModel.class,NSMutableDictionary.class, NSMutableArray.class]] fromData:storedEncodedObject error:nil];
    return mirrorDict ?: [NSMutableDictionary new];
}

+ (void)_printTime:(long)timeStamp info:(NSString *)info
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long week = (long)components.weekday;
    long day = (long)components.day;
    long hour = (long)components.hour;
    long minute = (long)components.minute;
    long second = (long)components.second;
    // print
    NSLog(@"%@: %ld年%ld月%ld日，一周的第%ld天，%ld:%ld:%ld，时间戳为%ld，与此时此刻的时间差为%ld",info, year, month, day, week, hour, minute, second, (long)[date timeIntervalSince1970], (long)[[NSDate now] timeIntervalSince1970] - (long)[date timeIntervalSince1970]);
}

#pragma mark - Log

+ (void)printTask:(MirrorDataModel *)task info:(NSString *)info
{
    if (!task) NSLog(@"❗️❗️❗️❗️❗️❗️❗️❗️ACTION FAILED❗️❗️❗️❗️❗️❗️❗️❗️");
    if (info) NSLog(@"%@%@", info, [UIColor getLongEmoji:task.color]);
    
    BOOL printTimestamp = NO; // 是否打印时间戳（平时不需要打印，出错debug的时候打印一下）
    NSString *tag = @"";
    tag = [tag stringByAppendingString:task.isArchived ? @"[":@" "];
    tag = [tag stringByAppendingString:[UIColor getEmoji:task.color]];
    tag = [tag stringByAppendingString:task.isArchived ? @"]":@" "];
    NSLog(@"%@%@, Created at %@",tag, task.taskName,  [MirrorTool timeFromTimestamp:task.createdTime printTimeStamp:printTimestamp]);
    for (int i=0; i<task.periods.count; i++) {
        if (task.periods[i].count == 1) {
            NSLog(@"[%@, ..........] 计时中..., ", [MirrorTool timeFromTimestamp:[task.periods[i][0] longValue] printTimeStamp:printTimestamp]);
        }
        if (task.periods[i].count == 2) {
            NSLog(@"[%@, %@] Lasted:%@, ",
                  [MirrorTool timeFromTimestamp:[task.periods[i][0] longValue] printTimeStamp:printTimestamp],
                  [MirrorTool timeFromTimestamp:[task.periods[i][1] longValue] printTimeStamp:printTimestamp],
                  [[NSDateComponentsFormatter new] stringFromTimeInterval:[task.periods[i][1] longValue]-[task.periods[i][0] longValue]]);
        }
    }
    
}

#pragma mark - Privates

+ (NSDate *)dateWithoutSeconds:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.second = 0;
    NSDate *dateWithoutSeconds = [gregorian dateFromComponents:components];
    return dateWithoutSeconds;
}
@end
