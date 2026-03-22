// MatrixSyncResponse.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>
#import "MatrixRoom.h"
#import "MatrixMessage.h"

@interface MatrixSyncResponse : NSObject

@property (nonatomic, copy, readonly) NSString *nextBatch;
@property (nonatomic, strong, readonly) NSDictionary *joinedRooms;
@property (nonatomic, strong, readonly) NSDictionary *messagesByRoomID;

- (instancetype)initWithNextBatch:(NSString *)nextBatch
                      joinedRooms:(NSDictionary *)joinedRooms
              messagesByRoomID:(NSDictionary *)messagesByRoomID;

+ (instancetype)syncResponseFromDict:(NSDictionary *)dict;

@end