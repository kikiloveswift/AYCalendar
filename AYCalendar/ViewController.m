//
//  ViewController.m
//  AYCalendar
//
//  Created by kong on 16/12/21.
//  Copyright © 2016年 konglee. All rights reserved.
//

#import "ViewController.h"
#import "AYCalendarViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}
- (IBAction)selectedBeginDate:(id)sender
{
    AYCalendarViewController *calVC = [[AYCalendarViewController alloc] init];
    [self.navigationController pushViewController:calVC animated:YES];
    
}




@end
