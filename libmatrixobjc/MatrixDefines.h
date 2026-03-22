// MatrixDefines.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>

extern NSString *const MatrixErrorDomain;

typedef NS_ENUM(NSInteger, MatrixErrorCode) {
    MatrixErrorUnknown             = -1,
    MatrixErrorNetwork             = 1,
    MatrixErrorInvalidResponse     = 2,
    MatrixErrorForbidden           = 3,  // M_FORBIDDEN
    MatrixErrorUnknownToken        = 4,  // M_UNKNOWN_TOKEN
    MatrixErrorBadJSON             = 5,  // M_BAD_JSON
    MatrixErrorNotFound            = 6,  // M_NOT_FOUND
    MatrixErrorLimitExceeded       = 7,  // M_LIMIT_EXCEEDED
    MatrixErrorGuestAccessForbidden = 8, // M_GUEST_ACCESS_FORBIDDEN
};

typedef void (^MatrixErrorBlock)(NSError *error);
typedef void (^MatrixLoginBlock)(NSString *accessToken, NSString *userID, NSError *error);
typedef void (^MatrixRoomsBlock)(NSArray *rooms, NSError *error);
typedef void (^MatrixMessagesBlock)(NSArray *messages, NSString *end, NSError *error);
typedef void (^MatrixUserBlock)(id user, NSError *error);
typedef void (^MatrixAvatarDataBlock)(NSData *data, NSString *mimeType, NSError *error);
typedef void (^MatrixSyncBlock)(id response, NSError *error);