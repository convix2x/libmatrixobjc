#import "MatrixSyncResponse.h"

@implementation MatrixSyncResponse

- (instancetype)initWithNextBatch:(NSString *)nextBatch
                      joinedRooms:(NSDictionary *)joinedRooms
              messagesByRoomID:(NSDictionary *)messagesByRoomID {
    self = [super init];
    if (self) {
        _nextBatch = [nextBatch copy];
        _joinedRooms = joinedRooms;
        _messagesByRoomID = messagesByRoomID;
    }
    return self;
}

+ (instancetype)syncResponseFromDict:(NSDictionary *)dict {
    NSString *nextBatch = dict[@"next_batch"];
    NSMutableDictionary *joinedRooms = [NSMutableDictionary dictionary];
    NSMutableDictionary *messagesByRoomID = [NSMutableDictionary dictionary];

    NSDictionary *rooms = dict[@"rooms"];
    NSDictionary *join = rooms[@"join"];

    for (NSString *roomID in join) {
        NSDictionary *roomData = join[roomID];
        MatrixRoom *room = [[MatrixRoom alloc] initWithRoomID:roomID];

        NSArray *stateEvents = roomData[@"state"][@"events"];
        for (NSDictionary *event in stateEvents) {
            [room applyStateEvent:event];
        }

        NSArray *timelineEvents = roomData[@"timeline"][@"events"];
        NSMutableArray *messages = [NSMutableArray array];
        for (NSDictionary *event in timelineEvents) {
            if ([event[@"type"] isEqualToString:@"m.room.message"]) {
                MatrixMessage *msg = [MatrixMessage messageFromEventDict:event roomID:roomID];
                if (msg) [messages addObject:msg];
            } else {
                [room applyStateEvent:event];
            }
        }

        NSString *prevBatch = roomData[@"timeline"][@"prev_batch"];
        if (prevBatch) room.paginationToken = prevBatch;

        joinedRooms[roomID] = room;
        if (messages.count > 0) messagesByRoomID[roomID] = [messages copy];
    }

    return [[self alloc] initWithNextBatch:nextBatch
                               joinedRooms:[joinedRooms copy]
                       messagesByRoomID:[messagesByRoomID copy]];
}

@end