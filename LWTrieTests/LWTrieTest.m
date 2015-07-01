//
//  LWTrieTest.m
//  LWTrie
//
//  Created by ldwong on 2/23/15.
//  Copyright (c) 2015 linus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "LWTrie.h"

@interface LWTrieTest : XCTestCase
@property (strong, nonatomic) LWTrie *trie;
@end

@implementation LWTrieTest

- (void)setUp {
    [super setUp];
    self.trie = [[LWTrie alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInsert {
    [_trie insert:@"hi" value:@1];
    [_trie insert:@"howdy" value:@2];
    [_trie insert:@"how" value:@3];
    [_trie insert:@"howard" value:@4];
    [_trie insert:@"hola" value:@5];

    [_trie stats];

    NSString *w;
    NSNumber *result;
    w = @"hi";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @1, @"'%@' differs", w);
    w = @"howdy";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @2, @"'%@' differs", w);
    w = @"how";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @3, @"'%@' differs", w);
    w = @"howard";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @4, @"'%@' differs", w);
    w = @"hola";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @5, @"'%@' differs", w);
    result = [_trie find:@"howd"];
    XCTAssertNil(result, @"'howd' not nil");
    result = [_trie find:@"ho"];
    XCTAssertNil(result, @"'ho' not nil");
}

- (void)testRemove {
    [_trie insert:@"hi" value:@1];
    [_trie insert:@"howdy" value:@2];
    [_trie insert:@"how" value:@3];
    [_trie insert:@"howard" value:@4];
    [_trie insert:@"hola" value:@5];
    [_trie stats];

    // Now remove the values one by one in reverse.

    NSNumber *result;
    NSString *w = @"hola";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @5, @"'%@' differs", w);
    [_trie remove:w];
    result = [_trie find:w];
    XCTAssertNil(result, @"'%@' not nil", w);
    [_trie stats];

    w = @"howard";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @4, @"'%@' differs", w);
    [_trie remove:w];
    result = [_trie find:w];
    XCTAssertNil(result, @"'%@' not nil", w);
    [_trie stats];

    w = @"how";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @3, @"'%@' differs", w);
    [_trie remove:w];
    result = [_trie find:w];
    XCTAssertNil(result, @"'%@' not nil", w);
    [_trie stats];

    w = @"howdy";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @2, @"'%@' differs", w);
    [_trie remove:w];
    result = [_trie find:w];
    XCTAssertNil(result, @"'%@' not nil", w);
    [_trie stats];

    w = @"hi";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @1, @"'%@' differs", w);
    [_trie remove:w];
    result = [_trie find:w];
    XCTAssertNil(result, @"'%@' not nil", w);
    [_trie stats];

    result = [_trie find:@"h"];
    XCTAssertNil(result, @"'h' not nil");
}

- (void)testArchiveAndUnArchive {
    [_trie insert:@"hi" value:@1];
    [_trie insert:@"howdy" value:@2];
    [_trie insert:@"how" value:@3];
    [_trie insert:@"howard" value:@4];
    [_trie insert:@"hola" value:@5];

    [_trie stats];

    // Archive then unarchive.
    NSString *triePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testArchiveAndUnArchive"];
    [NSKeyedArchiver archiveRootObject:_trie toFile:triePath];
    _trie = [NSKeyedUnarchiver unarchiveObjectWithFile:triePath];
    XCTAssertNotNil(_trie);
    NSLog(@"Path: %@", triePath);

    NSString *w;
    NSNumber *result;
    w = @"hi";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @1, @"'%@' differs", w);
    w = @"howdy";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @2, @"'%@' differs", w);
    w = @"how";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @3, @"'%@' differs", w);
    w = @"howard";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @4, @"'%@' differs", w);
    w = @"hola";
    result = [_trie find:w];
    XCTAssertEqualObjects(result, @5, @"'%@' differs", w);
    result = [_trie find:@"howd"];
    XCTAssertNil(result, @"'howd' not nil");
    result = [_trie find:@"ho"];
    XCTAssertNil(result, @"'ho' not nil");
}

- (void)testvaluesWithPrefix{
    [_trie insert:@"hi" value:@1];
    [_trie insert:@"howdy" value:@2];
    [_trie insert:@"how" value:@3];
    [_trie insert:@"howard" value:@4];
    [_trie insert:@"howards" value:@5];
    [_trie insert:@"hola" value:@6];

    [_trie stats];

    NSString *str = @"how";

    NSArray *valuelist = [_trie valuesWithPrefix:str];

    NSLog(@"%lu nodes in array", [valuelist count]);

    XCTAssertEqual([valuelist count], 4);
    XCTAssertTrue([valuelist containsObject:@2]);
    XCTAssertTrue([valuelist containsObject:@3]);
    XCTAssertTrue([valuelist containsObject:@4]);
    XCTAssertTrue([valuelist containsObject:@5]);

    XCTAssertFalse([valuelist containsObject:@1]);
    XCTAssertFalse([valuelist containsObject:@6]);
}

# pragma mark - utilities

- (void)writeBinaryPlist:(NSDictionary *)dict path:(NSString *)path {
    NSError *err = nil;
    NSData *plist;
    NSFileManager *manager;
    BOOL ret;

    manager = [NSFileManager defaultManager];

    plist = [NSPropertyListSerialization dataWithPropertyList:dict
                                                       format:NSPropertyListBinaryFormat_v1_0
                                                      options:0
                                                        error:&err];
    if(plist == nil) {
        NSLog(@"NSPropertyListSerialization error: %@", err);
    }
    ret = [manager createFileAtPath:path contents:plist attributes:nil];
    if(ret == NO) {
        NSLog(@"Create failed");
    }

}
@end
