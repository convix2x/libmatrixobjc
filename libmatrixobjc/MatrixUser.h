// MatrixUser.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>

@interface MatrixUser : NSObject

@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *avatarURL; // mxc:// uri, might be nil

- (instancetype)initWithUserID:(NSString *)userID;
- (instancetype)initWithUserID:(NSString *)userID
                   displayName:(NSString *)displayName
                     avatarURL:(NSString *)avatarURL;

@end