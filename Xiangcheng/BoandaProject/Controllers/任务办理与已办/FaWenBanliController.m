//
//  FaWenBanliController.m
//  GuangXiOA
//
//  Created by  on 11-12-27.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "FaWenBanliController.h"
#import "SharedInformations.h"
#import "UITableViewCell+Custom.h"
#import "DisplayAttachFileController.h"
#import "PDJsonkit.h"
#import "NSStringUtil.h"
#import "ServiceUrlString.h"
#import "FileUtil.h"
#import "SystemConfigContext.h"

@implementation FaWenBanliController
@synthesize infoDic,toDisplayKey,toDisplayKeyTitle;
@synthesize stepAry,attachmentAry,gwInfoAry,resTableView,isHandle;
@synthesize toDisplayHeightAry;
@synthesize webHelper,stepHeightAry,actionsModel,itemParams;

- (id)initWithNibName:(NSString *)nibNameOrNil andParams:(NSDictionary*)item isBanli:(BOOL)isToBanLi
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self)
    {
        self.itemParams = item;
        isHandle = isToBanLi;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addGestureRecognizer:self.swipe];
    
    
    //self.toDisplayKey = [NSArray arrayWithObjects:@"FBDW",@"ZBDWHRGR",@"XGSJ",@"WJLX",@"MJ",@"ZS",@"ZSDW",@"CSDW",@"CBDW",@"XGR",@"WH",@"ZTC",@"WJMC",nil];
    //self.toDisplayKeyTitle = [NSArray arrayWithObjects:@"拟稿单位：",@"拟稿人：",@"拟稿时间：",@"文件类型：",@"机密等级：",@"发行范围：",@"主送：",@"抄送：",@"抄报：",@"核稿：",@"文号：",@"主题词：",@"文件标题：",nil];
    self.toDisplayKey = [NSArray arrayWithObjects:@"WJLX",@"WH",@"CJSJ",@"JJCD",@"WJMC",@"FBDW",@"MJ",@"XGR",@"XGSJ",@"XDR",@"ZSDW",@"CSDW",@"CBDW",@"ZS",@"ZTC",@"hgyj",@"huigyj",@"qfyj",@"DNUM",nil];
    self.toDisplayKeyTitle = [NSArray arrayWithObjects:@"文件类型：",@"文号：",@"发文时间：",@"紧急程度：",@"标题：",@"拟文单位：",@"密级：",@"拟稿人：",@"拟稿时间：",@"校对人：",@"主送：",@"抄送：",@"抄报：",@"发行范围：",@"主题词：",@"核稿意见：",@"会稿意见：",@"签发意见：",@"打印份数：", nil];
    self.bOKFromTransfer = NO;
    self.stepAry = [[NSMutableArray alloc]init];
    self.attachmentAry = [[NSMutableArray alloc]init];
    self.gwInfoAry = [[NSMutableArray alloc]init];

    NSMutableArray *tempDisplayHeightAry = [[NSMutableArray alloc] initWithCapacity:15];
    for (int i=0; i< 15;i++)
    {
        [tempDisplayHeightAry addObject:[NSNumber numberWithFloat:60.0f]];
    }
    self.toDisplayHeightAry = tempDisplayHeightAry;
    
    //设置NavigationBarItem的字样
    if (isHandle)
    {
        self.actionsModel = [[ToDoActionsDataModel alloc] initWithTarget:self andParentView:self.view];
        [actionsModel requestActionDatasByParams:itemParams];

    }
    
    NSMutableDictionary *dicParams = [[NSMutableDictionary alloc] initWithCapacity:0];
    [dicParams setObject:@"QUERY_OAFWJBXX_IPAD" forKey:@"service"];
    [dicParams setObject:[itemParams objectForKey:@"YWBH"] forKey:@"businessId"];
    [dicParams setObject:[itemParams objectForKey:@"LCSLBH"] forKey:@"lcslbh"];
   
    NSString* strUrl = [ServiceUrlString generateUrlByParameters:dicParams];
    NSLog(@"^^^^^^^^%@",strUrl);
    
    self.webHelper = [[NSURLConnHelper alloc] initWithUrl:strUrl andParentView:self.view delegate:self];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (self.webHelper)
    {
        [self.webHelper cancel];
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Network Handler Methods

-(void)processWebData:(NSData*)webData
{
    if([webData length] <=0 )
        return;
    BOOL bParseError = NO;
    NSString *resultJSON = [[NSString alloc] initWithBytes: [webData bytes] length:[webData length] encoding:NSUTF8StringEncoding];
    NSDictionary *dic = [resultJSON objectFromJSONString];
    
    NSLog(@"dic = %@",dic);
    
    
    if ([dic isKindOfClass:[NSDictionary class]])
    {
        
        self.infoDic = [NSMutableDictionary dictionaryWithDictionary:[[dic objectForKey:@"data"] objectAtIndex:0]];
        //需要在此处配置字典
        NSString *djsj = [self.infoDic objectForKey:@"XGSJ"];
        if([djsj length] >=16)  
        {
            [self.infoDic setObject:[djsj substringToIndex:11] forKey:@"XGSJ"];
        }
        NSArray *hgyjArray = [dic objectForKey:@"hgyj"];
        NSArray *huigyjArray = [dic objectForKey:@"huigyj"];
        NSArray *qfyjArray = [dic objectForKey:@"qfyj"];
    
        if (hgyjArray && hgyjArray.count) {
            [self.infoDic setObject:[[hgyjArray objectAtIndex:0] objectForKey:@"CLRYJ"] forKey:@"hgyj"];
        }
        if (huigyjArray && huigyjArray.count) {
            [self.infoDic setObject:[[huigyjArray objectAtIndex:0] objectForKey:@"CLRYJ"] forKey:@"huigyj"];
        }
        if (qfyjArray && qfyjArray.count) {
            [self.infoDic setObject:[[qfyjArray objectAtIndex:0] objectForKey:@"CLRYJ"] forKey:@"qfyj"];   
        }
   
        self.stepAry = [dic objectForKey:@"steps"];
        
        self.attachmentAry = [dic objectForKey:@"fj"];

        self.gwInfoAry = [dic objectForKey:@"gw"];


    }
    else {
        bParseError = YES;
    }
    
    if (bParseError) {
        
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"提示" 
                              message:@"获取数据出错。" 
                              delegate:self 
                              cancelButtonTitle:@"确定" 
                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
   
    //
    UIFont *font1 = [UIFont fontWithName:@"Helvetica" size:19.0];
    NSMutableArray *aryTmp1 = [[NSMutableArray alloc] initWithCapacity:13];
    for (int i=0; i< 19;i++)
    {
        CGFloat cellHeight = 60.0f;
        if (i>=3)
        {
            NSString *itemTitle =[NSString stringWithFormat:@"%@", [infoDic objectForKey:[toDisplayKey objectAtIndex:i]]];
            cellHeight = [NSStringUtil calculateTextHeight:itemTitle byFont:font1 andWidth:520.0]+20;
        }
        else
        {
            cellHeight = 70;
        }
        if(cellHeight < 60) cellHeight = 60.0f;
        [aryTmp1 addObject:[NSNumber numberWithFloat:cellHeight]];
     }
    
    self.toDisplayHeightAry = aryTmp1;

    
    UIFont *font2 = [UIFont fontWithName:@"Helvetica" size:18.0];
    NSMutableArray *aryTmp2 = [[NSMutableArray alloc] initWithCapacity:6];
    
    NSLog(@"stepAry = %d",stepAry.count);
    
    for (int i=0; i< [stepAry count];i++) {
        
        NSDictionary *dicTmp = [stepAry   objectAtIndex:i];
        NSString *value =[NSString stringWithFormat:@"批示记录：%@",
                          [dicTmp objectForKey:@"CLRYJ"]];


        CGFloat cellHeight = [NSStringUtil calculateTextHeight:value byFont:font2 andWidth:700] + 30.0;
        if(cellHeight < 60)cellHeight = 60.0f;
        [aryTmp2 addObject:[NSNumber numberWithFloat:cellHeight]];
        
    }
    self.stepHeightAry = aryTmp2;
    
    [self.resTableView reloadData];
}

-(void)processError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:@"提示" 
                          message:@"请求数据失败." 
                          delegate:self 
                          cancelButtonTitle:@"确定" 
                          otherButtonTitles:nil];
    [alert show];
    return;
}

#pragma mark - UITableView Delegate & DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectZero];
    headerView.font = [UIFont systemFontOfSize:19.0];
    headerView.backgroundColor = [UIColor colorWithRed:170.0/255 green:223.0/255 blue:234.0/255 alpha:1.0];
    headerView.textColor = [UIColor blackColor];
    if (section == 0)  headerView.text= @"  发文信息";
    else if (section == 1)  headerView.text= @"  发文附件";
    else if (section == 2)  headerView.text= @"  处理步骤";
    else   headerView.text= @"  正式公文";
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2 )
    {
        return 115;
    }
    else if (indexPath.section == 1 )
    {
        return 80;
    }
    else if(indexPath.section == 0)
    {
        return [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
    }
	return 80;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row%2 == 0)
        cell.backgroundColor = LIGHT_BLUE_UICOLOR;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0 )
    {
        return 15;
    }
    if (section == 1)
    {
        return self.attachmentAry.count;
    }
    if (section == 2)
    {
        return [self.stepAry count];
    }
    else
    {
        return [self.gwInfoAry count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
    if (indexPath.section == 0)
    {
        if(indexPath.row == 0)
        {
            //文件类型 文号
            NSString *title1 = [toDisplayKeyTitle objectAtIndex:0];
            NSString *title2 = [toDisplayKeyTitle objectAtIndex:1];
            
            NSString *fwType = [infoDic objectForKey:[toDisplayKey objectAtIndex:0]];
            NSString *value1 = [SharedInformations getXCOAFWLXFromStr:fwType];
            NSString *value2 = [infoDic objectForKey:[toDisplayKey objectAtIndex:1]];
            
            
            CGFloat height = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withValue1:title1 value2:title2 value3:value1 value4:value2 height:height];
        }
        else if (indexPath.row == 1)
        {
            //发文时间  紧急程度
            NSString *title1 = [toDisplayKeyTitle objectAtIndex:2];
            NSString *title2 = [toDisplayKeyTitle objectAtIndex:3];
            
            NSString *value1 = [infoDic objectForKey:[toDisplayKey objectAtIndex:2]];
            if([value1 length]>10) value1 = [value1 substringToIndex:16];
            
            int gklx = [[infoDic objectForKey:[self.toDisplayKey objectAtIndex:4]] intValue];
            NSString *value2 = [SharedInformations getJJCDFromInt:gklx];
            
            CGFloat height = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withValue1:title1 value2:title2 value3:value1 value4:value2 height:height];
        }
        else if (indexPath.row == 2)
        {
            
            NSString *title = [self.toDisplayKeyTitle objectAtIndex:4];
            NSString *value = [NSString stringWithFormat:@"%@", [self.infoDic objectForKey:[self.toDisplayKey objectAtIndex:4]]];
            if ([value isEqual:[NSNull null]] || [value isEqualToString:@"(null)"] || value == nil) {
                value = @"";
            }
            CGFloat nHeight = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withTitle:title value:value andHeight:nHeight];
        }
        else if (indexPath.row == 3)
        {
            //拟文单位   密级
            NSString *title1 = [toDisplayKeyTitle objectAtIndex:5];
            NSString *title2 = [toDisplayKeyTitle objectAtIndex:6];
            
            NSString *value1 = [infoDic objectForKey:[toDisplayKey objectAtIndex:5]];
            
            int gklx = [[infoDic objectForKey:[self.toDisplayKey objectAtIndex:6]] intValue];
            NSString *value2 = [SharedInformations getBMJBFromInt:gklx];
            
            CGFloat height = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withValue1:title1 value2:title2 value3:value1 value4:value2 height:height];
        }
        else if (indexPath.row == 4)
        {
            //拟稿人  拟稿时间
            NSString *title1 = [toDisplayKeyTitle objectAtIndex:7];
            NSString *title2 = [toDisplayKeyTitle objectAtIndex:8];
            
            NSString *value1 = [infoDic objectForKey:[toDisplayKey objectAtIndex:7]];
            
            NSString *value2 = [infoDic objectForKey:[self.toDisplayKey objectAtIndex:8]];
            if([value1 length]>10) value1 = [value2 substringToIndex:16];
            
            
            CGFloat height = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            
            NSLog(@"height = %f",height);
            
            cell = [UITableViewCell makeSubCell:tableView withValue1:title1 value2:title2 value3:value1 value4:value2 height:height];
        }
        else
        {
            int div = 4;
            NSString *title = [self.toDisplayKeyTitle objectAtIndex:indexPath.row+div];
            NSString *value = [infoDic objectForKey:[toDisplayKey objectAtIndex:indexPath.row+div]]; 
            CGFloat nHeight = [[self.toDisplayHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withTitle:title value:value andHeight:nHeight];
            
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == 1)
    {
        static NSString *identifier = @"fujiancell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0];
            cell.textLabel.numberOfLines = 2;
        }
        if (self.attachmentAry ==nil||[self.attachmentAry count] == 0)
        {
            cell.textLabel.text = @"没有相关附件";
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            NSDictionary *dicTmp = [self.attachmentAry objectAtIndex:indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ ", [dicTmp objectForKey:@"WDMC"]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [dicTmp objectForKey:@"WDDX"]];
            NSString *pathExt = [[dicTmp objectForKey:@"WDMC"] pathExtension];
            cell.imageView.image = [FileUtil imageForFileExt:pathExt];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else if (indexPath.section == 2)
    {
        if (self.stepAry ==nil||[self.stepAry count] == 0)
        {
            static NSString *identifier = @"fujiancell";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
                cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:19.0];
                cell.textLabel.numberOfLines = 0;
            }
            cell.textLabel.text = @"没有相关处理步骤";
        }
        else
        {
            NSDictionary *dicTmp = [stepAry objectAtIndex:indexPath.row];
            NSString *title =[NSString stringWithFormat:@"%d %@", indexPath.row+1,[dicTmp objectForKey:@"BZMC"] ];
            NSString *value2 =[NSString stringWithFormat:@"处理人：%@",[dicTmp objectForKey:@"YHM"] ];
            NSString *value1 =[NSString stringWithFormat:@"步骤名称：%@", [dicTmp objectForKey:@"BZMC"] ];
            
            NSArray *clryjAry = [dicTmp objectForKey:@"CLRYJ"];
            NSString *clryj = @"";
            if (clryjAry && clryjAry.count) {
                clryj = [clryjAry objectAtIndex:0];
            }
            NSString *value4 =[NSString stringWithFormat:@"处理人意见：%@", clryj];
            
            NSString *clsj = [dicTmp objectForKey:@"JSSJS"];
            if([clsj length] >=16)
            {
                clsj = [clsj substringToIndex:11];
            }
            if ([clsj isEqualToString:@""])
            {
                clsj = @"处理中";
            }
            NSString *value3 =[NSString stringWithFormat:@"处理时间：%@", clsj];
            
            CGFloat height  = [[stepHeightAry objectAtIndex:indexPath.row] floatValue];
            cell = [UITableViewCell makeSubCell:tableView withTitle:title SubValue1:value1 SubValue2:value2 SubValue3:value3 SubValue4:value4 andHeight:height];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == 3)
    {
        static NSString *identifier = @"CellIdentifier";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:19.0];
            cell.textLabel.numberOfLines = 0;
        }
        if (self.gwInfoAry ==nil||[self.gwInfoAry count] == 0)
        {
            cell.textLabel.text = @"没有相关数据";
        }
        else
        {
            NSDictionary *dicTmp = [self.gwInfoAry objectAtIndex:indexPath.row];
            NSString *wdmc = [NSString stringWithFormat:@"%@.doc",[dicTmp objectForKey:@"FWGBH"]];
            
            NSLog(@"wdmc = %@",wdmc);
            
            
            cell.textLabel.text = wdmc;
            NSString *pathExt = [wdmc pathExtension];
            cell.imageView.image = [FileUtil imageForFileExt:pathExt];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    
    UIView *bgview = [[UIView alloc] initWithFrame:cell.contentView.frame];
    bgview.backgroundColor = [UIColor colorWithRed:0 green:94.0/255 blue:107.0/255 alpha:1.0];
    cell.selectedBackgroundView = bgview;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SystemConfigContext *context = [SystemConfigContext sharedInstance];
    NSString *seviceHeader = [context getSeviceHeader];
    
    NSLog(@"seviceHeader = %@",seviceHeader);
    
    
    if(indexPath.section == 1)
    {
        if ([attachmentAry count] <= 0)
        {
            return;
        }
        NSDictionary *dicTmp = [attachmentAry objectAtIndex:indexPath.row];
        NSString *idStr = [dicTmp objectForKey:@"WDBH"];
        NSString *wdlj = [dicTmp objectForKey:@"WDLJ"];
        //NSString *appidStr = [dicTmp objectForKey:@"APPBH"];
        if (idStr == nil )
        {
            return;
        }
        
        NSString *strUrl = [NSString stringWithFormat:@"http://%@%@",seviceHeader,wdlj];
        NSLog(@"^^^^^%@",strUrl);
        DisplayAttachFileController *controller = [[DisplayAttachFileController alloc] initWithNibName:@"DisplayAttachFileController"  fileURL:strUrl andFileName:[dicTmp objectForKey:@"WDMC"]];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else if(indexPath.section == 3)
    {
        if ([gwInfoAry count] <= 0)
        {
            return;
        }
        NSDictionary *dicTmp = [gwInfoAry objectAtIndex:indexPath.row];
        NSString *idStr = [dicTmp objectForKey:@"FWGBH"];
        
        if (idStr == nil )
        {
            return;
        }
        
        NSString *wdmc = [NSString stringWithFormat:@"%@.doc",[dicTmp objectForKey:@"FWGBH"]];
        NSString *wdlj = [NSString stringWithFormat:@"/UPLOAD_FILE/zhbg/FWDJ/fwg/%@",wdmc];
        NSString *strUrl = [NSString stringWithFormat:@"http://%@%@",seviceHeader,wdlj];
        NSLog(@"^^^^^%@",strUrl);
        DisplayAttachFileController *controller = [[DisplayAttachFileController alloc] initWithNibName:@"DisplayAttachFileController"  fileURL:strUrl andFileName:wdmc];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end

