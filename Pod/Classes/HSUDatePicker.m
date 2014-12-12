//
//  DatePicker.m
//  DatePicker
//
//  Created by Jason Hsu on 13-9-17.
//  Copyright (c) 2013年 Jason Hsu. All rights reserved.
//

#import "HSUDatePicker.h"

#define TextFont 16
#define HSUDatePickerSelectAction @"HSUDatePickerSelectAction"

@interface HSUDatePickerViewController : UICollectionViewController

@property (nonatomic, strong) UIColor *todayColor;
@property (nonatomic, strong) UIColor *touchColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;
@property (nonatomic, assign) BOOL allowPastDateSelection;

@property (nonatomic, assign) NSInteger startYear;
@property (nonatomic, assign) NSInteger endYear;

@property (nonatomic, strong) NSDateComponents *selectedDateComponents;
@property (nonatomic, strong) NSDateComponents *startSelectDateComponents;

@end

@interface HSUDateCollectionViewCell : UICollectionViewCell

@property (nonatomic, readwrite) NSDate *date;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *disabledColor;

@end

@interface HSUDateCollectionViewHeader : UICollectionReusableView
{
    NSInteger _month;
}

@property (nonatomic, readwrite) NSInteger month;
@property (nonatomic, assign) NSInteger firstWeekDay;
@property (nonatomic, strong) UIColor *tintColor;

@end

@interface HSUDatePicker ()

@property (nonatomic, strong) NSDate *startSelectedDate;

@end

@implementation HSUDatePicker

- (id)initWithStartYear:(NSInteger)startYear endYear:(NSInteger)endYear
{
    self = [super init];
    if (self) {
        NSAssert(startYear > 1582, @"startYear should later than 1582");
        self.startYear = startYear;
        self.endYear = endYear;
        
        self.todayColor = [UIColor redColor];
        self.touchColor = [UIColor lightGrayColor];
        self.selectedColor = [UIColor blackColor];
        self.allowPastDateSelection = YES;

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(selectDate:)
         name:HSUDatePickerSelectAction
         object:nil];
    }
    return self;
}

- (id)initFromCurrentYearWithYears:(NSInteger)years
{
    NSDateComponents *coms = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    return [self initWithStartYear:coms.year endYear:coms.year+years];
}

- (void)viewDidLoad
{
    HSUDatePickerViewController *datePickerVC = [[HSUDatePickerViewController alloc]
                                                 initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    datePickerVC.todayColor = self.todayColor;
    datePickerVC.touchColor = self.touchColor;
    datePickerVC.selectedColor = self.selectedColor;
    datePickerVC.disabledColor = self.disabledColor;
    datePickerVC.allowPastDateSelection = self.allowPastDateSelection;
    
    datePickerVC.startYear = self.startYear;
    datePickerVC.endYear = self.endYear;
    self.viewControllers = @[datePickerVC];

    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(cancel)];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)selectDate:(NSNotification *)notification
{
    UIGestureRecognizerState state = [notification.userInfo[@"state"] intValue];
    if (state == UIGestureRecognizerStateBegan) { // start select
        NSDate *date = notification.userInfo[@"date"];
        self.startSelectedDate = date;
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:-1 fromDate:self.startSelectedDate];
        HSUDatePickerViewController *datePickerVC = (HSUDatePickerViewController *)self.viewControllers[0];
        datePickerVC.startSelectDateComponents = dateComponents;
#ifdef __IPHONE_7_0
        [datePickerVC.collectionView reloadData];
#endif
    } else if (state == UIGestureRecognizerStateEnded) {
        self.selectedDate = self.startSelectedDate;
        self.selectedDateComponents = [[NSCalendar currentCalendar] components:-1 fromDate:self.selectedDate];
        HSUDatePickerViewController *datePickerVC = (HSUDatePickerViewController *)self.viewControllers[0];
        datePickerVC.startSelectDateComponents = nil;
        datePickerVC.selectedDateComponents = self.selectedDateComponents;
        [datePickerVC.collectionView reloadData];
        if (self.allowPastDateSelection || ![self dateInPast:self.selectedDate]) {
          [self.delegate datePicker:self didSelectDate:self.selectedDate];
        }
    } else if (state == UIGestureRecognizerStateCancelled) {
        HSUDatePickerViewController *datePickerVC = (HSUDatePickerViewController *)self.viewControllers[0];
        datePickerVC.startSelectDateComponents = nil;
        [datePickerVC.collectionView reloadData];
    }
}

- (void)cancel
{
    [self.delegate datePickerDidCancelSelect:self];
}

- (BOOL)dateInPast:(NSDate *)date {
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

  NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                 fromDate:[NSDate date]];
  [dateComponents setHour:0];
  [dateComponents setMinute:0];
  [dateComponents setSecond:0];

  NSDate *midnightUTC = [calendar dateFromComponents:dateComponents];

  NSComparisonResult result = [midnightUTC compare:date];
  switch (result)
  {
    case NSOrderedDescending:
      return YES;
      break;
    default:
      return NO;
  }
}

@end

@implementation HSUDateCollectionViewCell
{
    NSDate *_date;
}

- (void)dealloc
{
    _date = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.date) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:HSUDatePickerSelectAction
         object:nil
         userInfo:@{@"date": self.date, @"state": @(UIGestureRecognizerStateBegan)}];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:HSUDatePickerSelectAction
     object:nil
     userInfo:@{@"state": @(UIGestureRecognizerStateCancelled)}];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:HSUDatePickerSelectAction
     object:nil
     userInfo:@{@"state": @(UIGestureRecognizerStateEnded)}];
}

- (NSDate *)date
{
    return _date;
}

- (void)setDate:(NSDate *)date
{
    _date = date;
    
    [self setNeedsDisplay];
}

- (void)setDisabledColor:(UIColor *)disabledColor
{
  _disabledColor = disabledColor;

  [self setNeedsDisplay];
}

- (void)prepareForReuse {
  [super prepareForReuse];

  self.disabledColor = nil;
  self.tintColor = nil;
  self.date = nil;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, rect);
    
    if (self.date) {
        CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
        CGPoint *points = malloc(2 * sizeof(CGPoint));
        points[0] = CGPointMake(0, 0);
        points[1] = CGPointMake(rect.size.width, 0);
        CGContextStrokeLineSegments(context, points, 2);
        free(points);
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitWeekday
                                                                       fromDate:self.date];
        NSString *text = [NSString stringWithFormat:@"%ld", (long)components.day];
        UIFont *font = [UIFont systemFontOfSize:TextFont];
        if (self.tintColor) {
            font = [UIFont boldSystemFontOfSize:TextFont+2];
            CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(6, 4, rect.size.width-12, rect.size.width-12));
#ifdef __IPHONE_7_0
            NSDictionary *attr = @{NSFontAttributeName: font,
                                   NSForegroundColorAttributeName: [UIColor whiteColor]};
            CGSize textSize = [text sizeWithAttributes:attr];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 9) withAttributes:attr];
#else
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGSize textSize = [text sizeWithFont:font];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 9) withFont:font];
#endif
        } else if (components.weekday == 1 || components.weekday == 7) {
#ifdef __IPHONE_7_0
            NSDictionary *attr = @{NSFontAttributeName: font,
                                   NSForegroundColorAttributeName: [self holydaysTextColor]};
            CGSize textSize = [text sizeWithAttributes:attr];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 10) withAttributes:attr];
#else
            CGContextSetFillColorWithColor(context, [self holydaysTextColor].CGColor);
            CGSize textSize = [text sizeWithFont:font];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 10) withFont:font];
#endif
        } else {
#ifdef __IPHONE_7_0
            NSDictionary *attr = @{NSFontAttributeName: font,
                                   NSForegroundColorAttributeName: [self normalTextColor]};
            CGSize textSize = [text sizeWithAttributes:attr];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 10) withAttributes:attr];
#else
            CGContextSetFillColorWithColor(context, [self normalTextColor].CGColor);
            CGSize textSize = [text sizeWithFont:font];
            [text drawAtPoint:CGPointMake(rect.size.width/2-textSize.width/2, 10) withFont:font];
#endif
        }
    }
}

- (UIColor *)normalTextColor {
  if (self.disabledColor) {
    return self.disabledColor;
  } else {
    return [UIColor blackColor];
  }
}

- (UIColor *)holydaysTextColor {
  if (self.disabledColor) {
    return self.disabledColor;
  } else {
    return [UIColor grayColor];
  }
}

@end

@implementation HSUDateCollectionViewHeader

- (NSInteger)month
{
    return _month;
}

- (void)setMonth:(NSInteger)month
{
    _month = month;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, rect);
    
    NSString *text = [self localMonth:self.month];
    UIFont *font = [UIFont systemFontOfSize:TextFont];
#ifdef __IPHONE_7_0
    NSDictionary *attr = @{NSFontAttributeName: font,
                           NSForegroundColorAttributeName: self.tintColor ?: [UIColor blackColor]};
    CGSize textSize = [text sizeWithAttributes:attr];
    CGPoint textPoint = CGPointMake(self.firstWeekDay * rect.size.width / 7 + (rect.size.width/7/2 - textSize.width/2) ,
                                    rect.size.height/2-textSize.height/2);
    [text drawAtPoint:textPoint withAttributes:attr];
#else
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGSize textSize = [text sizeWithFont:font];
    CGPoint textPoint = CGPointMake(self.firstWeekDay * rect.size.width / 7 + (rect.size.width/7/2 - textSize.width/2) ,
                                    rect.size.height/2-textSize.height/2);
    [text drawAtPoint:textPoint withFont:font];
#endif
}

- (NSString *)localMonth:(NSInteger)month
{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"MMM"];
    NSDate *date = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:date];
    components.month = month;
    date = [[NSCalendar currentCalendar] dateFromComponents:components];
    return [fmt stringFromDate:date];
}

@end


@interface HSUDatePickerViewController()

@property (nonatomic, strong) NSDateComponents *today;
@property (nonatomic, strong) NSMutableArray *weekdayLabels;

@end

@implementation HSUDatePickerViewController

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[HSUDateCollectionViewCell class]
            forCellWithReuseIdentifier:@"HSUDateCollectionViewCell"];
    [self.collectionView registerClass:[HSUDateCollectionViewHeader class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"Header"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.scrollsToTop = NO;
    
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:[NSDate date]];
    self.today = components;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.weekdayLabels = [NSMutableArray array];
    for (int i=0; i<7; i++) {
        NSString *text = [self localWeekday:i+1];
        UILabel *weekdayLabel = [[UILabel alloc] init];
        [self.weekdayLabels addObject:weekdayLabel];
        weekdayLabel.textAlignment = NSTextAlignmentCenter;
        weekdayLabel.font = [UIFont systemFontOfSize:10];
        weekdayLabel.textColor = i == 0 || i == 6 ? [UIColor grayColor] : [UIColor blackColor];
        weekdayLabel.text = text;
        [weekdayLabel sizeToFit];
        [self.view addSubview:weekdayLabel];
        weekdayLabel.backgroundColor = [UIColor whiteColor];
        weekdayLabel.frame = CGRectMake(i * self.view.bounds.size.width / 7,
#ifdef __IPHONE_7_0
                                        64,
#else
                                        0,
#endif
                                        self.view.frame.size.width / 7,
                                        20);
        weekdayLabel.alpha = 0;
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self.weekdayLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setAlpha:1];
        }];
    }];
    
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x,
                                           self.collectionView.frame.origin.y+20,
                                           self.collectionView.frame.size.width,
                                           self.collectionView.frame.size.height-20);
    
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self.navigationController
                                                 action:@selector(cancel)];
    }
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_7_0
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
#endif
    self.navigationController.navigationBar.opaque = YES;
    
    NSUInteger section = (self.today.year - self.startYear) * 12 + self.today.month - 1;
    NSUInteger item = self.today.day;
    NSIndexPath *todayIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView scrollToItemAtIndexPath:todayIndexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:NO];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.weekdayLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *view = obj;
            view.frame = CGRectMake(view.frame.origin.x, [UIApplication sharedApplication].keyWindow.bounds.size.height, view.frame.size.width, view.frame.size.height);
        }];
    } completion:^(BOOL finished) {
        [self.weekdayLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromSuperview];
        }];
    }];
    
    [super viewWillDisappear:animated];
}

- (NSString *)localWeekday:(NSInteger)weekday
{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"E"];
    NSDate *date = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:-1 fromDate:date];
    while (components.weekday != weekday) {
        components.day += 1;
        date = [[NSCalendar currentCalendar] dateFromComponents:components];
        components = [[NSCalendar currentCalendar] components:-1 fromDate:date];
    }
    return [fmt stringFromDate:date];
}

// count moths
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 12 * (self.endYear - self.startYear);
}

// count weeks * 7 in moth
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger year = section / 12 + self.startYear;
    NSInteger month = section % 12 + 2;
    NSInteger days = 0;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay)
                                               fromDate:[NSDate dateWithTimeIntervalSince1970:0]];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:days];
    
    NSDate *date = [calendar dateFromComponents:components];
    components = [calendar components:(NSCalendarUnitWeekOfMonth) fromDate:date];
    
    return components.weekOfMonth * 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HSUDateCollectionViewCell *cell = (HSUDateCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"HSUDateCollectionViewCell"
                                                                                                             forIndexPath:indexPath];
    NSInteger year = indexPath.section / 12 + self.startYear;
    NSInteger month = indexPath.section % 12 + 1;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay)
                                               fromDate:[NSDate dateWithTimeIntervalSince1970:0]];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:1];
    
    NSDate *date = [calendar dateFromComponents:components];
    components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitWeekOfMonth) fromDate:date];
    
    NSInteger startRow = (components.weekday - 1) % 7;
    NSInteger day = indexPath.row - startRow + 1;
    
    if (day > 0 && day <= [self dayOfYear:year andMonth:month]) {
        [components setDay:day];
        cell.date = [calendar dateFromComponents:components];

        if (!self.allowPastDateSelection && [self dateInPast:components]) {
          cell.disabledColor = self.disabledColor;
        } else if (components.year == self.today.year &&
            components.month == self.today.month &&
            components.day == self.today.day) {
            cell.tintColor = self.todayColor;
        } else if (components.year == self.startSelectDateComponents.year &&
                   components.month == self.startSelectDateComponents.month &&
                   components.day == self.startSelectDateComponents.day) {
            cell.tintColor = self.touchColor;
        } else if (components.year == self.selectedDateComponents.year &&
                   components.month == self.selectedDateComponents.month &&
                   components.day == self.selectedDateComponents.day) {
            cell.tintColor = self.selectedColor;
        } else {
            cell.tintColor = nil;
        }
    } else {
        cell.date = nil;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        HSUDateCollectionViewHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                 withReuseIdentifier:@"Header"
                                                                                        forIndexPath:indexPath];
        NSInteger year = indexPath.section / 12 + self.startYear;
        NSInteger month = indexPath.section % 12 + 1;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        [calendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay)
                                                   fromDate:[NSDate dateWithTimeIntervalSince1970:0]];
        [components setYear:year];
        [components setMonth:month];
        [components setDay:0];
        
        NSDate *date = [calendar dateFromComponents:components];
        components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitWeekday|NSCalendarUnitWeekOfMonth)
                                 fromDate:date];
        
        header.firstWeekDay = components.weekday % 7;
        header.month = month;
        if (components.year == self.today.year && month == self.today.month) {
            header.tintColor = self.touchColor;
        } else {
            header.tintColor = nil;
        }
        [header sizeToFit];
        
        self.title = [NSString stringWithFormat:@"%ld", (long)year];
        
        return header;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.bounds.size.width/7, 70);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    return CGSizeMake(320, 30);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
{
    return 0;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
{
    return 0;
}

- (NSInteger)dayOfYear:(NSInteger)year andMonth:(NSInteger)month
{
    if (month == 2 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return 29;
    }
    if (month == 2) {
        return 28;
    }
    switch (month) {
        case 1:
        case 3:
        case 5:
        case 7:
        case 8:
        case 10:
        case 12:
            return 31;
        default:
            return 30;
    }
}

- (BOOL)dateInPast:(NSDateComponents *)components {
  NSCalendar *cal = [NSCalendar currentCalendar];
  NSDate *today = [cal dateFromComponents:self.today];
  NSDate *otherDate = [cal dateFromComponents:components];

  NSComparisonResult result = [today compare:otherDate];
  switch (result)
  {
    case NSOrderedDescending:
      return YES;
      break;
    default:
      return NO;
  }
}

@end