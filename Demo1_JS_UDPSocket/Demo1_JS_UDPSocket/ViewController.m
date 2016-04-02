//
//  ViewController.m
//  Demo1_JS_UDPSocket
//
//  Created by  江苏 on 16/3/27.
//  Copyright © 2016年 jiangsu. All rights reserved.
//

#import "ViewController.h"
#import "AsyncUdpSocket.h"
@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextField *MessageTF;
@property (strong, nonatomic) IBOutlet UIView *messageView;
@property(nonatomic,strong)AsyncUdpSocket* myUDPSocket;
@property(nonatomic)int count;
@property(nonatomic,strong)NSMutableArray* onlineIPS;
@property(nonatomic,copy)NSString* toHost;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UISwitch *mySwitch;
@property (strong, nonatomic) IBOutlet UITableView *FriendTableView;
@end

@implementation ViewController
- (IBAction)sendMessage:(id)sender {
    NSData *sendData=[self.MessageTF.text dataUsingEncoding:NSUTF8StringEncoding];
    if (!self.toHost) {
        self.toHost=@"255.255.255.255";
    }
    [self.myUDPSocket sendData:sendData toHost:self.toHost port:9000 withTimeout:-1 tag:0];
}
- (IBAction)mySwitchValueChanged:(UISwitch *)sender {
    if (self.mySwitch.isOn) {
        self.statusLabel.text=@"对所有人说";
        self.toHost=@"255.255.255.255";
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.count=0;
    self.onlineIPS=[NSMutableArray array];
    self.myUDPSocket=[[AsyncUdpSocket alloc]initWithDelegate:self];
    //绑定端口
    [self.myUDPSocket bindToPort:9000 error:nil];
    //是否设置为广播
    [self.myUDPSocket enableBroadcast:YES error:nil];
    //开始接收数据
    [self.myUDPSocket receiveWithTimeout:-1 tag:0];
    [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(checkOnline) userInfo:nil repeats:YES];
}
-(void)checkOnline{
    NSData *sendData=[@"谁在线" dataUsingEncoding:NSUTF8StringEncoding];
    [self.myUDPSocket sendData:sendData toHost:@"255.255.255.255" port:9000 withTimeout:-1 tag:0];
}
-(BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port{
    if (![host hasPrefix:@":"]) {
        NSString* info=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        if ([info isEqualToString:@"谁在线"]) {
            [self.myUDPSocket sendData:[@"我在线" dataUsingEncoding:NSUTF8StringEncoding] toHost:host port:9000 withTimeout:-1 tag:0];
        }else if ([info isEqualToString:@"我在线"]){
            //判断IP是否已经存在，如果存在了，则不保存，反之保存
            if (![self.onlineIPS containsObject:host]) {
                [self.onlineIPS addObject:host];
                //刷新tableview
                [self.FriendTableView reloadData];
            }
        }else{
            //收到的既不是谁在线，也不是我在线，而是发送来的消息
            UILabel* label=[[UILabel alloc]initWithFrame:CGRectMake(0, 30*self.count++, 250, 30)];
            label.text=[host stringByAppendingString:info];
            [self.messageView addSubview:label];
        }
    }
    [self.myUDPSocket receiveWithTimeout:-1 tag:0];
    return YES;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    return self.onlineIPS.count;
}

 - (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     static NSString *identifer = @"MyCell";
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
     
     if (!cell) {
         cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
     }
     cell.textLabel.text = [[self.onlineIPS[indexPath.row] componentsSeparatedByString:@"."] lastObject];
     NSLog(@"%@",self.onlineIPS[indexPath.row]);
     return cell;
 }
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.toHost=self.onlineIPS[indexPath.row];
    [self.mySwitch setOn:NO animated:YES];
    self.statusLabel.text=[NSString stringWithFormat:@"对%@说",self.toHost];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
