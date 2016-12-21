//
//  AYCalendarViewController.m
//  AYCalendar
//
//  Created by kong on 16/12/21.
//  Copyright © 2016年 konglee. All rights reserved.
//

#import "AYCalendarViewController.h"
#import <EventKit/EventKit.h>
#import "FSCalendar.h"

@interface AYCalendarViewController ()<FSCalendarDataSource,FSCalendarDelegate,FSCalendarDelegateAppearance>

@property (weak, nonatomic) FSCalendar *calendar;

@property (assign, nonatomic) BOOL showsLunar;
@property (assign, nonatomic) BOOL showsEvents;

@property (strong, nonatomic) NSCache *cache;

- (void)todayItemClicked:(id)sender;
- (void)lunarItemClicked:(id)sender;
- (void)eventItemClicked:(id)sender;

@property (strong, nonatomic) NSCalendar *lunarCalendar;
@property (strong, nonatomic) NSCalendar *gregorian;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSDate *minimumDate;
@property (strong, nonatomic) NSDate *maximumDate;

@property (strong, nonatomic) NSArray<NSString *> *lunarChars;
@property (strong, nonatomic) NSArray<EKEvent *> *events;

- (void)loadCalendarEvents;
- (NSArray<EKEvent *> *)eventsForDate:(NSDate *)date;

@end

@implementation AYCalendarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initUI];
}

- (void)initUI
{
    self.title = @"选择出发时间";
    
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    self.minimumDate = [self.dateFormatter dateFromString:@"2016-11-03"];
    self.maximumDate = [self.dateFormatter dateFromString:@"2017-01-01"];
    
//    [self loadCalendarEvents];
    
    FSCalendar *calendar = [[FSCalendar alloc] initWithFrame:CGRectMake(0, 64, KWidth, KHeight - 64)];
    calendar.backgroundColor = [UIColor whiteColor];
    calendar.dataSource = self;
    calendar.delegate = self;
    calendar.pagingEnabled = NO; // important
    calendar.allowsMultipleSelection = YES;
    calendar.firstWeekday = 2;
//    calendar.placeholderType = FSCalendarPlaceholderTypeFillHeadTail;
    calendar.appearance.caseOptions = FSCalendarCaseOptionsWeekdayUsesSingleUpperCase|FSCalendarCaseOptionsHeaderUsesUpperCase;
    calendar.appearance.cellShape = FSCalendarCellShapeRectangle;
    [self.view addSubview:calendar];
    self.calendar = calendar;
    
    _lunarCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
    _lunarCalendar.locale = [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
    _lunarChars = @[@"初一",@"初二",@"初三",@"初四",@"初五",@"初六",@"初七",@"初八",@"初九",@"初十",@"十一",@"十二",@"十三",@"十四",@"十五",@"十六",@"十七",@"十八",@"十九",@"二十",@"二一",@"二二",@"二三",@"二四",@"二五",@"二六",@"二七",@"二八",@"二九",@"三十"];
    _showsLunar = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
     
}

#pragma mark - Target actions

- (void)todayItemClicked:(id)sender
{
    [self.calendar setCurrentPage:[NSDate date] animated:YES];
}

- (void)lunarItemClicked:(UIBarButtonItem *)item
{
    self.showsLunar = !self.showsLunar;
    [self.calendar reloadData];
}

- (void)eventItemClicked:(id)sender
{
    self.showsEvents = !self.showsEvents;
    [self.calendar reloadData];
}

#pragma mark - FSCalendarDataSource

- (NSDate *)minimumDateForCalendar:(FSCalendar *)calendar
{
    return self.minimumDate;
}

- (NSDate *)maximumDateForCalendar:(FSCalendar *)calendar
{
    return self.maximumDate;
}

- (NSString *)calendar:(FSCalendar *)calendar subtitleForDate:(NSDate *)date
{
    NSLog(@"date is %@",date);
   
    if (_showsLunar) {
        NSInteger day = [_lunarCalendar component:NSCalendarUnitDay fromDate:date];
        return _lunarChars[day-1];
    }
    return nil;
}

#pragma mark - FSCalendarDelegate

//- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
//{
//    NSLog(@"did select %@",[self.dateFormatter stringFromDate:date]);
//}

- (void)calendarCurrentPageDidChange:(FSCalendar *)calendar
{
    NSLog(@"did change page %@",[self.dateFormatter stringFromDate:calendar.currentPage]);
}

- (NSInteger)calendar:(FSCalendar *)calendar numberOfEventsForDate:(NSDate *)date
{
    if (!self.showsEvents) return 0;
    if (!self.events) return 0;
    NSArray<EKEvent *> *events = [self eventsForDate:date];
    return events.count;
}

- (NSArray<UIColor *> *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventDefaultColorsForDate:(NSDate *)date
{
    if (!self.showsEvents) return nil;
    if (!self.events) return nil;
    NSArray<EKEvent *> *events = [self eventsForDate:date];
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(EKEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [colors addObject:[UIColor colorWithCGColor:obj.calendar.CGColor]];
    }];
    return colors.copy;
}

#pragma mark - Private methods

- (void)loadCalendarEvents
{
    __weak typeof(self) weakSelf = self;
    EKEventStore *store = [[EKEventStore alloc] init];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        
        if(granted) {
            NSDate *startDate = self.minimumDate;
            NSDate *endDate = self.maximumDate;
            NSPredicate *fetchCalendarEvents = [store predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil];
            NSArray<EKEvent *> *eventList = [store eventsMatchingPredicate:fetchCalendarEvents];
            NSArray<EKEvent *> *events = [eventList filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(EKEvent * _Nullable event, NSDictionary<NSString *,id> * _Nullable bindings) {
                return event.calendar.subscribed;
            }]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!weakSelf) return;
                weakSelf.events = events;
                [weakSelf.calendar reloadData];
            });
            
        } else {
            
            // Alert
            UIAlertController *alertController = [[UIAlertController alloc] init];
            alertController.title = @"Error";
            alertController.message = @"Permission of calendar is required for fetching events.";
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            
        }
    }];
    
}

- (NSArray<EKEvent *> *)eventsForDate:(NSDate *)date
{
    NSArray<EKEvent *> *events = [self.cache objectForKey:date];
    if ([events isKindOfClass:[NSNull class]]) {
        return nil;
    }
    NSArray<EKEvent *> *filteredEvents = [self.events filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(EKEvent * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject.occurrenceDate isEqualToDate:date];
    }]];
    if (filteredEvents.count) {
        [self.cache setObject:filteredEvents forKey:date];
    } else {
        [self.cache setObject:[NSNull null] forKey:date];
    }
    return filteredEvents;
}





@end
