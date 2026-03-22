#import "MatrixMessage.h"

@implementation MatrixMessage

- (instancetype)initWithEventID:(NSString *)eventID
                       senderID:(NSString *)senderID
                         roomID:(NSString *)roomID
                           body:(NSString *)body
                           type:(MatrixMessageType)type
                 originServerTS:(long long)originServerTS {
    self = [super init];
    if (self) {
        _eventID = [eventID copy];
        _senderID = [senderID copy];
        _roomID = [roomID copy];
        _body = [body copy];
        _type = type;
        _originServerTS = originServerTS;
    }
    return self;
}

+ (instancetype)messageFromEventDict:(NSDictionary *)dict roomID:(NSString *)roomID {
    NSString *eventID = dict[@"event_id"];
    NSString *senderID = dict[@"sender"];
    long long ts = [dict[@"origin_server_ts"] longLongValue];

    NSDictionary *content = dict[@"content"];
    NSString *body = content[@"body"];
    NSString *msgtype = content[@"msgtype"];

    MatrixMessageType type = MatrixMessageTypeUnknown;
    if ([msgtype isEqualToString:@"m.text"])        type = MatrixMessageTypeText;
    else if ([msgtype isEqualToString:@"m.emote"])  type = MatrixMessageTypeEmote;
    else if ([msgtype isEqualToString:@"m.notice"]) type = MatrixMessageTypeNotice;

    return [[self alloc] initWithEventID:eventID
                                senderID:senderID
                                  roomID:roomID
                                    body:body
                                    type:type
                          originServerTS:ts]; // scary typescript
}

- (NSDate *)date {
    return [NSDate dateWithTimeIntervalSince1970:_originServerTS / 1000.0];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MatrixMessage %@ from %@: %@>", _eventID, _senderID, _body];
}

@end