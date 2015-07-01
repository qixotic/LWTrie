//
//  LWTrie.m
//  LWTrie
//
//  Created by ldwong on 2/23/15.
//  Copyright (c) 2015 linus. All rights reserved.
//


#import "LWTrie.h"
#import <objc/runtime.h>


/**
 * Internal node structure of our trie.
 */
@interface LWTrieNode : NSObject <NSCoding> {
@public
    /**
     * The string of characters that terminate at this node. In a regular trie, each character would
     * correspond to a separate node, with a single pointer in 'children' pointing to the next node.
     */
    NSString *prefix;
    /**
     * The value associated with the word formed by concatenating the prefixes from the root to this
     * node. 'item' may be nil!
     */
    id item;
    LWTrieNode *parent;
}
/**
 * Our dictionary of children nodes maps a single character key to a child node. This lets us use
 * an arbitrary character set for the words in our trie. It is lazily instantiated on first access.
 */
@property (nonatomic, strong) NSMutableDictionary *children;
@end


@implementation LWTrieNode

- (id)initWithPrefix:(NSString *)myPrefix value:(id)myValue parent:(LWTrieNode *)myParent {
    self = [super init];
    if (self) {
        prefix = myPrefix;
        item = myValue;
        parent = myParent;
    }
    return self;
}


- (BOOL)hasChildren {
    return _children != nil && _children.count > 0;
}

- (NSMutableDictionary *)children {
    if (_children == nil) {
        _children = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return _children;
}

- (LWTrieNode *)getChildForKey:(NSNumber *)ch {
    return _children == nil ? nil : [self.children objectForKey:ch];
}

// Splits the current node's prefix in two, creating a new child node that takes ownership of the
// current children, old value, and the suffix of this split.  Returns the new node.
- (LWTrieNode *)splitNodeAt:(NSInteger)startIndex {
    NSString *newNodePrefix = [prefix substringFromIndex:startIndex];
    LWTrieNode *newNode = [[LWTrieNode alloc] initWithPrefix:newNodePrefix value:item parent:self];
    // Adopt this node's children.
    [newNode setChildren:_children];
    // Fix this node's entries.
    prefix = [prefix substringToIndex:startIndex];
    item = nil;
    _children = nil;
    // Insert the new node as a child.
    [self.children setObject:newNode forKey:@([newNodePrefix characterAtIndex:0])];

    return newNode;
}

// Helper function for inserts.
- (LWTrieNode *)insertChild:(NSString *)word startingAt:(NSInteger)startIndex value:(id)value {
    // Get child with first char and insert into that node
    NSNumber *key = @([word characterAtIndex:startIndex]);
    LWTrieNode *child = [self getChildForKey:key];
    if (child == nil) {
        // Whole new node, so just store the entire thing in it.
        child = [[LWTrieNode alloc] initWithPrefix:(startIndex == 0 ?
                                                    word :
                                                    [word substringFromIndex:startIndex])
                                             value:value
                                            parent:self];
        [self.children setObject:child forKey:key];
    } else {
        // Otherwise, we insert into this existing child node.
        // Note: could actually start at startIndex+1 since the child should share the first char
        //       with word[startIndex], but the insert impl must reflect that assumption, too.
        [child insert:word startingAt:startIndex value:value];
    }
    return child;
}

- (LWTrieNode *)insert:(NSString *)word startingAt:(NSInteger)startIndex value:(id)newValue {
    LWTrieNode *returnNode = nil;
    BOOL subsumedByPrefix = YES;
    NSInteger prefixLength = prefix != nil ? prefix.length : 0;

    for (NSInteger wordIndex = startIndex, prefixIndex = 0;
         wordIndex < word.length;
         ++wordIndex, ++prefixIndex) {
        if (prefixIndex < prefixLength) {
            // Check for a common prefix and keep it growing if so.
            unichar c = [word characterAtIndex:wordIndex];
            unichar this_c = [prefix characterAtIndex:prefixIndex];
            if (c != this_c) {
                subsumedByPrefix = NO;
                // Break prefix at this index, creating a new node, adopting the prefix's suffix,
                // old value, and children. Insert it as a new child of this node.
                [self splitNodeAt:prefixIndex];
                // Lastly, insert word's suffix and newValue into another new child.
                returnNode = [self insertChild:word startingAt:wordIndex value:newValue];
                break;
            }
        } else {
            // Word is longer. Insert word suffix as a child.
            subsumedByPrefix = NO;
            returnNode = [self insertChild:word startingAt:wordIndex value:newValue];
            break;
        }
    }
    if (subsumedByPrefix) {
        // Value belongs in this node. set|replace it after fixing the current state...
        NSInteger wordLengthFromStart = word.length - startIndex;
        if (prefixLength > wordLengthFromStart) {
            // Break prefix at the word length.
            [self splitNodeAt:wordLengthFromStart];
        } else if (item != nil) {
            NSLog(@"Duplicate key: %@ has old value: %@ replaced with: %@", word, item, newValue);
        }
        // Now set|replace with the new below.
        item = newValue;
        returnNode = self;
    } // else it was already handled in the for loop.
    return returnNode;
}

- (LWTrieNode *)find:(NSString *)word startingAt:(NSInteger)startIndex {
    // See if word subsumes the prefix. If not => not in tree.
    NSInteger prefixLength = prefix != nil ? prefix.length : 0;
    // word can't be in the tree if the prefix is longer than the suffix of word we're inserting.
    if (prefixLength > word.length - startIndex) return nil;

    for (NSInteger wordIndex = startIndex, prefixIndex = 0;
         wordIndex < word.length;
         ++wordIndex, ++prefixIndex) {
        if (prefixIndex < prefixLength) {
            // Check for a common prefix and keep it growing if so.
            unichar c = [word characterAtIndex:wordIndex];
            unichar this_c = [prefix characterAtIndex:prefixIndex];
            if (c != this_c) return nil;
        } else {
            // Word is longer. Check children for remainder of word.
            LWTrieNode *child = [self getChildForKey:@([word characterAtIndex:wordIndex])];
            return (child == nil) ? nil : [child find:word startingAt:wordIndex];
        }
    }
    // Prefix is the same length as the word here, and we didn't find differences.
    return self;
}

// Removes the item in this node, and potentially compacts itself.
- (void)remove {
    item = nil;
    // now clean up this node if there are no children, possibly compacting the parent as well.
    if (!_children || _children.count == 0) {
        if (parent) {
            [parent.children removeObjectForKey:@([prefix characterAtIndex:0])];
            [parent maybeCompactWithChild];
            // Now self should autorelease.
        }
    } else {  // may still be able to compact with a lone child.
        [self maybeCompactWithChild];
    }
}

// If there's no item in this node, and only one child, we can combine with the child.
- (void)maybeCompactWithChild {
    if (!_children || _children.count != 1 || item != nil) return;

    // collapse this node w/ its child. Parent stays the same.
    id key = [[_children keyEnumerator] nextObject];
    LWTrieNode *child = [_children objectForKey:key];
    [_children removeObjectForKey:key];
    // Adopt the child's contents.
    prefix = [prefix stringByAppendingString:child->prefix];
    item = child->item;
    _children = child->_children;
    // Now it's safe to release the child.
    //        child->_children = nil;
    //        child->parent = nil;
    //        child->item = nil;
    //        child->prefix = nil;
}

- (unsigned long)numChildren {
    return _children ? _children.count : 0;
}

#pragma mark - NSCoding protocol

// NSCoding keys
#define kPrefix     @"1"
#define kItem       @"2"
#define kParent     @"3"
#define kChildren   @"4"

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (prefix != nil) {
        [aCoder encodeObject:prefix forKey:kPrefix];
    }
    if (item != nil && [item conformsToProtocol:@protocol(NSCoding)]) {
        [aCoder encodeObject:item forKey:kItem];
    }
    if (parent != nil) {
        [aCoder encodeObject:parent forKey:kParent];
    }
    if (_children != nil) {
        [aCoder encodeObject:_children forKey:kChildren];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        prefix = [aDecoder decodeObjectForKey:kPrefix];
        item = [aDecoder decodeObjectForKey:kItem];
        parent = [aDecoder decodeObjectForKey:kParent];
        _children = [aDecoder decodeObjectForKey:kChildren];
    }
    return self;
}

@end


#pragma mark - LWTrie

@interface LWTrie ()

@property (strong) LWTrieNode *root;
@property (strong) NSDictionary *idIndex;

@end


@implementation LWTrie

- (id)init {
    if (self = [super init]) {
        self.root = [[LWTrieNode alloc] initWithPrefix:@"" value:nil parent:nil];
    }
    return self;
}

- (void)insert:(NSString *)word value:(id)object {
    LWTrieNode *node = self.root;
    [node insertChild:word startingAt:0 value:object];
}

- (void)remove:(NSString *)word {
    LWTrieNode *node = [self.root find:word startingAt:0];
    if (node) [node remove];
}

- (id)find:(NSString *)word {
    LWTrieNode *node = [self.root find:word startingAt:0];
    return (node && node->item != nil) ? node->item : nil;
}

#define TOTAL @(-1)
- (void)stats {
    NSMutableDictionary *stats = [[NSMutableDictionary alloc] init];
    stats[TOTAL] = @1;

    if ([_root hasChildren]) {
        stats[@(_root.children.count)] = @1;

        for (id c in _root.children) {
            LWTrieNode *node = [_root getChildForKey:c];
            [self statsInternal:stats forNode:node];
        }
    }

    for (NSNumber *k in [[stats allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        if ([k intValue] == -1) continue;
        NSLog(@"Stats key: %@ ->\t %@", k, stats[k]);
    }
    NSLog(@"Stats # NODES: %@", stats[TOTAL]);
}

- (void)statsInternal:(NSMutableDictionary *)stats forNode:(LWTrieNode *)node {
    // Add to the total # of nodes
    NSInteger total = [stats[TOTAL] integerValue];
    stats[TOTAL] = @(total + 1);

    // Add to the histogram of node children sizes
    NSInteger numChildren = [node hasChildren] ? node.children.count : 0;
    NSInteger bucketCount = [stats[@(numChildren)] integerValue];
    stats[@(numChildren)] = @(bucketCount + 1);

    if ([node hasChildren]) {
        for (id c in node.children) {
            LWTrieNode *childNode = [node getChildForKey:c];
            [self statsInternal:stats forNode:childNode];
        }
    }
}

#pragma mark - NSCoding protocol

#define kRoot @"r"
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_root forKey:kRoot];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        _root = [aDecoder decodeObjectForKey:kRoot];
    }
    return self;
}

@end
