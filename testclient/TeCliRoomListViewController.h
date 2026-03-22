#import <UIKit/UIKit.h>
#import "MatrixClient.h"

@interface TeCliRoomListViewController : UITableViewController

- (instancetype)initWithClient:(MatrixClient *)client;

@end