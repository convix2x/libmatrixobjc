#import "TeCliRoomListViewController.h"
#import "MatrixRoom.h"
#import "MatrixSyncResponse.h"
#import "TeCliChatViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TeCliRoomListViewController ()
@property (nonatomic, strong) MatrixClient *client;
@property (nonatomic, strong) NSArray *rooms;
@end

@implementation TeCliRoomListViewController

- (instancetype)initWithClient:(MatrixClient *)client {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _client = client;
        _rooms = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Rooms";
    [self loadRooms];
}

- (void)loadRooms {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    [spinner startAnimating];

    [_client syncWithCompletion:^(MatrixSyncResponse *response, NSError *error) {
        [spinner stopAnimating];
        self.navigationItem.rightBarButtonItem = nil;

        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                       message:error.localizedDescription
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
            return;
        }

        _rooms = [response.joinedRooms allValues];
        [_client profileForUserID:_client.userID completion:^(MatrixUser *user, NSError *error) {
            if (error) { NSLog(@"Profile error: %@", error); return; }
            NSLog(@"Display name: %@, avatar: %@", user.displayName, user.avatarURL);
            if (!user.avatarURL) return;
            
            [_client avatarDataForMXCURL:user.avatarURL completion:^(NSData *data, NSString *mimeType, NSError *err) {
                if (err) { NSLog(@"Avatar error: %@", err); return; }
                UIImage *img = [UIImage imageWithData:data];
                if (!img) { NSLog(@"Couldn't decode image"); return; }
                NSLog(@"Got avatar! %@ bytes, mime: %@", @(data.length), mimeType);
                // show in navbar 
                UIImageView *iv = [[UIImageView alloc] initWithImage:img];
                iv.frame = CGRectMake(0, 0, 32, 32);
                iv.layer.cornerRadius = 16;
                iv.clipsToBounds = YES;
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:iv];
            }];
        }];
        [self.tableView reloadData];
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _rooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"RoomCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    MatrixRoom *room = _rooms[indexPath.row];
    cell.textLabel.text = room.name ?: room.canonicalAlias ?: room.roomID;
    cell.detailTextLabel.text = room.topic;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MatrixRoom *room = _rooms[indexPath.row];
    TeCliChatViewController *chat = [[TeCliChatViewController alloc] initWithClient:_client room:room];
    [self.navigationController pushViewController:chat animated:YES];
}

@end