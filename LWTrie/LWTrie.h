//
//  LWTrie.h
//  LWTrie
//
//  Created by ldwong on 2/23/15.
//  Copyright (c) 2015 linus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LWTrie : NSObject <NSCoding>

- (id)init;
- (id)initWithCapacity:(NSInteger)capacity;

/**
 * Maps this word to the given object, replacing any previous value if present.
 */
- (void)insert:(NSString *)word value:(id)object;

/**
 * Removes the word and its associated value from the trie if present.
 */
- (void)remove:(NSString *)word;

/**
 * @return the value associated with the word, or nil.
 */
- (id)find:(NSString *)word;

/// Dump some stats info to the console.
- (void)stats;
@end
