//
//  pathSelectionViewController.m
//  ImageManager
//
//  Created by li peng on 13-5-3.
//  Copyright (c) 2013年 li peng. All rights reserved.
//

#import "FolderSelectionViewController.h"
#import "UINavigationBar+Ext.h"
#import "FileManager.h"

@interface FolderSelectionViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dirArray;
@property (nonatomic, copy) NSString *basePath;
@end

@implementation FolderSelectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil basePath:(NSString *)path
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.basePath = path;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.basePath = [FileManager rootPath];
    }
    return self;
}

- (void)initData
{
    self.dirArray = [FileManager subPathOfPath:_basePath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];

    [self initData];
    _tableView.tableFooterView = [[UIView alloc] init];
}

- (IBAction)selectDone
{
    [self selectPath:_basePath];
}

- (void)backToParentFolder
{
    self.basePath = [_basePath stringByDeletingLastPathComponent];
    [self initData];
    [_tableView reloadData];
    
    if ([_basePath isEqualToString:[FileManager rootPath]]) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        [self.navigationController.navigationBar setBackButtonTitle:[_basePath lastPathComponent] target:self action:@selector(backToParentFolder)];
    }
}

- (void)selectPath:(NSString *)path
{
    if (_delegate && [_delegate respondsToSelector:@selector(pathSelected:)]) {
        [_delegate pathSelected:path];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table View Data Source Methods

- (UITableViewCell *)tableView:(UITableView *)varTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [varTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.textLabel.text = _dirArray[indexPath.row];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dirArray count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    NSString *path = [_basePath stringByAppendingPathComponent:_dirArray[indexPath.row]];
//    if ([[FileManager subPathOfPath:path] count] == 0) {
//        [self selectPath:path];
//        return;
//    }
//    NSLog(@"%s %@", __func__, path);
//    FolderSelectionViewController *viewController = [[FolderSelectionViewController alloc] initWithNibName:@"FolderSelectionViewController" bundle:nil basePath:path];
//    viewController.delegate = _delegate;
//    [self.navigationController pushViewController:viewController animated:YES];

    NSString *path = [_basePath stringByAppendingPathComponent:_dirArray[indexPath.row]];
    if ([FileManager isDirPath:path] == NO) {
        NSLog(@"%s Click on a file.", __func__);
        return;
    }

    [self.navigationController.navigationBar setBackButtonTitle:_dirArray[indexPath.row] target:self action:@selector(backToParentFolder)];
    self.basePath = path;
    [self initData];
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
