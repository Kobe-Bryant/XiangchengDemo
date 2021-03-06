//
//  MoreFileViewController.m
//  BoandaProject
//
//  Created by BOBO on 13-12-23.
//  Copyright (c) 2013年 szboanda. All rights reserved.
//

#import "MoreFileViewController.h"
#import "ServiceUrlString.h"
#import "JSONKit.h"
#import "FileUtil.h"
#import "DisplayAttachFileController.h"

@interface MoreFileViewController ()
@property (nonatomic,strong)NSDictionary *fileDic;
@property (nonatomic,strong)NSString *typeStr;
@property (nonatomic,strong)NSMutableArray *valueAry;
@property (nonatomic,strong)UITableView *listTableView;
@property (nonatomic,assign)BOOL isLoading;
@end

@implementation MoreFileViewController
-(id)initWithFile:(NSDictionary*)fileDic andType:(NSString*)type
{
    if ([super init])
    {
        self.fileDic = fileDic;
        self.typeStr = type;
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addGestureRecognizer:self.swipe];
	// Do any additional setup after loading the view.
    NSString *titleStr = [self.fileDic objectForKey:@"wdmc"];
    self.title = titleStr;
    
    self.listTableView = [[UITableView alloc]initWithFrame:self.view.bounds];
    self.listTableView.delegate = self;
    self.listTableView.dataSource = self;
    [self.view addSubview:self.listTableView];
    
    self.valueAry = [[NSMutableArray alloc]initWithCapacity:0];
    
    [self requestData];
}
- (void)requestData
{
    self.isLoading = YES;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"QUERY_DOCUMENT_CENTER" forKey:@"service"];
    NSString *wdbh = [self.fileDic objectForKey:@"wdbh"];
    [params setObject:wdbh forKey:@"parentId"];
    [params setObject:self.typeStr forKey:@"type"];
    NSString *user = [[NSUserDefaults standardUserDefaults]objectForKey:KUserName];
    [params setObject:user forKey:@"userId"];
    
    NSString *strUrl = [ServiceUrlString generateUrlByParameters:params];
    NSLog(@"%@",strUrl);
    
    self.webHelper = [[NSURLConnHelper alloc] initWithUrl:strUrl andParentView:self.view delegate:self];
    
}
#pragma mark - Network Handler Methods
- (void)processWebData:(NSData *)webData
{
    self.isLoading = NO;
    if(webData.length <= 0)
    {
        return;
    }
    NSString *resultJSON = [[NSString alloc] initWithBytes: [webData bytes] length:[webData length] encoding:NSUTF8StringEncoding];
    
    NSLog(@"resultJSON = %@",resultJSON);
    
    //将字符串分割成数组
    NSArray *ary = [resultJSON componentsSeparatedByString:@"result"];
    NSString *str = [ary objectAtIndex:1];
    resultJSON = [NSString stringWithFormat:@"{\"result\"%@",str];
    NSDictionary *obj = [resultJSON objectFromJSONString];
    BOOL bParsedError = NO;
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        NSArray *tmpAry = [obj objectForKey:@"result"];
        [self.valueAry addObjectsFromArray:tmpAry];
    }
    else
    {
        bParsedError = YES;
    }
    [self.listTableView reloadData];
    if(bParsedError)
    {
        [self showAlertMessage:@"解析数据出错!"];
    }
}

- (void)processError:(NSError *)error
{
    self.isLoading = NO;
    [self showAlertMessage:@"获取数据出错!"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - 列表数据源
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_valueAry count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSDictionary* dic = [self.valueAry objectAtIndex:indexPath.row];
    int isFiled = [[dic objectForKey:@"file"]integerValue];
    if (isFiled == 0)
    {
        cell.textLabel.text = [dic objectForKey:@"wdmc"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ ", [dic objectForKey:@"wdmc"]];
        NSString *pathExt = [[dic objectForKey:@"wdmc"] pathExtension];
        cell.imageView.image = [FileUtil imageForFileExt:pathExt];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [dic objectForKey:@"wdmc"]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dic = [self.valueAry objectAtIndex:indexPath.row];
    int isFiled = [[dic objectForKey:@"file"]integerValue];
    
    if (isFiled == 0)
    {
        MoreFileViewController *mfVC = [[MoreFileViewController alloc]initWithFile:dic andType:self.typeStr];
        [self.navigationController pushViewController:mfVC animated:YES];
    }
    else
    {
        NSString *idStr = [dic objectForKey:@"wdbh"];
        NSString *wdkbh = [dic objectForKey:@"wdkbh"];

        if (idStr == nil)
        {
            return;
        }
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:0];
        [params setObject:@"DOWN_OA_FILES" forKey:@"service"];
        [params setObject:idStr forKey:@"wdbh"];
        [params setObject:@"DOWN_FILE" forKey:@"ACTION_TYPE"];
        [params setObject:wdkbh forKey:@"wdkbh"];
        //NSString *strUrl = [ServiceUrlString generateUrlByParameters:params];
        NSString *strUrl = [NSString stringWithFormat:@"http://222.92.101.82:8008/xcoa/invoke/?version=1.0&imei=356242050024965&clientType=IPAD&userid=WCL&password=1&service=DOWN_OA_FILES&wdbh=%@&ACTION_TYPE=DOWN_FILE&docType=%@&wdkbh=%@",idStr,self.typeStr,wdkbh];
        NSLog(@"^^^^^^%@",strUrl);
        
        DisplayAttachFileController *controller = [[DisplayAttachFileController alloc] initWithNibName:@"DisplayAttachFileController"  fileURL:strUrl andFileName:[dic objectForKey:@"wdmc"]];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
}

@end
