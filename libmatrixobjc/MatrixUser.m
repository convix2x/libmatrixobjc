#import "MatrixUser.h"

@implementation MatrixUser

- (instancetype)initWithUserID:(NSString *)userID {
    return [self initWithUserID:userID displayName:nil avatarURL:nil];
}

- (instancetype)initWithUserID:(NSString *)userID
                   displayName:(NSString *)displayName
                     avatarURL:(NSString *)avatarURL {
    self = [super init];
    if (self) {
        _userID = [userID copy];
        _displayName = [displayName copy];
        _avatarURL = [avatarURL copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MatrixUser %@ (%@)>", _userID, _displayName ?: @"no displayname"];
}

@end