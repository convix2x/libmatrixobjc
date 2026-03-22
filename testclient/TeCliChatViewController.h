#import <UIKit/UIKit.h>
#import "MatrixClient.h"
#import "MatrixRoom.h"

@interface TeCliChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

- (instancetype)initWithClient:(MatrixClient *)client room:(MatrixRoom *)room;

@end