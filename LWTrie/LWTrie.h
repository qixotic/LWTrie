//
//  LWTrie.h
//  LWTrie
//
//  Created by ldwong on 2/23/15.
//  Copyright (c) 2015 linus. All rights reserved.
//

#import <Foundation/Foundation.h>

/// An implementation of a patricia trie that supports words from an arbitrary character set.
@interface LWTrie : NSObject <NSCoding>

- (id)init;

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

/**
 * Returns the values of a node with a given prefix and all descendants
 */
- (NSArray *)valuesWithPrefix:(NSString *)prefix;
@end
