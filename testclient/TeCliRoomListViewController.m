#import "TeCliRoomListViewController.h"
#import "MatrixRoom.h"
#import "MatrixSyncResponse.h"

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
    // todo: add chat
}

@end