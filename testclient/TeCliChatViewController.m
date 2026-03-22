#import "TeCliChatViewController.h"
#import "MatrixMessage.h"

@interface TeCliChatViewController ()
@property (nonatomic, strong) MatrixClient *client;
@property (nonatomic, strong) MatrixRoom *room;
@property (nonatomic, strong) NSArray *messages;
@end

@implementation TeCliChatViewController

- (instancetype)initWithClient:(MatrixClient *)client room:(MatrixRoom *)room {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _client = client;
        _room = room;
        _messages = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _room.name ?: _room.canonicalAlias ?: _room.roomID;
    [self loadMessages];
}

- (void)loadMessages {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    [spinner startAnimating];

    [_client messagesForRoomID:_room.roomID from:_room.paginationToken limit:50 completion:^(NSArray *messages, NSString *end, NSError *error) {
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

        _messages = [[messages reverseObjectEnumerator] allObjects];
        _room.paginationToken = end;
        [self.tableView reloadData];
        if (_messages.count > 0) {
            NSIndexPath *last = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatrixMessage *msg = _messages[indexPath.row];
    CGSize size = [msg.body sizeWithFont:[UIFont systemFontOfSize:14]
                       constrainedToSize:CGSizeMake(self.view.bounds.size.width - 16, CGFLOAT_MAX)
                           lineBreakMode:NSLineBreakByWordWrapping];
    return MAX(54, size.height + 30);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"MessageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    MatrixMessage *msg = _messages[indexPath.row];
    cell.textLabel.text = msg.body;
    cell.detailTextLabel.text = msg.senderID;
    return cell;
}

// todo: sending messages

@end