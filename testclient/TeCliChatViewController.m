#import "TeCliChatViewController.h"
#import "MatrixMessage.h"
#import "MatrixSyncResponse.h"

@interface TeCliChatViewController ()
@property (nonatomic, strong) MatrixClient *client;
@property (nonatomic, strong) MatrixRoom *room;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, assign) CGFloat inputBarBottom;
@end

@implementation TeCliChatViewController

- (instancetype)initWithClient:(MatrixClient *)client room:(MatrixRoom *)room {
    self = [super init];
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
    self.view.backgroundColor = [UIColor whiteColor];

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50, 0);
    [self.view addSubview:_tableView];

    CGFloat w = self.view.bounds.size.width;
    _inputBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, w, 50)];
    _inputBar.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    _inputBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 1)];
    topBorder.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    topBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_inputBar addSubview:topBorder];

    _inputField = [[UITextField alloc] initWithFrame:CGRectMake(8, 8, w - 76, 34)];
    _inputField.borderStyle = UITextBorderStyleRoundedRect;
    _inputField.placeholder = @"Message";
    _inputField.returnKeyType = UIReturnKeySend;
    _inputField.delegate = self;
    _inputField.font = [UIFont systemFontOfSize:15];
    _inputField.backgroundColor = [UIColor whiteColor];
    _inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_inputBar addSubview:_inputField];

    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendBtn.frame = CGRectMake(w - 66, 8, 58, 34);
    sendBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [sendBtn addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [_inputBar addSubview:sendBtn];

    [self.view addSubview:_inputBar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [_tableView addGestureRecognizer:tap];

    [self loadMessages];
    [self startLiveSync];
}

- (void)loadMessages {
    [_client messagesForRoomID:_room.roomID from:nil limit:50 completion:^(NSArray *messages, NSString *end, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                       message:error.localizedDescription
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
            return;
        }
        _messages = [[messages reverseObjectEnumerator] allObjects];
        [_tableView reloadData];
        [self scrollToBottom:NO];
    }];
}

- (void)scrollToBottom:(BOOL)animated {
    if (_messages.count == 0) return;
    NSIndexPath *last = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
    [_tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)startLiveSync {
    [_client startSyncWithBlock:^(MatrixSyncResponse *response, NSError *error) {
        if (error) return;
        NSArray *newMessages = response.messagesByRoomID[_room.roomID];
        if (!newMessages.count) return;
        NSMutableArray *updated = [_messages mutableCopy];
        for (MatrixMessage *msg in newMessages) {
            BOOL found = NO;
            for (MatrixMessage *existing in _messages) {
                if ([existing.eventID isEqualToString:msg.eventID]) { found = YES; break; }
            }
            if (!found) [updated addObject:msg];
        }
        _messages = [updated copy];
        [_tableView reloadData];
        [self scrollToBottom:YES];
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatrixMessage *msg = _messages[indexPath.row];
    CGSize size = [msg.body sizeWithFont:[UIFont systemFontOfSize:15]
                       constrainedToSize:CGSizeMake(self.view.bounds.size.width - 24, CGFLOAT_MAX)
                           lineBreakMode:NSLineBreakByWordWrapping];
    return size.height + 36;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"MsgCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    MatrixMessage *msg = _messages[indexPath.row];
    BOOL isOwn = [msg.senderID isEqualToString:_client.userID];
    cell.textLabel.text = msg.body;
    cell.textLabel.textAlignment = isOwn ? NSTextAlignmentRight : NSTextAlignmentLeft;
    cell.textLabel.textColor = isOwn ? [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0] : [UIColor blackColor];
    cell.detailTextLabel.text = isOwn ? @"You" : msg.senderID;
    cell.detailTextLabel.textAlignment = isOwn ? NSTextAlignmentRight : NSTextAlignmentLeft;
    return cell;
}

#pragma mark - Input

- (void)sendTapped {
    NSString *text = [_inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!text.length) return;
    _inputField.text = @"";
    _inputField.enabled = NO;
    [_client sendTextMessage:text toRoomID:_room.roomID completion:^(NSError *error) {
        _inputField.enabled = YES;
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                       message:error.localizedDescription
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendTapped];
    return NO;
}

- (void)dismissKeyboard {
    [_inputField resignFirstResponder];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGFloat kbHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat viewH = self.view.bounds.size.height;

    [UIView animateWithDuration:duration animations:^{
        _inputBar.frame = CGRectMake(0, viewH - kbHeight - 50, self.view.bounds.size.width, 50);
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, kbHeight + 50, 0);
        _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, kbHeight + 50, 0);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat viewH = self.view.bounds.size.height;

    [UIView animateWithDuration:duration animations:^{
        _inputBar.frame = CGRectMake(0, viewH - 50, self.view.bounds.size.width, 50);
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
        _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50, 0);
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_client stopSync];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end