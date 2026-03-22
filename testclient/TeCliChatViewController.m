#import "TeCliChatViewController.h"
#import "MatrixMessage.h"

@interface TeCliChatViewController ()
@property (nonatomic, strong) MatrixClient *client;
@property (nonatomic, strong) MatrixRoom *room;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UITextField *inputField;
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
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(loadMessages) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    [self setupToolbar];
    [self loadMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self.view bringSubviewToFront:_toolbar];
}

- (void)loadMessages {
    [_client messagesForRoomID:_room.roomID from:nil limit:50 completion:^(NSArray *messages, NSString *end, NSError *error) {
        [self.refreshControl endRefreshing];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                       message:error.localizedDescription
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
            return;
        }
        _messages = [[messages reverseObjectEnumerator] allObjects];
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

- (void)setupToolbar {
    _toolbar = (UIToolbar *)[[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44,
                                                            self.view.bounds.size.width, 44)];
    _toolbar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.5)];
    border.backgroundColor = [UIColor lightGrayColor];
    border.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_toolbar addSubview:border];

    _inputField = [[UITextField alloc] initWithFrame:CGRectMake(8, 7, self.view.bounds.size.width - 76, 30)];
    _inputField.borderStyle = UITextBorderStyleRoundedRect;
    _inputField.placeholder = @"Message";
    _inputField.returnKeyType = UIReturnKeySend;
    _inputField.delegate = self;
    _inputField.font = [UIFont systemFontOfSize:14];
    _inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_toolbar addSubview:_inputField];

    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.frame = CGRectMake(self.view.bounds.size.width - 66, 7, 58, 30);
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [_toolbar addSubview:sendButton];

    [self.view addSubview:_toolbar];
    [self.view bringSubviewToFront:_toolbar];

    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 44, 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

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
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self loadMessages];
        });
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendTapped];
    return NO;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration animations:^{
        _toolbar.frame = CGRectMake(0, self.view.bounds.size.height - keyboardHeight - 44,
                                    self.view.bounds.size.width, 44);
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, keyboardHeight + 44, 0);
        self.tableView.contentInset = insets;
        self.tableView.scrollIndicatorInsets = insets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration animations:^{
        _toolbar.frame = CGRectMake(0, self.view.bounds.size.height - 44,
                                    self.view.bounds.size.width, 44);
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 44, 0);
        self.tableView.contentInset = insets;
        self.tableView.scrollIndicatorInsets = insets;
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end