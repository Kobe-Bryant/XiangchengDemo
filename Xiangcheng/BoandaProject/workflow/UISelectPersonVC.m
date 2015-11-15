//
//  UISelectPersonVC.m
//  HNYDZF
//
//  Created by zhang on 12-12-13.
//
//

#import "UISelectPersonVC.h"
#import "QQSectionHeaderView.h"
#import "QQList.h"
#import "UITableViewCell+Custom.h"

@interface UISelectPersonVC ()<QQSectionHeaderViewDelegate>
@property(nonatomic,strong)UISegmentedControl *segCtrl;
@property(nonatomic,strong) NSMutableArray * arySelUsrs;
@property(nonatomic,strong) NSMutableArray * lists;
@property(nonatomic,strong) NSMutableArray * titleArray;
@property(nonatomic,assign) NSInteger saveSegSelect;
@end

@implementation UISelectPersonVC
@synthesize segCtrl,aryWorkflowUsrs,multiUsr,toSelPersonType,delegate,arySelUsrs;
@synthesize departUserModel,myTableView,tableDataType,saveSegSelect;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)segCtrlValueChanged:(id)sender{
    if(segCtrl.selectedSegmentIndex == 0){
        tableDataType = kTableData_WorkflowUsrs;
    }else{
        tableDataType = kTableData_Depart;
        if(departUserModel == nil)
        {
            self.departUserModel = [[DepartUsersDataModel alloc] initWithTarget:self andParentView:self.view];
            [departUserModel requestDepartUsers];
        }
        else if (!departUserModel.aryDeparts.count){
            [departUserModel requestDepartUsers];
        }
    }
    [myTableView reloadData];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake( 320, 480);
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(okBtnPressed:)];
    self.navigationItem.rightBarButtonItem = barItem;

    tableDataType = kTableData_WorkflowUsrs;
    
    if(toSelPersonType != kPersonType_Master)
    {
 
        UISegmentedControl *aSegCtrl =[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"默认人员",@"通讯录", nil]];
        // aSegCtrl.frame = CGRectMake(10, 10, 180, 40);
        aSegCtrl.selectedSegmentIndex = self.saveSegSelect;
        aSegCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.segCtrl = aSegCtrl;
        [segCtrl addTarget:self action:@selector(segCtrlValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:self.segCtrl];
        
        self.navigationItem.titleView = segCtrl;
    }
    if (self.lists == nil) {
        self.lists = [[NSMutableArray alloc]init];
    }
    if (arySelUsrs == nil) {
        self.arySelUsrs = [NSMutableArray arrayWithCapacity:3];
    }
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(toSelPersonType == kPersonType_Master)
    {
        segCtrl.hidden= YES;
    }else{
        segCtrl.hidden = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    
    if(departUserModel)
        [departUserModel cancelRequest];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)okBtnPressed:(id)sender{
    [delegate returnSelectedPersons:arySelUsrs andPersonType:toSelPersonType];
    
}

-(void)setAryWorkflowUsrs:(NSArray *)ary{
    aryWorkflowUsrs = [ary copy];
    
}

-(void)departsDataReceived:(NSArray*)aryDeparts{
    if (self.lists.count) {
        [self.lists removeAllObjects];
    }
    for (int i = 0; i < [aryDeparts count]; i++) {
        NSDictionary *dataDic = [aryDeparts objectAtIndex:i];
        QQList *list = [[QQList alloc] init];
        list.m_nID = i; //  分组依据
        list.m_strGroupName =  [dataDic objectForKey:@"deptName"];
        list.m_arrayPersons = [[NSMutableArray alloc] init];
        list.opened = NO;
        list.indexPaths = [[NSMutableArray alloc] init];
        [self.lists addObject:list];
    }
    [myTableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if(tableDataType == kTableData_Depart){
        return self.lists.count;
    }
    else{
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(tableDataType == kTableData_Depart){
        QQList *persons = [self.lists objectAtIndex:section];
        if (persons.opened) {
           return [persons.m_arrayPersons count]; // 人员数 
        }
        else{
            return 0;
        }
    }
    else
        return [aryWorkflowUsrs count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    NSDictionary *usrsDic = nil;
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    if(tableDataType == kTableData_Depart){
        QQList *header= [self.lists objectAtIndex:indexPath.section];
        QQPerson *person = [header.m_arrayPersons objectAtIndex:indexPath.row];
        usrsDic = person.m_dataDic;
        cell.textLabel.text = person.m_strPersonName;
    }
    else{
        usrsDic = [aryWorkflowUsrs objectAtIndex:indexPath.row];
        cell.textLabel.text = [usrsDic objectForKey:@"userName"];
    }
    if(arySelUsrs){
        if([arySelUsrs containsObject:usrsDic]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(tableDataType == kTableData_Depart){
        QQList *persons = [self.lists objectAtIndex:section];
        QQSectionHeaderView *sectionHeadView = [[QQSectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.myTableView.bounds.size.width, 44)title:persons.m_strGroupName section:section opened:persons.opened delegate:self];
        [sectionHeadView setBackgroundWithPortrait:@"cellBG_type1.png" andLandscape:@"cellBG_type1.png"];
        return sectionHeadView ;
    }
    else{
        return nil ;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(tableDataType == kTableData_Depart){
        return 44;
    }
    else{
        return 0;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row%2 == 0)
        cell.backgroundColor = LIGHT_BLUE_UICOLOR;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *usrsDic  = nil;
    if (tableDataType == kTableData_Depart) {
        QQList *list = [self.lists objectAtIndex:indexPath.section];
        QQPerson *person = [list.m_arrayPersons objectAtIndex:indexPath.row];
        usrsDic = person.m_dataDic;
    }
    else{
        usrsDic  = [aryWorkflowUsrs objectAtIndex:indexPath.row];
    }
    
    if(toSelPersonType == kPersonType_Master && multiUsr == NO){
        [arySelUsrs removeAllObjects];
        [arySelUsrs addObject:usrsDic];
    }
    else{
        if([arySelUsrs containsObject:usrsDic]){
            [arySelUsrs removeObject:usrsDic];
        }
        else{
            [arySelUsrs addObject:usrsDic];
        }
    }
    [tableView reloadData];
}

-(void)sectionHeaderView:(QQSectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)section{
    QQList *list = [self.lists objectAtIndex:section];
	list.opened = !list.opened;
	NSDictionary *dicSelDepart = [departUserModel.aryDeparts objectAtIndex:section];
    NSArray *valueArray = [dicSelDepart objectForKey:@"users"];
    if (!list.m_arrayPersons.count) {
        for (int j = 0; j < [valueArray count]; j++)
        {
            NSDictionary *dataDic = [valueArray objectAtIndex:j];
            QQPerson *person = [[QQPerson alloc] init];
            person.m_nListID = section; //  分组依据
            person.m_dataDic = dataDic;
            person.m_strPersonName = [dataDic objectForKey:@"userName"];
            [list.m_arrayPersons addObject:person];
            [list.indexPaths addObject:[NSIndexPath indexPathForRow:j inSection:section]];
        }
    }
	// 展开+动画 (如果不需要动画直接reloaddata)
    if ([list.m_arrayPersons count] > 0)
    {
		[self.myTableView insertRowsAtIndexPaths:list.indexPaths withRowAnimation:UITableViewRowAnimationBottom];
	}
}

-(void)sectionHeaderView:(QQSectionHeaderView *)sectionHeaderView sectionClosed:(NSInteger)section{
    QQList *list = [self.lists objectAtIndex:section];
    list.opened = !list.opened;
	
	// 收缩+动画 (如果不需要动画直接reloaddata)
	NSInteger countOfRowsToDelete = [self.myTableView numberOfRowsInSection:section];
    if (countOfRowsToDelete > 0)
    {
		
        [self.myTableView deleteRowsAtIndexPaths:list.indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

@end
