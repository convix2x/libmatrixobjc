#import "MatrixClient.h"

@interface MatrixClient ()
@property (nonatomic, copy, readwrite) NSString *homeserver;
@property (nonatomic, copy, readwrite) NSString *accessToken;
@property (nonatomic, copy, readwrite) NSString *userID;
@property (nonatomic, assign, readwrite) BOOL isSyncing;
@property (nonatomic, assign) BOOL stopSyncFlag;
@end

@implementation MatrixClient

#pragma mark - Init

- (instancetype)initWithHomeserver:(NSString *)homeserver {
    self = [super init];
    if (self) {
        _homeserver = [homeserver copy];
        _syncTimeout = 30.0;
    }
    return self;
}

- (instancetype)initWithHomeserver:(NSString *)homeserver
                       accessToken:(NSString *)accessToken
                            userID:(NSString *)userID {
    self = [self initWithHomeserver:homeserver];
    if (self) {
        _accessToken = [accessToken copy];
        _userID = [userID copy];
    }
    return self;
}

#pragma mark - Internal helpers

- (NSURL *)urlForPath:(NSString *)path {
    NSString *base = [_homeserver stringByAppendingString:@"/_matrix/client/v3"];
    return [NSURL URLWithString:[base stringByAppendingString:path]];
}

- (NSURL *)urlForPath:(NSString *)path queryParams:(NSDictionary *)params {
    NSMutableString *query = [NSMutableString string];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        if (query.length > 0) [query appendString:@"&"];
        [query appendFormat:@"%@=%@", key,
            [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }];
    NSString *base = [_homeserver stringByAppendingString:@"/_matrix/client/v3"];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?%@", base, path, query]];
}

- (NSMutableURLRequest *)requestForURL:(NSURL *)url method:(NSString *)method body:(NSDictionary *)body {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = method;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (_accessToken) {
        [req setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken]
   forHTTPHeaderField:@"Authorization"];
    }
    if (body) {
        req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    }
    return req;
}

- (NSError *)errorFromResponseData:(NSData *)data httpStatus:(NSInteger)status {
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *errcode = json[@"errcode"] ?: @"M_UNKNOWN";
    NSString *errmsg  = json[@"error"]   ?: @"Unknown error";

    MatrixErrorCode code = MatrixErrorUnknown;
    if ([errcode isEqualToString:@"M_FORBIDDEN"])          code = MatrixErrorForbidden;
    else if ([errcode isEqualToString:@"M_UNKNOWN_TOKEN"]) code = MatrixErrorUnknownToken;
    else if ([errcode isEqualToString:@"M_BAD_JSON"])      code = MatrixErrorBadJSON;
    else if ([errcode isEqualToString:@"M_NOT_FOUND"])     code = MatrixErrorNotFound;
    else if ([errcode isEqualToString:@"M_LIMIT_EXCEEDED"]) code = MatrixErrorLimitExceeded;
    else if ([errcode isEqualToString:@"M_GUEST_ACCESS_FORBIDDEN"]) code = MatrixErrorGuestAccessForbidden;

    return [NSError errorWithDomain:MatrixErrorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: errmsg}];
}

- (void)sendRequest:(NSURLRequest *)req
         completion:(void (^)(NSDictionary *json, NSError *error))completion {
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
        if (connError) {
            completion(nil, [NSError errorWithDomain:MatrixErrorDomain
                                                code:MatrixErrorNetwork
                                            userInfo:@{NSLocalizedDescriptionKey: connError.localizedDescription}]);
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (http.statusCode < 200 || http.statusCode >= 300) {
            completion(nil, [self errorFromResponseData:data httpStatus:http.statusCode]);
            return;
        }
        completion(json, nil);
    }];
}

#pragma mark - Auth

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
               completion:(MatrixLoginBlock)completion {
    NSURL *url = [self urlForPath:@"/login"];
    NSDictionary *body = @{
        @"type": @"m.login.password",
        @"identifier": @{
            @"type": @"m.id.user",
            @"user": username
        },
        @"password": password
    };
    NSMutableURLRequest *req = [self requestForURL:url method:@"POST" body:body];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, nil, error); return; }
        _accessToken = json[@"access_token"];
        _userID = json[@"user_id"];
        completion(_accessToken, _userID, nil);
    }];
}

- (void)logoutWithCompletion:(MatrixErrorBlock)completion {
    NSURL *url = [self urlForPath:@"/logout"];
    NSMutableURLRequest *req = [self requestForURL:url method:@"POST" body:@{}];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

#pragma mark - Rooms

- (void)joinedRoomsWithCompletion:(MatrixRoomsBlock)completion {
    NSURL *url = [self urlForPath:@"/joined_rooms"];
    NSMutableURLRequest *req = [self requestForURL:url method:@"GET" body:nil];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSArray *roomIDs = json[@"joined_rooms"];
        NSMutableArray *rooms = [NSMutableArray array];
        for (NSString *roomID in roomIDs) {
            [rooms addObject:[[MatrixRoom alloc] initWithRoomID:roomID]];
        }
        completion([rooms copy], nil);
    }];
}

#pragma mark - Sync

- (void)syncWithCompletion:(MatrixSyncBlock)completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"timeout"] = [NSString stringWithFormat:@"%d", (int)(_syncTimeout * 1000)];
    if (_syncToken) params[@"since"] = _syncToken;

    NSURL *url = [self urlForPath:@"/sync" queryParams:params];
    NSMutableURLRequest *req = [self requestForURL:url method:@"GET" body:nil];
    req.timeoutInterval = _syncTimeout + 10.0;

    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        MatrixSyncResponse *response = [MatrixSyncResponse syncResponseFromDict:json];
        self.syncToken = response.nextBatch;
        completion(response, nil);
    }];
}

- (void)startSyncWithBlock:(MatrixSyncBlock)block {
    _isSyncing = YES;
    _stopSyncFlag = NO;
    [self _syncLoop:block];
}

- (void)_syncLoop:(MatrixSyncBlock)block {
    if (_stopSyncFlag) {
        _isSyncing = NO;
        return;
    }
    [self syncWithCompletion:^(MatrixSyncResponse *response, NSError *error) {
        block(response, error);
        // let's keep looping even on an error!
        [self _syncLoop:block];
    }];
}

- (void)stopSync {
    _stopSyncFlag = YES;
}

#pragma mark - Messages

- (void)sendTextMessage:(NSString *)text
               toRoomID:(NSString *)roomID
             completion:(MatrixErrorBlock)completion {
    [self sendMessage:text msgtype:@"m.text" toRoomID:roomID completion:completion];
}

- (void)sendEmote:(NSString *)text
         toRoomID:(NSString *)roomID
       completion:(MatrixErrorBlock)completion {
    [self sendMessage:text msgtype:@"m.emote" toRoomID:roomID completion:completion];
}

- (void)sendMessage:(NSString *)text
            msgtype:(NSString *)msgtype
           toRoomID:(NSString *)roomID
         completion:(MatrixErrorBlock)completion {
    // txnID needs to be unique per request, or we'll fucking die.
    NSString *txnID = [[NSUUID UUID] UUIDString];
    NSString *path = [NSString stringWithFormat:@"/rooms/%@/send/m.room.message/%@",
                      [roomID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                      txnID];
    NSURL *url = [self urlForPath:path];
    NSDictionary *body = @{ @"msgtype": msgtype, @"body": text };
    NSMutableURLRequest *req = [self requestForURL:url method:@"PUT" body:body];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

- (void)messagesForRoomID:(NSString *)roomID
                     from:(NSString *)from
                    limit:(NSUInteger)limit
               completion:(MatrixMessagesBlock)completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"dir"] = @"b";
    params[@"limit"] = [NSString stringWithFormat:@"%lu", (unsigned long)limit];
    if (from) params[@"from"] = from;

    NSString *path = [NSString stringWithFormat:@"/rooms/%@/messages",
                      [roomID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [self urlForPath:path queryParams:params];
    NSMutableURLRequest *req = [self requestForURL:url method:@"GET" body:nil];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, nil, error); return; }
        NSArray *chunk = json[@"chunk"];
        NSMutableArray *messages = [NSMutableArray array];
        for (NSDictionary *event in chunk) {
            if ([event[@"type"] isEqualToString:@"m.room.message"]) {
                MatrixMessage *msg = [MatrixMessage messageFromEventDict:event roomID:roomID];
                if (msg) [messages addObject:msg];
            }
        }
        completion([messages copy], json[@"end"], nil);
    }];
}

#pragma mark - Users

- (void)profileForUserID:(NSString *)userID
              completion:(MatrixUserBlock)completion {
    NSString *path = [NSString stringWithFormat:@"/profile/%@",
                      [userID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [self urlForPath:path];
    NSMutableURLRequest *req = [self requestForURL:url method:@"GET" body:nil];
    [self sendRequest:req completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        MatrixUser *user = [[MatrixUser alloc] initWithUserID:userID
                                                  displayName:json[@"displayname"]
                                                    avatarURL:json[@"avatar_url"]];
        completion(user, nil);
    }];
}

- (void)avatarDataForMXCURL:(NSString *)mxcURL
                 completion:(MatrixAvatarDataBlock)completion {
    // mxc://server/mediaID -> /_matrix/media/v3/download/server/mediaID
    NSString *stripped = [mxcURL substringFromIndex:6]; 
    NSString *urlString = [NSString stringWithFormat:@"%@/_matrix/media/v3/download/%@", _homeserver, stripped];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    if (_accessToken) {
        [req setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken]
   forHTTPHeaderField:@"Authorization"];
    }
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connError) {
        if (connError) { completion(nil, nil, connError); return; }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            completion(nil, nil, [self errorFromResponseData:data httpStatus:http.statusCode]);
            return;
        }
        NSString *mimeType = http.MIMEType ?: @"image/jpeg";
        completion(data, mimeType, nil);
    }];
}

@end