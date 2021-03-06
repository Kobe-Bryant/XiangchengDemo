//
//  RecordDetailsViewController.m
//  BoandaProject
//
//  Created by BOBO on 13-12-30.
//  Copyright (c) 2013年 szboanda. All rights reserved.
//

#import "RecordDetailsViewController.h"
#import "ServiceUrlString.h"
#import "RelatedrecordsViewController.h"
#import "HtmlTableGenerator.h"
#import "JSONKit.h"

@interface RecordDetailsViewController ()
@property (nonatomic,strong) NSArray *relatedAry;
@property (nonatomic,strong) NSArray *serviceAry;
@property (nonatomic,copy) NSString *xczfbh;
@property (nonatomic,copy) NSString *serviceType;
@property (nonatomic,strong) NSDictionary *infoDic;

@end

@implementation RecordDetailsViewController
@synthesize dataDic,wrymc;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"基本信息";
        self.serviceType = @"QUERY_XCZF_TZ_BASE";
    }
    return self;
}

-(void)changeWRYMessage:(UIBarButtonItem *)sender{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    if (self.tableView.frame.origin.x == 528) {
        self.tableView.frame = CGRectMake(528+240, 0, 240, 960);
    }
    else{
        self.tableView.frame = CGRectMake(528, 0, 240, 960);
    }
    [UIView commitAnimations];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addGestureRecognizer:self.swipe];
   
    self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc]initWithTitle:@"相关记录" style:UIBarButtonItemStyleBordered target:self action:@selector(changeWRYMessage:)];

    self.serviceAry = [[NSArray alloc]initWithObjects:@"QUERY_XCZF_TZ_XCJCBL",@"QUERY_XCZF_TZ_XCCYJL",@"QUERY_XCZF_TZ_XZCL",@"QUERY_XCZF_TZ_XWBL",@"QUERY_XCZF_TZ_FJ",@"QUERY_XCZF_TZ_YJTZD",@"QUERY_XCZF_TZ_XZJYS",@"QUERY_XCZF_TZ_XZTSS",@"QUERY_XCZF_TZ_XZJSS",@"QUERY_XCZF_TZ_XZJCS",@"QUERY_XCZF_TZ_CFAJHFB",@"QUERY_XCZF_TZ_XZJSHFB",@"QUERY_XCZF_TZ_HJJCYJS",@"QUERY_XCZF_TZ_ZDXMXZFDS",@"QUERY_XCZF_TZ_GPDB",@"QUERY_XCZF_TZ_WFLASP",@"QUERY_XCZF_TZ_XZCFYJS", nil];

    
    self.xczfbh = [self.dataDic objectForKey:@"XCZFBH"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self.serviceType forKey:@"service"];
    [params setObject:self.xczfbh forKey:@"XCZFBH"];
    
    NSString *strUrl = [ServiceUrlString generateUrlByParameters:params];

    self.webHelper = [[NSURLConnHelper alloc] initWithUrl:strUrl andParentView:self.view delegate:self];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.relatedAry.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    NSDictionary *dic = [self.relatedAry objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)",[dic objectForKey:@"title"],[dic objectForKey:@"number"]];
    cell.textLabel.numberOfLines = 0;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dic = [self.relatedAry objectAtIndex:indexPath.row];
    if ([[dic objectForKey:@"number"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        return;
    }
    NSString *serviceStr = [self.serviceAry objectAtIndex:indexPath.row];
    RelatedrecordsViewController* rdVC = [[RelatedrecordsViewController alloc]init];
    rdVC.wrymc = self.wrymc;
    rdVC.xczfbh = self.xczfbh;
    rdVC.serviceType = serviceStr;
    rdVC.title = [dic objectForKey:@"title"];
    [self.navigationController pushViewController:rdVC animated:YES];
}

-(void)processWebData:(NSData *)webData{
    
    NSString *resultJSON =[[NSString alloc] initWithBytes: [webData bytes] length:[webData length] encoding:NSUTF8StringEncoding];
    NSString *htmlStr;
    NSDictionary *result = [resultJSON objectFromJSONString];
    NSArray *resultArr = [result objectForKey:@"data"];
    if(resultArr.count==0){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"提示"
                              message:kNETDATA_ERROR_MESSAGE
                              delegate:self
                              cancelButtonTitle:@"确定"
                              otherButtonTitles:nil];
        [alert show];
    }
    else{
        self.infoDic = [resultArr objectAtIndex:0];
        htmlStr = [HtmlTableGenerator genContentWithTitle:wrymc andParaMeters:self.infoDic andType:self.serviceType];
        self.relatedAry = [HtmlTableGenerator genContentWithValue:self.infoDic];
        for (NSDictionary* dic in self.relatedAry) {
            
            NSLog(@"dic = %@",[dic objectForKey:@"title"]);
            
            
        }
        
        [self.tableView reloadData];
    }
    self.myWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    [self.myWebView loadHTMLString:htmlStr baseURL:[[NSBundle mainBundle] bundleURL]];
}

-(void)Relatedrecords
{
    RelatedrecordsViewController* rdVC = [[RelatedrecordsViewController alloc]init];
    rdVC.xczfbh = self.xczfbh;
    [self.navigationController pushViewController:rdVC animated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setMyWebView:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
