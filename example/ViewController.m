//
//  ViewController.m
//  example
//
//  Created by Lawrence on 2020/5/22.
//  Copyright © 2020 Lawrence. All rights reserved.
//

#import "ViewController.h"
#import <ActorModel/ActorModel.h>
#import "HttpClient.h"

@interface ViewController () <订阅者>

@property (nonatomic, strong) ActionHandler *handler;
@property (nonatomic, strong) NSString *username;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UIButton *changeNameButton;
@property (weak, nonatomic) IBOutlet UILabel *消息Label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _handler = [[ActionHandler alloc] initWithSubscriber:self];
    
    [Actor消息中心() 订阅该地址:@"首页/用户名" 订阅者:self];
    [Actor消息中心() 订阅该地址:@"消息/hello" 订阅者:self];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(隐藏键盘)];
    [self.view addGestureRecognizer:tap];
}

- (void)dealloc {
    [_handler 重置];
    [Actor消息中心() 移除订阅者:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Actor消息中心() 请求Actor:@"首页/用户名" options:nil 订阅者:[HttpClient instance]];
}


- (void)updateUI {
    _label.text = _username;
}

- (IBAction)changeUsernameTouched:(UIButton *)sender {
    if (_textfield.text.length) {
        [Actor消息中心() 请求Actor:@"用户/更新用户名" options:@{@"url": @"text/updateusername", @"用户名": _textfield.text} 订阅者:[HttpClient instance]];
        _textfield.text = @"";
    } else {
        NSLog(@"名称长度为0");
    }
}

- (void)隐藏键盘 {
    [_textfield endEditing:true];
}

- (void)收到该地址资源:(NSString *)path 资源:(id)resource options:(NSDictionary *)options {
    if ([path isEqualToString:@"首页/用户名"]) {
        NSLog(@"received resource on actor queue");
        __weak __typeof(self)weakSelf = self;
        DispatchOnMainQueue(^{
            NSLog(@"update UI on main queue");
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf.username = (NSString *)resource;
                [strongSelf updateUI];
            }
        });
    }
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
