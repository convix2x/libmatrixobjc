#import <UIKit/UIKit.h>
#import "MatrixClient.h"
#import "MatrixRoom.h"

@interface TeCliChatViewController : UITableViewController

- (instancetype)initWithClient:(MatrixClient *)client room:(MatrixRoom *)room;

@end