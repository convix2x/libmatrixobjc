// MatrixClient.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>
#import "MatrixDefines.h"
#import "MatrixRoom.h"
#import "MatrixMessage.h"
#import "MatrixUser.h"
#import "MatrixSyncResponse.h"

typedef void (^MatrixErrorBlock)(NSError *error);
typedef void (^MatrixLoginBlock)(NSString *accessToken, NSString *userID, NSError *error);
typedef void (^MatrixRoomsBlock)(NSArray *rooms, NSError *error);
typedef void (^MatrixMessagesBlock)(NSArray *messages, NSString *end, NSError *error);
typedef void (^MatrixUserBlock)(MatrixUser *user, NSError *error);
typedef void (^MatrixAvatarDataBlock)(NSData *data, NSString *mimeType, NSError *error);
typedef void (^MatrixSyncBlock)(MatrixSyncResponse *response, NSError *error);

@interface MatrixClient : NSObject

@property (nonatomic, copy, readonly) NSString *homeserver;
@property (nonatomic, copy, readonly) NSString *accessToken;
@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy) NSString *syncToken;
@property (nonatomic, assign) NSTimeInterval syncTimeout; // default 30s because matrix likes long sync times :)
@property (nonatomic, assign, readonly) BOOL isSyncing;

- (instancetype)initWithHomeserver:(NSString *)homeserver;
- (instancetype)initWithHomeserver:(NSString *)homeserver
                       accessToken:(NSString *)accessToken
                            userID:(NSString *)userID;

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
               completion:(MatrixLoginBlock)completion;
- (void)logoutWithCompletion:(MatrixErrorBlock)completion;

- (void)joinedRoomsWithCompletion:(MatrixRoomsBlock)completion;

- (void)syncWithCompletion:(MatrixSyncBlock)completion;
- (void)startSyncWithBlock:(MatrixSyncBlock)block;
- (void)stopSync;

- (void)sendTextMessage:(NSString *)text
               toRoomID:(NSString *)roomID
             completion:(MatrixErrorBlock)completion;
- (void)sendEmote:(NSString *)text
         toRoomID:(NSString *)roomID
       completion:(MatrixErrorBlock)completion;
- (void)messagesForRoomID:(NSString *)roomID
                     from:(NSString *)from
                    limit:(NSUInteger)limit
               completion:(MatrixMessagesBlock)completion;

- (void)profileForUserID:(NSString *)userID
              completion:(MatrixUserBlock)completion;
- (void)avatarDataForMXCURL:(NSString *)mxcURL
                 completion:(MatrixAvatarDataBlock)completion;

@end