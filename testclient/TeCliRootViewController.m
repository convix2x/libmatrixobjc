#import "TeCliRootViewController.h"
#import "TeCliRoomListViewController.h"
#import <MatrixClient.h>

@interface TeCliRootViewController ()
@property (nonatomic, strong) UITextField *homeserverField;
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation TeCliRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Log In";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupFields];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)setupFields {
    CGFloat width = self.view.bounds.size.width - 40;
    CGFloat x = 20;

    _homeserverField = [self textFieldWithPlaceholder:@"Homeserver" y:100 width:width x:x secure:NO];
    _homeserverField.text = @"https://matrix.org";
    _homeserverField.keyboardType = UIKeyboardTypeURL;
    _homeserverField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    _usernameField = [self textFieldWithPlaceholder:@"Username" y:160 width:width x:x secure:NO];
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    _passwordField = [self textFieldWithPlaceholder:@"Password" y:220 width:width x:x secure:YES];

    _loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _loginButton.frame = CGRectMake(x, 290, width, 44);
    [_loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loginButton];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = CGPointMake(self.view.bounds.size.width / 2, 350);
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder y:(CGFloat)y width:(CGFloat)width x:(CGFloat)x secure:(BOOL)secure {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(x, y, width, 44)];
    field.placeholder = placeholder;
    field.secureTextEntry = secure;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.returnKeyType = UIReturnKeyNext;
    [self.view addSubview:field];
    return field;
}

- (void)loginTapped {
    NSString *homeserver = _homeserverField.text;
    NSString *username   = _usernameField.text;
    NSString *password   = _passwordField.text;

    if (!homeserver.length || !username.length || !password.length) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:@"All fields are required."
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil] show];
        return;
    }

    [_spinner startAnimating];
    _loginButton.enabled = NO;

    MatrixClient *client = [[MatrixClient alloc] initWithHomeserver:homeserver];
    [client loginWithUsername:username password:password completion:^(NSString *accessToken, NSString *userID, NSError *error) {
        [_spinner stopAnimating];
        _loginButton.enabled = YES;

        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                       message:error.localizedDescription
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
            return;
        }

        NSLog(@"Logged in as %@", userID);
		TeCliRoomListViewController *rooms = [[TeCliRoomListViewController alloc] initWithClient:client];
		[self.navigationController pushViewController:rooms animated:YES];
    }];
}

@end