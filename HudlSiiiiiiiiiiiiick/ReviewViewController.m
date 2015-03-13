//
//  SecondViewController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "ReviewViewController.h"
#import "AppDelegate.h"
#import "SharedStats.h"
#import "FileHelper.h"
#import "Maths.h"
#import "KMMedia.h"
#import "Utilities.h"

@import MediaPlayer;

@interface ReviewViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) FileHelper *fileHelper;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSMutableArray *arrFiles;

@property (nonatomic, strong) NSString *selectedFile;
@property (nonatomic) NSInteger selectedRow;

@property (nonatomic, copy) NSMutableDictionary *xfers;
@property (nonatomic, copy) NSMutableArray *xferIndex;

@property (nonatomic, strong) NSMutableArray *combineFilesArray;

-(NSArray *)getAllDocDirFiles;

-(void)didStartReceivingResourceWithNotification:(NSNotification *)notification;
-(void)updateReceivingProgressWithNotification:(NSNotification *)notification;
-(void)didFinishReceivingResourceWithNotification:(NSNotification *)notification;
@end

@implementation ReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.combineFilesArray = [[NSMutableArray alloc] init];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _fileHelper = [[FileHelper alloc] initWithDirectory:@"review"];
    _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateReceivingProgressWithNotification:)
                                                 name:@"MCReceivingProgressNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didStartReceivingResourceWithNotification:)
                                                 name:@"didStartReceivingResourceNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishReceivingResourceWithNotification:)
                                                 name:@"didFinishReceivingResourceNotification"
                                               object:nil];

    [_tblFiles setDelegate:self];
    [_tblFiles setDataSource:self];
    [_tblFiles reloadData];

    _xfers = [[NSMutableDictionary alloc] init];
    _xferIndex = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray *)getAllDocDirFiles{
    return [_fileHelper getFilesByModificationDate];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (_xferIndex.count > 0) {
        return 2;
    }
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0 && _xferIndex.count > 0) {
        return _xferIndex.count;
    }
    return _arrFiles.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    NSError *attributesError = nil;
    NSLog(@"Index Path Section: %ld Row: %ld", (long)indexPath.section, (long)indexPath.row);
    if ( (indexPath.section == 1 && _xferIndex.count > 0) || (indexPath.section == 0 && _xferIndex.count == 0)) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"normalCellIdentifier"];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"normalCellIdentifier"];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }

        NSString *fileName = [_arrFiles objectAtIndex:indexPath.row];
        NSString *odk = @"O";
        if ([fileName rangeOfString:@"Defense"].location != NSNotFound) {
            odk = @"D";
        }
        if ([fileName rangeOfString:@"Kicking"].location != NSNotFound) {
            odk = @"K";
        }

        [(UILabel *)[cell viewWithTag:100] setText:fileName];
        [(UILabel *)[cell viewWithTag:200] setText:odk];
        [(UILabel *)[cell viewWithTag:300] setText:[_fileHelper getFileSize:fileName]];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"newCellIdentifier"];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"newCellIdentifier"];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }

        if (_arrFiles.count > indexPath.row) {
            NSString *key = [_xferIndex objectAtIndex:indexPath.row];
            NSDictionary *dict = [_xfers objectForKey:key];
            NSString *receivedFilename = [dict objectForKey:@"resourceName"];
            NSString *peerDisplayName = [[dict objectForKey:@"peerID"] displayName];
            NSProgress *progress = [dict objectForKey:@"progress"];

            [(UILabel *)[cell viewWithTag:100] setText:receivedFilename];
            [(UILabel *)[cell viewWithTag:200] setText:[NSString stringWithFormat:@"coming from '%@'", peerDisplayName]];
            [(UIProgressView *)[cell viewWithTag:300] setProgress:progress.fractionCompleted];
            [(UILabel *)[cell viewWithTag:400] setText:[_fileHelper getFileSize:receivedFilename]];
        }
    }

    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ((indexPath.section == 1 && _xferIndex.count > 0) || (indexPath.section == 0 && _xferIndex.count == 0)) {
        return 60.0;
    }
    else {
        return 80.0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.combineFilesArray addObject:self.arrFiles[indexPath.row]];
    NSString *currentFileName = [_arrFiles[indexPath.row] lastPathComponent];
    NSString *documentsDirectoryPath = [Utilities applicationSupportDirectory];
    NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:currentFileName];

    if (indexPath.row == 0) {
        //Play the movie now
            NSURL *videoURL =[NSURL fileURLWithPath:filePath];
            MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
            videoPlayerView.moviePlayer.fullscreen=TRUE;
        
            [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
            [videoPlayerView.moviePlayer play];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [(UILabel *)[cell viewWithTag:400] setText:@"🔴"];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.combineFilesArray removeObject:self.arrFiles[indexPath.row]];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [(UILabel *)[cell viewWithTag:400] setText:@"⚪️"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSString *sendingMessage = [NSString stringWithFormat:@"%@ - Sending %.f%%",
                                _selectedFile,
                                [(NSProgress *)object fractionCompleted] * 100
                                ];

    [_arrFiles replaceObjectAtIndex:_selectedRow withObject:sendingMessage];

    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void)didStartReceivingResourceWithNotification:(NSNotification *)notification{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];

    [dict setObject:[NSNumber numberWithDouble:interval] forKey:@"startTime"];
    [dict setObject:dict[@"progress"] forKey:@"progress"];

    [_xfers setObject:dict forKey:dict[@"resourceName"]];
    [_xferIndex addObject:dict[@"resourceName"]];

    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)didFinishReceivingResourceWithNotification:(NSNotification *)notification{
    NSDictionary *dict = [notification userInfo];

    NSURL *localURL = [dict objectForKey:@"localURL"];
    NSString *resourceName = [dict objectForKey:@"resourceName"];

    NSString *destinationPath = [[_fileHelper getStorageLocation] stringByAppendingPathComponent:resourceName];
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager copyItemAtURL:localURL toURL:destinationURL error:&error];

    if (error) {
        NSLog(@"ERR: %@", [error localizedDescription]);
    }

    NSError *sendDataError;
    NSString *ackCmd = [NSString stringWithFormat:@"got-file:%@", resourceName];
    NSArray *peer = @[dict[@"peerID"]];
    [_appDelegate.mcManager.session sendData:[ackCmd dataUsingEncoding:NSUTF8StringEncoding] toPeers:peer withMode:MCSessionSendDataReliable error:&sendDataError];

    dispatch_async(dispatch_get_main_queue(), ^{
        // log the xfer time
        NSMutableDictionary *xferDict = [_xfers objectForKey:resourceName];
        NSNumber *start = [xferDict objectForKey:@"startTime"];
        NSNumber *now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        NSNumber *delta = [NSNumber numberWithDouble:[now doubleValue] - [start doubleValue]];

        NSNumber *filesize = [_fileHelper getFileSizeRaw:resourceName];
        NSNumber *quality;
        if([destinationPath containsString:@"high-"]) {
            quality = [NSNumber numberWithInt:2];
        } else if([destinationPath containsString:@"medium-"]) {
            quality = [NSNumber numberWithInt:1];
        } else {
            quality = [NSNumber numberWithInt:0];
        }

        [[SharedStats instance] logVideoTransfer:quality withSize:filesize withDuration:delta];
        [_xfers removeObjectForKey:resourceName];
        [_xferIndex removeObject:dict[@"resourceName"]];
        [_arrFiles removeAllObjects];
        _arrFiles = nil;
        _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];
        [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        
        [self updateStats];

        if (_xferIndex.count == 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    });
}


-(void)updateStats
{
    SharedStats *stats = [SharedStats instance];
    NSNumber *lowMbps = [Maths calcMbps:stats.avgLowQualityVideoSize duration:stats.avgLowQualityVideoTransferTime];
    NSNumber *medMbps = [Maths calcMbps:stats.avgMedQualityVideoSize duration:stats.avgMedQualityVideoTransferTime];
    NSNumber *highMbps = [Maths calcMbps:stats.avgHighQualityVideoSize duration:stats.avgHighQualityVideoTransferTime];

    _lblPendingXfers.text = [NSString stringWithFormat:@"Pending Xfers: %lu", (unsigned long)_xfers.count];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.roundingIncrement = [NSNumber numberWithDouble:0.01];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;

    _lblLowAvgTime.text = [NSString stringWithFormat:@"Avg Low: %@MBps", [formatter stringFromNumber:lowMbps]];
    _lblMedAvgTime.text = [NSString stringWithFormat:@"Avg Med: %@MBps", [formatter stringFromNumber:medMbps]];
    _lblHighAvgTime.text = [NSString stringWithFormat:@"Avg High: %@MBps", [formatter stringFromNumber:highMbps]];
}

-(void)updateReceivingProgressWithNotification:(NSNotification *)notification{
    @try {
        // one of these lines blows up and I'm too damn lazy to figure it out right now...
        NSProgress *newProgress = [[notification userInfo] objectForKey:@"progress"];

        NSMutableDictionary *xferDict = [_xfers objectForKey:[[notification userInfo] objectForKey:@"resourceName"]];
        [xferDict setObject:newProgress forKey:@"progress"];
        [_xfers setObject:xferDict forKey:[[notification userInfo] objectForKey:@"resourceName"]];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    }

    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(IBAction)btnClearTapped:(id)sender
{
    [_fileHelper removeFiles];

    SharedStats *_stats = [SharedStats instance];
    [_stats reset];
    [_arrFiles removeAllObjects];
    _arrFiles = nil;
    _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];
    [_tblFiles reloadData];
}

- (IBAction)btnCombineTapped:(UIButton *)sender {
    [sender setTitle:@"Combining files..." forState:UIControlStateNormal];
    __block NSDate *beginDate = [NSDate date];
    
    NSError *error;
    NSString *docDir = [Utilities applicationSupportDirectory];
    NSMutableArray *finalContent = [[NSMutableArray alloc] init];
    NSArray *docDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDir error:&error];
    for (NSString *secondDocDir in docDirContent) {
        NSString *secondFullDir = [NSString stringWithFormat:@"%@/%@", docDir, secondDocDir];
        NSArray *secondDocDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:secondFullDir error:&error];
        for (NSString *finalDocDir in secondDocDirContent) {
            NSArray *finalDocDirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", secondFullDir, finalDocDir] error:&error];
            for (NSString *halfPath in finalDocDirContent) {
                NSString *fullPath = [NSString stringWithFormat:@"%@/%@/%@", secondFullDir, finalDocDir, halfPath];
                [finalContent addObject:fullPath];
            }
        }
    }
    
    if (!error) {
        NSArray *fileList = [finalContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ts'"]];
        __block NSUInteger fileCount = fileList.count;
        
        if (fileCount > 0) {
            NSMutableArray *assetList = [NSMutableArray arrayWithCapacity:fileCount];
            for (NSString *fileName in fileList) {
                NSURL *fileURL = [NSURL fileURLWithPath:fileName];
                [assetList addObject:[KMMediaAsset assetWithURL:fileURL withFormat:KMMediaFormatTS]];
            }
            
            NSURL *mp4URL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Result.mp4", docDir]];
            KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4URL withFormat:KMMediaFormatMP4];
            
            KMMediaAssetExportSession *exportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:assetList];
            exportSession.outputAssets = @[mp4Asset];
            
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                if (exportSession.status == KMMediaAssetExportSessionStatusCompleted) {
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:beginDate toDate:[NSDate date] options:0];
                    [sender setTitle:[NSString stringWithFormat:@"Export %lu chunks completed in %ld:%ld",(unsigned long) fileCount,(long) components.minute,(long) components.second]  forState:UIControlStateNormal];
                    [self.tblFiles reloadData];
                } else {
                    [sender setTitle:[NSString stringWithFormat:@"Export failed: %@", exportSession.error] forState:UIControlStateNormal];
                }
            }];
        } else {
            [sender setTitle:@"No files found" forState:UIControlStateNormal];
        }
    } else {
        [sender setTitle:[NSString stringWithFormat:@"Cannot retrieve files: %@", error.localizedDescription] forState:UIControlStateNormal];
    }
}

@end
