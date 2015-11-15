//
//  DisplayAttachFileController.m
//  GuangXiOA
//
//  Created by  on 11-12-27.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "DisplayAttachFileController.h"
#import "FileUtil.h"
#import "ZipFileBrowserController.h"
#import "ShowLocalFileController.h"
#import <Unrar4iOS/Unrar4iOS.h>
#import "ZipArchive.h"
#import "PDFileManager.h"

@interface DisplayAttachFileController()
@property (nonatomic,strong) ASINetworkQueue * networkQueue ;
@property (nonatomic,assign) BOOL showZipFile;
@property (nonatomic,strong) NSArray *aryFiles;
@property (nonatomic,strong) NSString *tmpUnZipDir;//解压缩后的临时目录
@property (nonatomic,strong) UIPopoverController *popVc;
@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic,strong) UITableView *listTableView;
@property (nonatomic,strong) NSString *attachURL;
@property (nonatomic,strong) NSString *attachName;
@property (nonatomic,strong) PDFileManager *fileManager;
@property (nonatomic,strong) NSString *savePath;
@property (nonatomic,assign) NSInteger didTag;

@end

@implementation DisplayAttachFileController

@synthesize webView,progress,labelTip, attachURL,attachName,networkQueue,showZipFile,didTag;
@synthesize aryFiles,tmpUnZipDir,listTableView,savePath;

- (id)initWithNibName:(NSString *)nibNameOrNil fileURL:(NSString *)fileUrl andFileName:(NSString*)fileName
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self)
    {
        self.attachURL = fileUrl;
        self.attachName = fileName;
        showZipFile = NO;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fileManager = [[PDFileManager alloc] init];    
    self.title = attachName;
    if([attachName length])
    {
        [self downloadFile];
    }
}
-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(showZipFile)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (_popVc)
        [_popVc dismissPopoverAnimated:YES];
    [networkQueue cancelAllOperations];
    if (didTag == NO) {
        NSMutableArray *folderKeys = [[NSUserDefaults standardUserDefaults] objectForKey:@"folderKeys"];
        
        if (folderKeys.count > 0 ) {
            
            for (int i = 0;i<folderKeys.count;i++) {
                NSString *string = [folderKeys objectAtIndex:i];
                if ([string isEqualToString:@"默认文件夹"]) {
                    
                    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:string];
                    NSMutableArray *array1 = [[NSMutableArray alloc] initWithArray:array];
                    [array1 addObject:[NSDictionary dictionaryWithObject:self.savePath forKey:attachName]];
                    NSString *key1 = [folderKeys objectAtIndex:i];
                    [[NSUserDefaults standardUserDefaults] setObject:array1 forKey:key1];
                    
                    
                }
            }
        }
    }
    
    [super viewWillDisappear:animated];
}
-(void)downloadFile
{
    //下载文件到默认文件夹
    NSString *docsDir = self.fileManager.defaultFolderPath;
    
    NSFileManager *fm = [NSFileManager defaultManager ];
    BOOL isDir;
    
    NSLog(@"%d",[fm fileExistsAtPath:docsDir isDirectory:&isDir]);
    
    if(![fm fileExistsAtPath:docsDir isDirectory:&isDir])
    {
        [fm createDirectoryAtPath:docsDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *path=[docsDir stringByAppendingPathComponent:attachName];
   
    NSLog(@"path = %@",path);
    
    
    self.savePath = path;
    
    //如果文件存在先删除文件
    if([fm fileExistsAtPath:path])
    {
        [fm removeItemAtPath:path error:nil];
    }
    
    
    
    //////////////////////////// 任务队列 /////////////////////////////
    if(!networkQueue)
    {
        self.networkQueue = [[ASINetworkQueue alloc] init];
    }
    
    [networkQueue reset];// 队列清零
    [networkQueue setShowAccurateProgress:YES]; // 进度精确显示
    [networkQueue setDelegate:self ]; // 设置队列的代理对象
    ASIHTTPRequest *request;
    
  // http://y1.eoews.com/assets/ringtones/2012/5/17/34031/axiddhql6nhaegcofs4hgsjrllrcbrf175oyjuv0.mp3
    
    
    ///////////////// request for file1 //////////////////////
    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:attachURL]]; // 设置文件 1 的 url
    [request setDownloadProgressDelegate:progress]; // 文件 1 的下载进度条
    //设置下载文件存放的路径
    [request setDownloadDestinationPath:path];
    
    [request setCompletionBlock :^( void ){
        self.navigationItem.rightBarButtonItem.enabled = YES;
        // 使用 complete 块，在下载完时做一些事情
        
        NSString *pathExt = [path pathExtension];
        NSLog(@"pathExt = %@",pathExt);

        if([pathExt compare:@"rar" options:NSCaseInsensitiveSearch] == NSOrderedSame || [pathExt compare:@"zip" options:NSCaseInsensitiveSearch] ==NSOrderedSame)
        {
     
            [self handleZipRarFile:path];
            
        }
        else
        {
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 768, 960)];
            webView.scalesPageToFit = YES;
            [self.view addSubview:webView];
            NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
            [webView loadRequest:[NSURLRequest requestWithURL:url]];
            
        }
    }];
    [request setFailedBlock :^( void ){
        // 使用 failed 块，在下载失败时做一些事情
        self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 768, 960)];
        webView.scalesPageToFit = YES;
        [self.view addSubview:webView];
        [webView loadHTMLString:@"下载文件失败！" baseURL:nil];
    }];
    
    
    [ networkQueue addOperation :request];
    [ networkQueue go ]; // 队列任务开始

}

- (void)didSelectedRow:(NSInteger)row
{
    didTag = YES;
    NSMutableArray *folderKeys = [[NSMutableArray alloc] initWithArray:[self.fileManager directoryListAtPath:self.fileManager.basePath]];
    if(folderKeys == nil || folderKeys.count == 0)
    {
        [_popVc dismissPopoverAnimated:YES];
        return;
    }
    NSString *string = [folderKeys objectAtIndex:row];
    NSString *selectedRowPath = [self.fileManager.basePath stringByAppendingPathComponent:string];
    NSString *toPath = toPath = [selectedRowPath stringByAppendingPathComponent:self.attachName];
    NSString *toDefaultPath = [self.fileManager.defaultFolderPath stringByAppendingPathComponent:self.attachName];
    if([toPath isEqualToString:toDefaultPath])
    {
        [_popVc dismissPopoverAnimated:YES];
        return;
    }
    [self.fileManager copyItemFromPath:self.savePath toPath:toPath];
    [self.fileManager removeFileAtPath:self.savePath];
    [_popVc dismissPopoverAnimated:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(void)decompressZipFile:(NSString*)path
{
    ZipArchive *zipper = [[ZipArchive alloc] init];
    [zipper UnzipOpenFile:path];
    [zipper UnzipFileTo:tmpUnZipDir overWrite:YES];
    [zipper UnzipCloseFile];
}

-(void)decompressRarFile:(NSString*)path
{
    Unrar4iOS *unrar = [[Unrar4iOS alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager ];
    BOOL isDir;
    if(![fm fileExistsAtPath:tmpUnZipDir isDirectory:&isDir])
        [fm createDirectoryAtPath:tmpUnZipDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    BOOL ok = [unrar unrarOpenFile:path];
	if (ok)
    {
        [unrar unrarFileTo:tmpUnZipDir overWrite:YES];
        [unrar unrarCloseFile];
    }
}

-(void)handleZipRarFile:(NSString*)path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *dicAttr = [manager attributesOfItemAtPath:path error:nil];
    //拿到文件的总大小
    NSNumber *numSize = [dicAttr objectForKey:NSFileSize];
    
    if([numSize integerValue] > 0)
    {
        self.tmpUnZipDir = [NSTemporaryDirectory()  stringByAppendingPathComponent:[path lastPathComponent]];
        
        NSLog(@"tmpUnZipDir = %@",tmpUnZipDir);
        
        
        NSString *pathExt = [path pathExtension];
        if([pathExt compare:@"rar" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            [self decompressRarFile:path];
        }
        else if([pathExt compare:@"zip" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            [self decompressZipFile:path];
        }
    }
    else
    {
        [webView loadHTMLString:@"下载文件失败" baseURL:nil];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *ary = [NSMutableArray arrayWithCapacity:20];
    NSArray *aryTmp = [fm contentsOfDirectoryAtPath:tmpUnZipDir error:nil];
    [ary addObjectsFromArray:aryTmp];
    [ary removeObject:@".DS_Store"];
    [ary removeObject:@"__MACOSX"];
    self.aryFiles = ary;
    self.listTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 768, 960) style:UITableViewStylePlain];
    listTableView.dataSource = self;
    listTableView.delegate = self;
    [self.view addSubview:listTableView];
    [listTableView reloadData];
}

#pragma mark - UIWebView Delegate Method

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [webView loadHTMLString:@"对不起，您所访问的文件不存在" baseURL:nil];
}

#pragma mark - UITableView Delegate Method

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [aryFiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0];
        cell.textLabel.numberOfLines = 2;
        
        UIView *bgview = [[UIView alloc] initWithFrame:cell.contentView.frame];
        bgview.backgroundColor = [UIColor colorWithRed:0 green:94.0/255 blue:107.0/255 alpha:1.0];
        cell.selectedBackgroundView = bgview;
    }
    NSString *fileName = [aryFiles objectAtIndex:indexPath.row];
    cell.textLabel.text = fileName;
    NSString *path = [NSString stringWithFormat:@"%@/%@",tmpUnZipDir,fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
    NSDictionary *dicAttr = [fm attributesOfItemAtPath:path error:&err];
    if([[dicAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    {
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
    }
    else
    {
        NSString *pathExt = [fileName pathExtension];
        cell.imageView.image = [FileUtil imageForFileExt:pathExt];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [aryFiles objectAtIndex:indexPath.row];
    NSString *path = [NSString stringWithFormat:@"%@/%@",tmpUnZipDir,fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
    NSDictionary *dicAttr = [fm attributesOfItemAtPath:path error:&err];
    if([[dicAttr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    {
        ZipFileBrowserController *detailViewController = [[ZipFileBrowserController alloc] initWithStyle:UITableViewStylePlain andParentDir:path];
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    else
    {
        ShowLocalFileController *detailViewController = [[ShowLocalFileController alloc] initWithNibName:@"ShowLocalFileController" bundle:nil];
        detailViewController.fullPath = path;
        detailViewController.fileName = fileName;
        detailViewController.bCanSendEmail = NO;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}


@end
