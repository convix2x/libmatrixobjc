// MatrixRoom.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>

@interface MatrixRoom : NSObject

@property (nonatomic, copy, readonly) NSString *roomID;
@property (nonatomic, copy) NSString *name;          
@property (nonatomic, copy) NSString *topic;         
@property (nonatomic, copy) NSString *avatarURL;     
@property (nonatomic, copy) NSString *canonicalAlias; // e.g. #general:matrix.org
@property (nonatomic, copy) NSString *paginationToken;

- (instancetype)initWithRoomID:(NSString *)roomID;
- (void)applyStateEvent:(NSDictionary *)event;

@end