//
//  DetailViewController.m
//  example
//
//  Created by Lawrence on 2020/5/25.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "DetailViewController.h"
#import <ActorModel/ActorModel.h>

@interface DetailViewController () <订阅者>

@property (nonatomic, strong) ActionHandler *handler;

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *消息Label;

@end

@implementation DetailViewController

- (void)dealloc {
    [_handler 重置];
    [Actor消息中心() 移除订阅者:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _handler = [[ActionHandler alloc] initWithSubscriber:self];
    
    [Actor消息中心() 订阅该地址:@"消息/hello" 订阅者:self];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(隐藏键盘)];
    [self.view addGestureRecognizer:tap];
}

- (IBAction)发送消息点击:(UIButton *)sender {
    [Actor消息中心() 派发消息给订阅该地址的订阅者:@"消息/hello" 消息:_textField.text 消息类型:nil];
}

- (void)隐藏键盘 {
    [_textField endEditing:true];
}

- (void)收到该地址消息:(NSString *)path 消息:(id)message 消息类型:(NSString *)type {
    if ([path isEqualToString:@"消息/hello"]) {
        __weak __typeof(self)weakSelf = self;
        DispatchOnMainQueue(^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf != nil) {
                NSString *text = (NSString *)message;
                strongSelf.消息Label.text = text.length > 0 ? text : @"";
            }
        });
    }
}

@end
