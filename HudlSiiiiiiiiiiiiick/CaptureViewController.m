//
//  FirstViewController.m
//  HudlSiiiiiiiiiiiiick
//
//  Created by Jared Barboza on 2/18/15.
//  Copyright (c) 2015 Jared Barboza. All rights reserved.
//

#import "CaptureViewController.h"
#import "AppDelegate.h"
#import "FileHelper.h"
#import "VideoCaptureController.h"
#import "FragmentedVideoCaptureController.h"

@interface CaptureViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) FileHelper *fileHelper;
@property (nonatomic, strong) NSMutableArray *arrFiles;

@property (nonatomic, strong) NSString *selectedFile;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) NSString *selectedPlayType;

@property (nonatomic, copy) NSArray *playTypes;

@property (nonatomic, copy) NSMutableDictionary *xfers;

@property (nonatomic) BOOL useBuiltInCapture;
@property (nonatomic) int transfersInProgress;

-(NSArray *)getAllDocDirFiles;

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _fileHelper = [[FileHelper alloc] initWithDirectory:@"capture"];
    [_tblFiles setDelegate:self];
    [_tblFiles setDataSource:self];
    [_pckPlayType setDataSource:self];
    [_pckPlayType setDelegate:self];

    _playTypes = @[ @"Offense", @"Defense", @"Kicking" ];
    _selectedPlayType = @"Offense";

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onClientACKFileReceived:)
                                                 name:@"clientACKFileReceived"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoDoneGotCaptured:)
                                                 name:@"videoisready"
                                               object:nil];

    _useBuiltInCapture = NO;

    UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [_tblFiles addGestureRecognizer:longPressRecognizer];
    _transfersInProgress = 0;
    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refresh {
    _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];
    [_tblFiles reloadData];
}

- (IBAction)captureVideo:(id)sender {
    if (_useBuiltInCapture && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;

        if(_appDelegate.videoQuality != [NSNumber numberWithInt:1])
        {
            int qual = [_appDelegate.videoQuality intValue];
            switch(qual)
            {
                case 0:
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                    break;
                case 2:
                    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                    break;
                default:
                    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                    break;
            }
        }

        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];

        [self presentViewController:picker animated:YES completion:NULL];
    } else {
        UIStoryboard *storyboard = self.storyboard;
        // VideoCaptureController *vc = [storyboard instantiateViewControllerWithIdentifier:@"VideoCaptureBoard"];
        FragmentedVideoCaptureController *vc = [storyboard instantiateViewControllerWithIdentifier:@"FragmentedVideoCaptureBoard"];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

-(void)onLongPress:(UILongPressGestureRecognizer*)pGesture
{
    if (pGesture.state == UIGestureRecognizerStateRecognized)
    {
        //Do something to tell the user!
    }
    if (pGesture.state == UIGestureRecognizerStateEnded)
    {
        CGPoint touchPoint = [pGesture locationInView:_tblFiles];
        NSIndexPath* row = [_tblFiles indexPathForRowAtPoint:touchPoint];
        if (row != nil) {
            //Handle the long press on row
            NSString *fileName = _arrFiles[row.row];
            NSArray *peers = _appDelegate.mcManager.session.connectedPeers;
            if (peers != nil && peers.count > 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending Video"
                                                                message:[NSString stringWithFormat:@"Sending %@", fileName]
                                                               delegate:self
                                                      cancelButtonTitle:@"WORD 👊"
                                                      otherButtonTitles:nil];
                [alert show];
                [self sendVideo:fileName];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Peers"
                                                                message:@"You're not connected to anyone!"
                                                               delegate:self
                                                      cancelButtonTitle:@"awww 😿"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];

    self.videoURL = info[UIImagePickerControllerMediaURL];

    NSData *videoData = [NSData dataWithContentsOfURL:self.videoURL];

    [self dismissViewControllerAnimated:YES completion:nil] ;

    NSString *root = [_fileHelper getStorageLocation];
    NSString *fileName = [_fileHelper getNewFileName:@"TEST"];
    NSString *path = [NSString stringWithFormat:@"%@/%@", root, fileName];

    [videoData writeToFile:path atomically:NO];

    [self refresh];

    NSLog(@"Wrote to %@", path);

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Shipping the bits. url: %@    filename: %@", path, fileName);
        [self sendVideo:fileName];
    });
}

-(void)sendVideo:(NSString *)fileName
{
    NSString *path = [NSString stringWithFormat:@"%@/%@", [_fileHelper getStorageLocation], fileName];
    NSURL *resourceURL = [NSURL fileURLWithPath:path];
    NSInteger peerCount = [[_appDelegate.mcManager.session connectedPeers] count];

    NSMutableArray *peerCounts = [[NSMutableArray alloc] init];
    [_xfers setObject:peerCounts forKey:fileName];

    NSLog(@"%@", fileName);
    _transfersInProgress++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    for (MCPeerID *peer in [_appDelegate.mcManager.session connectedPeers]) {
        NSLog(@"%@    %@    %ld", fileName, peer.displayName, (long)peerCount);

        [_appDelegate.mcManager.session
         sendResourceAtURL:resourceURL
         withName:fileName
         toPeer:peer
         withCompletionHandler:^(NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", [error localizedDescription]);
             }
             _transfersInProgress--;
             if(_transfersInProgress == 0) {
                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
             }
         }];
    }
}

-(void)onClientACKFileReceived:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    NSString *fileName = dict[@"fileName"];
    NSMutableArray *peerCounts = [_xfers objectForKey:fileName];
    if ([peerCounts isEqual:nil]) {
        peerCounts = [[NSMutableArray alloc] init];
    }

    if (![peerCounts containsObject:dict[@"peerID"]]) {
        [peerCounts addObject:dict[@"peerID"]];
    }

    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (IBAction)removeAllFiles:(id)sender
{
    [_fileHelper removeFiles];
    [self refresh];
}


# pragma mark - Get All Files In Docs
-(NSArray *)getAllDocDirFiles{
    return [_fileHelper getFilesByModificationDate];
}


# pragma mark - Table Shit

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_arrFiles count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdCapturedVideoCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdCapturedVideoCell"];
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
    [(UILabel *)[cell viewWithTag:400] setText:[NSString stringWithFormat:@"%@ / %@", [_fileHelper getFileSize:fileName], [_fileHelper getFileDuration:fileName]]];

    NSString *status = @"";
    NSMutableArray *peerCounts = [_xfers objectForKey:fileName];
    if ([peerCounts isEqual:nil]) {
        // not sent yet
        status = @"U";
    } else if ([[NSNumber numberWithUnsignedInt:peerCounts.count] isEqualToNumber:[NSNumber numberWithInt:[[_appDelegate.mcManager.session connectedPeers] count]]]) {
        // all peers have this file
        status = @"E";
    } else {
        // only some of the peers got this file
        status = @"S";
    }
    [(UILabel *)[cell viewWithTag:300] setText:status];

    [[cell textLabel] setFont:[UIFont systemFontOfSize:14.0]];

    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([[_arrFiles objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
        return 60.0;
    }
    else{
        return 80.0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *currentFileName = [_arrFiles[indexPath.row] lastPathComponent];
    NSString *documentsDirectoryPath = [_fileHelper getStorageLocation];
    NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:currentFileName];

    // [self sendVideo:filePath filename:currentFileName];
    NSURL *videoURL =[NSURL fileURLWithPath:filePath];
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
    videoPlayerView.moviePlayer.fullscreen=TRUE;

    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    [videoPlayerView.moviePlayer play];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)videoDoneGotCaptured:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refresh];
    });

    if (_appDelegate.mcManager.session.connectedPeers.count > 0) {
        NSDictionary *dict = [notification userInfo];

        [self sendVideo:dict[@"resourceName"]];
    }
}

# pragma mark - Picker Stuffs
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _playTypes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _playTypes[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectedPlayType = [_playTypes objectAtIndex:row];

    NSLog(@"Selected Play Type: %@", _selectedPlayType);
}
@end
