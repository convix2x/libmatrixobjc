// MatrixMessage.h
// libmatrixobjc
// Licensed under the GNU Lesser General Public License v2.1, see LICENSE in
// the repo root for details.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MatrixMessageType) {
    MatrixMessageTypeText,    // m.text
    MatrixMessageTypeEmote,   // m.emote
    MatrixMessageTypeNotice,  // m.notice
    MatrixMessageTypeUnknown,
};

@interface MatrixMessage : NSObject

@property (nonatomic, copy, readonly) NSString *eventID;
@property (nonatomic, copy, readonly) NSString *senderID;
@property (nonatomic, copy, readonly) NSString *roomID;
@property (nonatomic, copy, readonly) NSString *body;
@property (nonatomic, assign, readonly) MatrixMessageType type;
@property (nonatomic, assign, readonly) long long originServerTS; // ms
@property (nonatomic, strong, readonly) NSDate *date;

- (instancetype)initWithEventID:(NSString *)eventID
                       senderID:(NSString *)senderID
                         roomID:(NSString *)roomID
                           body:(NSString *)body
                           type:(MatrixMessageType)type
                 originServerTS:(long long)originServerTS;

+ (instancetype)messageFromEventDict:(NSDictionary *)dict roomID:(NSString *)roomID;

@end