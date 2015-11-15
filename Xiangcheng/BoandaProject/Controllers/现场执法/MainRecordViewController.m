//
//  MainRecordViewController.m
//  BoandaProject
//
//  Created by BOBO on 13-12-30.
//  Copyright (c) 2013年 szboanda. All rights reserved.
//

#import "MainRecordViewController.h"
#import "UITableViewCell+Custom.h"
#import "JSONKit.h"
#import "RecordDetailsViewController.h"
#import "ServiceUrlString.h"


@interface MainRecordViewController ()<UITextFieldDelegate>
@property (nonatomic,copy) NSString *pageCount;
@property (nonatomic,strong)NSMutableArray *valueAry;
@end

@implementation MainRecordViewController
@synthesize recordTable;
@synthesize isGotJsonString;
@synthesize wrymcLab,qsrqLab,wrymcFie;
@synthesize qsrqFie,searchBtn,jzrqLab,jzrqFie;
@synthesize webHelper,currentTag;
@synthesize dateController,popController,scrollImage;
@synthesize curParsedData,webResultAry;
@synthesize isLoading,isScroll,currentPage,isEnd;

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
    self.title = @"执法台账";
    self.scrollImage.hidden = YES;

    self.qsrqFie.delegate = self;
    self.jzrqFie.delegate = self;
    
    [self.qsrqFie addTarget:self action:@selector(touchFromDate:) forControlEvents:UIControlEventTouchDown];
    [self.jzrqFie addTarget:self action:@selector(touchFromDate:) forControlEvents:UIControlEventTouchDown];
 
    PopupDateViewController *date = [[PopupDateViewController alloc] initWithPickerMode:UIDatePickerModeDate];
	self.dateController = date;
	self.dateController.delegate = self;
	
	UINavigationController *navDate = [[UINavigationController alloc] initWithRootViewController:dateController];
	UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navDate];
	self.popController = popover;
    
    self.valueAry = [NSMutableArray array];
    
    currentPage = 1;
    isEnd = NO;
    [self.scrollImage setImage:[UIImage imageNamed:@"upScroll.png"]];
    
    [self requestData];
}


-(void)requestData
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"QUERY_XCZF_INFO" forKey:@"service"];
    [params setObject:qsrqFie.text forKey:@"startDate"];
    [params setObject:jzrqFie.text forKey:@"endDate"];
    [params setObject:wrymcFie.text forKey:@"wrymc"];
    [params setObject:[NSString stringWithFormat:@"%d",ONE_PAGE_SIZE] forKey:@"pagesize"];
    [params setObject:[NSString stringWithFormat:@"%d",currentPage] forKey:@"current"];
 
    NSString *strUrl = [ServiceUrlString generateUrlByParameters:params];
    NSLog(@"^^^^%@",strUrl);
    self.pageCount = @"0";
    self.webHelper = [[NSURLConnHelper alloc] initWithUrl:strUrl andParentView:self.view delegate:self];
}
- (void)processWebData:(NSData *)webData
{
    self.isLoading = NO;
    BOOL bParsedError = NO;
    if(webData.length > 0)
    {
        NSString *jsonStr = [[NSString alloc] initWithData:webData encoding:NSUTF8StringEncoding];
        NSArray *ary = [jsonStr componentsSeparatedByString:@"data"];
        NSString *str = [ary objectAtIndex:1];
        jsonStr = [NSString stringWithFormat:@"{\"data\"%@",str];
        NSArray *datailAry = [[jsonStr objectFromJSONString]objectForKey:@"data"];
        NSString *countStr = [ary objectAtIndex:0];
        NSArray *countAry = [countStr componentsSeparatedByString:@"ZS:"];
        countStr = [countAry objectAtIndex:1];
        self.pageCount = [countStr substringToIndex:countStr.length-2];
        if (currentPage == 1) {
            [self.valueAry removeAllObjects];
        }
        if (datailAry.count < ONE_PAGE_SIZE) {
            isEnd = YES;
        }
        if(datailAry != nil && datailAry.count)
        {
            [self.valueAry addObjectsFromArray:datailAry];
        }
        else
        {
            bParsedError = YES;
        }
    }
    [self.recordTable reloadData];
    
    if(bParsedError)
    {
        [self showAlertMessage:@"查询不到数据"];
    }
    
  
    
}

- (void)processError:(NSError *)error
{
    self.isLoading = NO;
    [self showAlertMessage:@"获取数据出错!"];
}
- (void)touchFromDate:(id)sender {
    
    UITextField *tfd =(UITextField*)sender;
    tfd.text = @"";
    currentTag = tfd.tag;
    NSDateFormatter *matter = [[NSDateFormatter alloc]init];
    [matter setDateFormat:@"yyyy-MM-dd"];
    if (currentTag == 1) {
        NSDate *data = [matter dateFromString:self.qsrqFie.text];
        self.dateController.date = data;
    }
    else if (currentTag == 2){
        NSDate *data = [matter dateFromString:self.jzrqFie.text];
        self.dateController.date = data;
    }
	[self.popController presentPopoverFromRect:[tfd bounds] inView:tfd permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)searchBtnPressed:(id)sender
{
    
    [wrymcFie resignFirstResponder];
    [self.valueAry removeAllObjects];


    currentPage = 1;
    isEnd = NO;
    
    [self.scrollImage setImage:[UIImage imageNamed:@"upScroll.png"]];
    
    [self requestData];

}
#pragma mark - Choose Date delegate

- (void)PopupDateController:(PopupDateViewController *)controller Saved:(BOOL)bSaved selectedDate:(NSDate*)date {
    
    [self.popController dismissPopoverAnimated:YES];
	if (bSaved) {
        if (self.currentTag == 1)
        {
            NSDateFormatter *matter = [[NSDateFormatter alloc]init];
            [matter setDateFormat:@"yyyy-MM-dd"];
            NSString *dateString = [matter stringFromDate:date];
            NSDate *jzsjDate = [matter dateFromString:self.jzrqFie.text];
            NSTimeInterval qssj = [date timeIntervalSince1970];
            NSTimeInterval jzsj = [jzsjDate timeIntervalSince1970];
            if (jzsj>qssj || [self.jzrqFie.text isEqualToString:@""]) {
                self.qsrqFie.text = dateString;
            }
            else{
                [self showAlertMessage:@"起始时间不能晚于截止时间"];
            }
        }
        else if (self.currentTag == 2)
        {
            NSDateFormatter *matter = [[NSDateFormatter alloc]init];
            [matter setDateFormat:@"yyyy-MM-dd"];
            NSString *dateString = [matter stringFromDate:date];
            NSDate *qssjDate = [matter dateFromString:self.qsrqFie.text];
            NSTimeInterval jzsj = [date timeIntervalSince1970];
            NSTimeInterval qssj = [qssjDate timeIntervalSince1970];
            if (jzsj>qssj || [self.qsrqFie.text isEqualToString:@""]) {
                self.jzrqFie.text = dateString;
            }
            else{
                [self showAlertMessage:@"截止时间不能早于起始时间"];
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.valueAry count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSDictionary *tmpDic = [self.valueAry objectAtIndex:indexPath.row];
    //现场检查人  询问人
    NSString *person = [NSString stringWithFormat:@"调查人：%@",[tmpDic objectForKey:@"ZFRY"]];

    NSString *date = [tmpDic objectForKey:@"DCSJ"];
    date = [date substringToIndex:10];
    
    cell = [UITableViewCell makeSubCell:tableView withTitle:[tmpDic objectForKey:@"DWMC"] andSubvalue1:person andSubvalue2:[NSString stringWithFormat:@"检查时间：%@",date] andSubvalue3:@"" andSubvalue4:@"" andNoteCount:indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"查询结果%@条",self.pageCount];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row%2 == 0)
        cell.backgroundColor = LIGHT_BLUE_UICOLOR;
    else
        cell.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tmpDic = [self.valueAry objectAtIndex:indexPath.row];
    RecordDetailsViewController *childView = [[RecordDetailsViewController alloc] init];
    childView.dataDic = tmpDic;
    childView.wrymc = [tmpDic objectForKey:@"DWMC"];
    [self.navigationController pushViewController:childView animated:YES];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
    NSLog(@"%f",scrollView.contentOffset.y);
    NSLog(@"%f",scrollView.contentSize.height);
    NSLog(@"%f",scrollView.frame.size.height);
    
    
    if (scrollView.contentSize.height < scrollView.contentOffset.y+scrollView.frame.size.height) {
        
        NSLog(@"huodaodibuliao");
        
        
    }
    
    
	if (isLoading) return;
	
    if (scrollView.contentSize.height - scrollView.contentOffset.y <= 850 ) {
        
        if (!isEnd) {
            currentPage++;
            [self requestData];
        }
		else{
            [self showText:kNETLAST_MESSAGE];
        }
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
