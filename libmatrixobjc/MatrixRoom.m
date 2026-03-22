#import "MatrixRoom.h"

@implementation MatrixRoom

- (instancetype)initWithRoomID:(NSString *)roomID {
    self = [super init];
    if (self) {
        _roomID = [roomID copy];
    }
    return self;
}

- (void)applyStateEvent:(NSDictionary *)event {
    NSString *type = event[@"type"];
    NSDictionary *content = event[@"content"];

    if ([type isEqualToString:@"m.room.name"]) {
        self.name = content[@"name"];
    } else if ([type isEqualToString:@"m.room.topic"]) {
        self.topic = content[@"topic"];
    } else if ([type isEqualToString:@"m.room.avatar"]) {
        self.avatarURL = content[@"url"];
    } else if ([type isEqualToString:@"m.room.canonical_alias"]) {
        self.canonicalAlias = content[@"alias"];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MatrixRoom %@ (%@)>", _roomID, _name ?: _canonicalAlias ?: @"unnamed"];
}

@end