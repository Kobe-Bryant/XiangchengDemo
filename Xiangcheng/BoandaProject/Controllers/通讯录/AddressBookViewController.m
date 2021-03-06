//
//  AddressBookViewController.m
//  BoandaProject
//
//  Created by Alex Jean on 13-7-8.
//  Copyright (c) 2013年 szboanda. All rights reserved.
//

#define VIEWCONTROLLER_TITLE @"通讯录"
#define DEPARTMENT_TABLEVIEW_TAG 1001
#define DETAIL_TABLEVIEW_TAG 1002

#define BUSSINESS_NORMAL_TAG 0 //正常
#define BUSSINESS_SEARCH_TAG 1 //搜索
#define BUSSINESS_REFRESH_DATA_TAG 2 //刷新数据
#define BUSSINESS_LOCAL_DATA_TAG 3 //从本地获取数据

#define kUserMC @"YHMC"
#define kUserSJ @"YHSJ"
#define kUserDH @"YHDH"
#define kUserZW @"YHZW"

#import "AddressBookViewController.h"
#import "AddressCardCell.h"

@interface AddressBookViewController ()

@property (nonatomic) int currentNotificationTag;
@property (nonatomic) BOOL isSpecial;

@end

@implementation AddressBookViewController

@synthesize syncManager;
@synthesize currentNotificationTag;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //注册通知 数据同步完成的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:kNotifyDataSyncFininshed object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self modifyNavigationBar];
    
    [self initData];
    
    [self makeView];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(refreshHUD)
    {
        [refreshHUD hide:YES];
    }
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.syncManager cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotifyDataSyncFininshed object:nil];
}

- (void)modifyNavigationBar
{
    self.title = VIEWCONTROLLER_TITLE;
    
    //刷新按钮
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refreshClick:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
}

- (void)initData
{
    index = 0;
    if(usersHelper == nil)
    {
        usersHelper = [[UsersHelper alloc] init];
    }
    
    if(deptDataArray == nil)
    {
        deptDataArray = [[NSMutableArray alloc] init];
    }
    [deptDataArray removeAllObjects];
    [deptDataArray addObjectsFromArray:[usersHelper queryAllRootDept]];
    
    NSLog(@"deptDataArray = %@",deptDataArray);
    
    
    if(detailDataArray == nil)
    {
        detailDataArray = [[NSMutableArray alloc] init];
    }
    [detailDataArray removeAllObjects];
}

- (void)refreshData:(NSNotificationCenter *)notification
{
    if(currentNotificationTag == BUSSINESS_REFRESH_DATA_TAG)
    {

        if(refreshHUD)
        {
            [refreshHUD hide:YES];
        }
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    [self initData];
    [deptTableView reloadData];
    [detailTableView reloadData];
}

- (void)makeView
{
    //导航条
    UIView *navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768*0.4, 44)];
    [self.view addSubview:navigationView];

    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, 230, 30)];
    titleLabel.text = @"部门列表";
    titleLabel.backgroundColor = [UIColor clearColor];
    [navigationView addSubview:titleLabel];
    
    parentButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    parentButton.frame = CGRectMake(220, 10, 75, 30);
    //parentButton.backgroundColor = [UIColor grayColor];
    [parentButton setTitle:@"上级部门" forState:UIControlStateNormal];
    [navigationView addSubview:parentButton];
    parentButton.hidden = YES;
    
    deptTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 768*0.4, 960-50) style:UITableViewStyleGrouped];
    deptTableView.opaque = YES;
    deptTableView.backgroundColor = [UIColor clearColor];
    deptTableView.tag = DEPARTMENT_TABLEVIEW_TAG;
    deptTableView.dataSource = self;
    deptTableView.delegate = self;
    [self.view addSubview:deptTableView];
    
    UISearchBar *mySearchbar = [[UISearchBar alloc] initWithFrame:CGRectMake(768*0.4, 0, 760*0.6, 44)];
    mySearchbar.placeholder = @"输入姓名、电话查询...";
    mySearchbar.delegate = self;
    
    detailTableView = [[UITableView alloc] initWithFrame:CGRectMake(768*0.4, 0, 768*0.6, 960)];
    detailTableView.dataSource = self;
    detailTableView.delegate = self;
    detailTableView.tag = DETAIL_TABLEVIEW_TAG;
    [self.view addSubview:detailTableView];
    
    detailTableView.tableHeaderView = mySearchbar;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 按钮点击处理

- (void)refreshClick:(id)sender
{
    if(refreshHUD == nil)
    {
        refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    }
    [self.view addSubview:refreshHUD];
    refreshHUD.labelText = @"正在刷新中...";
    [refreshHUD show:YES];
    
    //先清空原有存储的数据，
    currentNotificationTag = BUSSINESS_REFRESH_DATA_TAG;
    if(usersHelper)
    {
        [usersHelper clearAllData];
    }
    //重新同步数据
    self.syncManager = [[DataSyncManager alloc] init];
    [syncManager syncAllTables:YES];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - UITableView Delegate Method

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView.tag == DEPARTMENT_TABLEVIEW_TAG)
    {
        return @"";
    }
    else if(tableView.tag == DETAIL_TABLEVIEW_TAG)
    {
        return @"用户列表";
    }
    else
    {
        return @"";
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView.tag == DEPARTMENT_TABLEVIEW_TAG) {
        return deptDataArray.count;
    }
    else if (tableView.tag == DETAIL_TABLEVIEW_TAG) {
        return 1;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == DEPARTMENT_TABLEVIEW_TAG) {
        return 44;
    }
    else if (tableView.tag == DETAIL_TABLEVIEW_TAG) {
        return 88;
    }
    else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag == DEPARTMENT_TABLEVIEW_TAG)
    {
        return 1;
    }
    else if(tableView.tag == DETAIL_TABLEVIEW_TAG)
    {
        if(businessTag == BUSSINESS_SEARCH_TAG)
        {
            return searchResultArray.count;
        }
        else
        {
            return detailDataArray.count;
        }
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(tableView.tag == DEPARTMENT_TABLEVIEW_TAG)
    {
        static NSString *deptCellIdentifier = @"deptCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:deptCellIdentifier];
        if(cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:deptCellIdentifier];
        }
        
        if ([[[deptDataArray objectAtIndex:indexPath.section]objectForKey:@"PXH"] integerValue]<400)
        {
            for (id obj in [cell subviews])
            {
                if ([obj isKindOfClass:[UILabel class]])
                {
                    [obj removeFromSuperview];
                }
            
            }
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(20, 5, 200, 30)];
            label.backgroundColor = [UIColor clearColor];
            label.text = [[deptDataArray objectAtIndex:indexPath.section] objectForKey:@"ZZQC"];
            [cell addSubview:label];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
        }

        
        return cell;
    }
    else if(tableView.tag == DETAIL_TABLEVIEW_TAG)
    {
        static NSString *detailCellIdentifier = @"AddressCardCell";
        AddressCardCell *cell = [tableView dequeueReusableCellWithIdentifier:detailCellIdentifier];
        if(cell == nil)
        {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"AddressCardCell" owner:nil options:nil] objectAtIndex:0];
       
        }
        NSDictionary *dict = nil;
        if(businessTag == BUSSINESS_SEARCH_TAG)
        {
            dict = [searchResultArray objectAtIndex:indexPath.row];
        }
        else
        {
            dict = [detailDataArray objectAtIndex:indexPath.row];
        }
        
        NSString *name = [[dict objectForKey:kUserMC] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserMC];
        NSString *phone = [[dict objectForKey:kUserSJ] isEqual:[NSNull null]] || [[dict objectForKey:kUserSJ] isEqualToString:@"null"] ? @"" : [dict objectForKey:kUserSJ];
        NSString *tel = [[dict objectForKey:kUserDH] isEqualToString:@"null"] ? @"" : [dict objectForKey:kUserDH];
        NSString *zw = [[dict objectForKey:kUserZW] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserZW];
        cell.nameTitle.text = name;
        cell.zwLabel.text = zw;
        cell.mobileLabel.text = phone;
        cell.telLabel.text = tel;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    NSString *deptStr = [[deptDataArray objectAtIndex:indexPath.section] objectForKey:@"ZZBH"];
    if(tableView.tag == DEPARTMENT_TABLEVIEW_TAG)
    {
        businessTag = BUSSINESS_NORMAL_TAG;
        titleLabel.text = [[deptDataArray objectAtIndex:indexPath.section] objectForKey:@"ZZQC"];
        //判断当前的部门是否有下级部门
        BOOL ret = [usersHelper hasSubDept:deptStr];
        
        if(ret && !self.isSpecial)
        {
            parentButton.hidden = NO;
            [deptDataArray removeAllObjects];
            NSMutableDictionary *jcdaDic = [[NSMutableDictionary alloc]init];
            [jcdaDic setObject:@"监察大队" forKey:@"ZZQC"];
            [jcdaDic setObject:deptStr forKey:@"ZZBH"];
            self.isSpecial = YES;
            
            [deptDataArray addObject:jcdaDic];
            [deptDataArray addObjectsFromArray:[usersHelper queryAllSubDept:deptStr]];
            
            [deptTableView reloadData];
            
            index = index + 1;
        }
        else
        {
            //parentButton.hidden = YES;
            [detailDataArray removeAllObjects];
            [detailDataArray addObjectsFromArray:[usersHelper queryAllUsers:deptStr]];
            [detailTableView reloadData];
        }
        [parentButton addTarget:self action:@selector(returnBack:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - 搜索

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self doSearch:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    businessTag = BUSSINESS_NORMAL_TAG;
    [detailTableView reloadData];
    [searchBar resignFirstResponder];
}

- (void)doSearch:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
    
    if(searchResultArray == nil)
    {
        searchResultArray = [[NSMutableArray alloc] init];
    }
    [searchResultArray removeAllObjects];
    
    
    for (NSDictionary *dict in [usersHelper queryAllUsers])
    {
        NSString *name = [[dict objectForKey:kUserMC] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserMC];
        NSString *phone = [[dict objectForKey:kUserSJ] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserSJ];
        NSString *tel = [[dict objectForKey:kUserDH] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserDH];
        NSString *zw = [[dict objectForKey:kUserZW] isEqual:[NSNull null]] ? @"" : [dict objectForKey:kUserZW];
        
        
        NSString *Valuetext = [NSString stringWithFormat:@"%@_%@_%@_%@",name,phone,tel,zw];
        
        NSRange resRange = [Valuetext rangeOfString:searchBar.text];
        
        
        if(resRange.location != NSNotFound)
        {
            [searchResultArray addObject:dict];
        }
        
        businessTag = BUSSINESS_SEARCH_TAG;
        [detailTableView reloadData];
    }
    
}

- (void)returnBack:(id)sender
{
    self.isSpecial = NO;
    
    index = index - 1;
    if (index == 0)
    {
        parentButton.hidden = YES;
    }
    
    [deptDataArray removeAllObjects];
    [deptDataArray addObjectsFromArray:[usersHelper queryAllRootDept]];
    [deptTableView reloadData];
    
    [detailDataArray removeAllObjects];
    [detailTableView reloadData];
}

@end
