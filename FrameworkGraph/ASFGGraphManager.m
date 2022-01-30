//
//  ASFGGraphManager.m
//  FrameworkGraph
//
//  Created by Adair Wang on 2022/1/20.
//

#import "ASFGGraphManager.h"
#import "ASFGGraphData.h"
#import "ASFGNode.h"
#import "ASFGConnection.h"
#import "ASFGPathHelper.h"

#include <mach-o/fat.h>
#include <mach-o/loader.h>

#define LEVEL_GRAPH_BUILD_METHOD 3

@interface ASFGGraphManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, ASFGNode *> *inputNodes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ASFGNode *> *allNodes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<ASFGConnection *> *> *graph;
@property (nonatomic, strong) ASFGGraphData *graphData;

@property (nonatomic, strong) NSMutableSet<NSString *> *hiddenFrameworks;

@property (nonatomic, assign) cpu_type_t preferCPUType;

@end

@implementation ASFGGraphManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _inputNodes = [[NSMutableDictionary alloc] init];
        _allNodes = [[NSMutableDictionary alloc] init];
        _graph = [[NSMutableDictionary alloc] init];
        
        _hiddenFrameworks = [[NSMutableSet alloc] init];
        
#if TARGET_CPU_X86_64
        _preferCPUType = CPU_TYPE_X86_64;
#else
        _preferCPUType = CPU_TYPE_ARM64;
#endif
    }
    return self;
}

- (void)addItems:(NSArray<NSString *> *)itemPaths
{
    [itemPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        [self updateGraphWithItemPath:path];
    }];
    
    [self updateGraphData];
}

- (void)clearItems
{
    [_inputNodes removeAllObjects];
    [_allNodes removeAllObjects];
    [_graph removeAllObjects];
    _graphData = nil;
    
    [_hiddenFrameworks removeAllObjects];
}

- (void)updateHiddenFrameworks:(NSSet<NSString *> *)frameworks
{
    NSMutableSet<NSString *> *hiddenFrameworks = [frameworks mutableCopy];
    
    [_inputNodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull filePath, ASFGNode * _Nonnull node, BOOL * _Nonnull stop) {
        [hiddenFrameworks removeObject:filePath];
    }];
    
    if ([hiddenFrameworks isEqualToSet:_hiddenFrameworks])
    {
        return;
    }
    else
    {
        _hiddenFrameworks = hiddenFrameworks;
    }
    
    [self updateGraphData];
}

- (NSSet<NSString *> *)currentHiddenFrameworks
{
    return _hiddenFrameworks;
}

- (NSSet<NSString *> *)currentInputFrameworks
{
    return [NSSet setWithArray:_inputNodes.allKeys];
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)currentAllFrameworks
{
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *data = [[NSMutableDictionary alloc] init];
    [_allNodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull filePath, ASFGNode * _Nonnull node, BOOL * _Nonnull stop) {
        NSString *dir = [self extractDirWithFilePath:filePath];
        if (data[dir] == nil)
        {
            data[dir] = [[NSMutableArray alloc] init];
        }
        [data[dir] addObject:filePath];
    }];
    [data enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [data[key] sortUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
    }];
    return data;
}

- (void)updateGraphData
{
    // sorted input nodes
    NSArray<ASFGNode *> *sortedInputNodes = [_inputNodes.allValues sortedArrayUsingComparator:^NSComparisonResult(ASFGNode * _Nonnull node1, ASFGNode * _Nonnull node2) {
        return [node1.filePath compare:node2.filePath];
    }];
    
    // filter graph/allNodes
    NSDictionary<NSString *, NSArray<ASFGConnection *> *> *filteredGraph = [self filterGraph];
    NSMutableDictionary<NSString *, ASFGNode *> *filteredallNodes = [[NSMutableDictionary alloc] init];
    [filteredGraph enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull filePath, NSArray<ASFGConnection *> * _Nonnull connections, BOOL * _Nonnull stop) {
        filteredallNodes[filePath] = _allNodes[filePath];
        [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull conn, NSUInteger idx, BOOL * _Nonnull stop) {
            filteredallNodes[conn.targetNode.filePath] = conn.targetNode;
        }];
    }];
    
    // level graph
    NSArray<NSArray<ASFGNode *> *> *levelGraph = [[self class] getLevelGraphDataWithInputNodes:sortedInputNodes allNodes:filteredallNodes graph:filteredGraph];
    
    // graph data
    _graphData = [[ASFGGraphData alloc] initWithInputNodes:sortedInputNodes graph:filteredGraph levelGraph:levelGraph];
}

#pragma mark - parse

- (void)updateGraphWithItemPath:(NSString *)itemPath
{
    NSString *realItemPath = [ASFGPathHelper realAccessPathWithPath:itemPath];
    BOOL isDir = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:realItemPath isDirectory:&isDir];
    if (!existed)
    {
        return;
    }
    
    NSString *filePath = nil;
    if (isDir)
    {
        NSString *frameworkNameSuffix = @".framework";
        if ([itemPath hasSuffix:frameworkNameSuffix])
        {
            // if need to read the info.plist to get the library file name (not work at the following case)
            // for example: /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
            // - /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
            // - no info.plist in '/System/Library/Frameworks/IOKit.framework'
            // - but there is a 'link' in '/System/Library/Frameworks/IOKit.framework'!!
            NSString *frameworkName = itemPath.lastPathComponent;
            NSString *fileName = [frameworkName substringWithRange:NSMakeRange(0, frameworkName.length - frameworkNameSuffix.length)];
            filePath = [itemPath stringByAppendingPathComponent:fileName];
        }
        else
        {
            assert(NO);
            return;
        }
    }
    else
    {
        filePath = itemPath;
    }
    
    // check if symbolic link
    NSString *realFilePath = [ASFGPathHelper realAccessPathWithPath:filePath];
    NSDictionary<NSFileAttributeKey, id> *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:realFilePath error:nil];
    if (fileAttrs[NSFileType] == NSFileTypeSymbolicLink)
    {
        NSString *destination = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:realFilePath error:nil];
        assert(destination.length > 0);
        filePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:destination];
    }
    
    // parsed already
    if (_inputNodes[filePath] != nil)
    {
        return;
    }
    
    NSArray<ASFGConnection *> *connections = [self parseDependenciesWithFilePath:filePath];
    if (connections == nil)
    {
        return;
    }
    
    ASFGNode *node = _allNodes[filePath];
    if (node == nil)
    {
        node = [[ASFGNode alloc] initWithFilePath:filePath];
        _allNodes[filePath] = node;
    }
    _inputNodes[filePath] = node;
    
    // graph
    [self addGraphDataWithSourceNode:node connections:connections];
}

- (NSString *)extractDirWithFilePath:(NSString *)filePath
{
    NSString *dir = nil;
    
    NSRange frameworkRange = [filePath rangeOfString:@".framework"];
    if (frameworkRange.location != NSNotFound)
    {
        NSString *frameworkDir = [filePath substringToIndex:(frameworkRange.location + frameworkRange.length)];
        dir = [frameworkDir stringByDeletingLastPathComponent];
    }
    else
    {
        dir = [filePath stringByDeletingLastPathComponent];
    }
    
    return dir;
}

- (NSArray<ASFGConnection *> *)parseDependenciesWithFilePath:(NSString *)filePath
{
    NSString *realFilePath = [ASFGPathHelper realAccessPathWithPath:filePath];
    NSData *data = [NSData dataWithContentsOfFile:realFilePath];
    if (data == nil || data.length < 1024)
    {
        NSLog(@"File not found or No access right to the file: %@ (at %@)", filePath, realFilePath);
        return nil;
    }
    
    uint64_t machoFileOffset = 0;
    uint64_t machoFileSize = 0;
    
    struct fat_header *fatHeader = (struct fat_header *)data.bytes;
    BOOL isFatFile = fatHeader->magic == FAT_MAGIC || fatHeader->magic == FAT_CIGAM;
    if (isFatFile)
    {
        uint32_t archCount = ntohl(fatHeader->nfat_arch);
        if (archCount == 0)
        {
            return nil;
        }
        
        struct fat_arch *fatArch = (struct fat_arch *)((uint8_t *)fatHeader + sizeof(struct fat_header));
        for (uint32_t i = 0; i < archCount; i++)
        {
            cpu_type_t cpuType = ntohl(fatArch->cputype);
            if (cpuType == _preferCPUType)
            {
                machoFileOffset = ntohl(fatArch->offset);
                machoFileSize = ntohl(fatArch->size);
                break;
            }
            
            fatArch += 1;
        }
    }
    else
    {
        BOOL isMachOFile = fatHeader->magic == MH_MAGIC_64
                           || fatHeader->magic == MH_CIGAM_64;
        if (!isMachOFile)
        {
            return nil;
        }
        
        // TODO: support MH_CIGAM_64
        assert(fatHeader->magic != MH_CIGAM_64);
        
        machoFileSize = data.length;
    }
    
    if (machoFileSize == 0)
    {
        return nil;
    }
    
    NSMutableArray<ASFGConnection *> *connections = [[NSMutableArray alloc] init];
    
    struct mach_header_64 *machoHeader = (struct mach_header_64 *)((uint8_t *)data.bytes + machoFileOffset);
    uint8_t *machoLoadCommand = (uint8_t *)machoHeader + sizeof(struct mach_header_64);
    uint32_t ncmds = machoHeader->ncmds;
    for (int i = 0; i < ncmds; i++)
    {
        struct load_command *lc = (struct load_command *)machoLoadCommand;
        uint32_t type = lc->cmd;
        uint32_t size = lc->cmdsize;
        if (type == LC_LOAD_DYLIB
            || type == LC_LOAD_WEAK_DYLIB
            || type == LC_REEXPORT_DYLIB
            || type == LC_LAZY_LOAD_DYLIB)
        {
            // TODO: lazy load...
            assert(type != LC_LAZY_LOAD_DYLIB);
            
            struct dylib_command *dylibLC = (struct dylib_command *)lc;
            char *dylibPathCString = (char *)lc + dylibLC->dylib.name.offset;
            NSString *dylibPath = [NSString stringWithCString:dylibPathCString encoding:NSUTF8StringEncoding];
            ASFGNode *node = _allNodes[dylibPath];
            if (node == nil)
            {
                node = [[ASFGNode alloc] initWithFilePath:dylibPath];
                _allNodes[dylibPath] = node;
            }
            
            ASFGConnectionType connType = ASFGConnectionTypeStrong;
            if (type == LC_LOAD_WEAK_DYLIB)
            {
                connType = ASFGConnectionTypeWeak;
            }
            else if (type == LC_REEXPORT_DYLIB)
            {
                connType = ASFGConnectionTypeReexport;
            }
            ASFGConnection *conn = [[ASFGConnection alloc] initWithTargetNode:node connectionType:connType];
            [connections addObject:conn];
        }
        machoLoadCommand += size;
    }
    
    return connections;
}

- (void)addGraphDataWithSourceNode:(ASFGNode *)sourceNode connections:(NSArray<ASFGConnection *> *)connections
{
    assert(_graph[sourceNode.filePath] == nil);
    
    NSArray<ASFGConnection *> *sortedConnections = [connections sortedArrayUsingComparator:^NSComparisonResult(ASFGConnection * _Nonnull conn1, ASFGConnection * _Nonnull conn2) {
        return [conn1.targetNode.filePath compare:conn2.targetNode.filePath];
    }];
    _graph[sourceNode.filePath] = sortedConnections;
}

- (NSDictionary<NSString *, NSArray<ASFGConnection *> *> *)filterGraph
{
    NSMutableDictionary<NSString *, NSArray<ASFGConnection *> *> *graph = [[NSMutableDictionary alloc] init];
    
    [_graph enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<ASFGConnection *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray<ASFGConnection *> *goodConns = [[NSMutableArray alloc] init];
        
        [obj enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![_hiddenFrameworks containsObject:obj.targetNode.filePath])
            {
                [goodConns addObject:obj];
            }
        }];
        
        graph[key] = goodConns;
    }];
    
    return graph;
}

+ (NSArray<NSArray<ASFGNode *> *> *)getLevelGraphDataWithInputNodes:(NSArray<ASFGNode *> *)inputNodes allNodes:(NSDictionary<NSString *, ASFGNode *> *)allNodes graph:(NSDictionary<NSString *, NSArray<ASFGConnection *> *> *)graph
{
    // Level Graph:
    // - there should not be 'connections' between the nodes in the same level
    // == (if need to remove this limitation......)
    // Level Graph Optimations (TODO):
    // - if too many node in one level, break it down...
    // - the node with more "out lines" should place more close center??????
    // - ...
    
#if LEVEL_GRAPH_BUILD_METHOD == 1
    
    // ----------------------------------- method 1 start
    NSMutableDictionary<NSString *, NSNumber *> *nodeInLevelGraph = [[NSMutableDictionary alloc] init];
    __block NSInteger currentMinLevelGraphIndex = 0;
    __block NSInteger currentMaxLevelGraphIndex = 0;
    [inputNodes enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        __block NSInteger sourceNodeLevelGraphIndex = currentMinLevelGraphIndex;
        if (nodeInLevelGraph[node.filePath] != nil)
        {
            sourceNodeLevelGraphIndex = [nodeInLevelGraph[node.filePath] integerValue];
        }
        
        NSArray<ASFGConnection *> *connections = graph[node.filePath];
        [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull conn, NSUInteger idx, BOOL * _Nonnull stop) {
            ASFGNode *targetNode = conn.targetNode;
            NSInteger targetNodeLevelGraphIndex = sourceNodeLevelGraphIndex + 1;
            if (nodeInLevelGraph[targetNode.filePath] != nil)
            {
                targetNodeLevelGraphIndex = [nodeInLevelGraph[targetNode.filePath] integerValue];
            }
            if (sourceNodeLevelGraphIndex == targetNodeLevelGraphIndex)
            {
                if (sourceNodeLevelGraphIndex == currentMinLevelGraphIndex)
                {
                    sourceNodeLevelGraphIndex -= 1;
                }
                else if (targetNodeLevelGraphIndex == currentMaxLevelGraphIndex)
                {
                    targetNodeLevelGraphIndex = currentMaxLevelGraphIndex + 1;
                }
                else
                {
                    targetNodeLevelGraphIndex = sourceNodeLevelGraphIndex + 1;
                }
            }
            currentMinLevelGraphIndex = MIN(currentMinLevelGraphIndex, sourceNodeLevelGraphIndex);
            currentMaxLevelGraphIndex = MAX(currentMaxLevelGraphIndex, targetNodeLevelGraphIndex);
            
            nodeInLevelGraph[targetNode.filePath] = @(targetNodeLevelGraphIndex);
        }];
        
        nodeInLevelGraph[node.filePath] = @(sourceNodeLevelGraphIndex);
    }];
    
    NSMutableArray<NSMutableArray<ASFGNode *> *> *levelGraph = [[NSMutableArray alloc] init];
    
    NSArray<NSString *> *sortedKeys = [nodeInLevelGraph keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *  _Nonnull obj1, NSNumber *  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    __block NSNumber *currentIndexValue = nil;
    [sortedKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *indexValue = nodeInLevelGraph[obj];
        if (currentIndexValue == nil || ![currentIndexValue isEqualToNumber:indexValue])
        {
            currentIndexValue = indexValue;
            [levelGraph addObject:[[NSMutableArray alloc] init]];
        }
        [levelGraph[levelGraph.count - 1] addObject:allNodes[obj]];
    }];
    
#elif LEVEL_GRAPH_BUILD_METHOD == 2
    
    // ----------------------------------- method 2 start
    NSMutableArray<NSMutableArray<ASFGNode *> *> *levelGraph = [[NSMutableArray alloc] init];
    NSMutableDictionary<NSString *, NSMutableArray<ASFGNode *> *> *nodeContainerInLevelGraph = [[NSMutableDictionary alloc] init];
    [inputNodes enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray<ASFGNode *> *sourceNodeContainer = nodeContainerInLevelGraph[node.filePath];
        if (sourceNodeContainer == nil)
        {
            if (levelGraph.count == 0)
            {
                [levelGraph addObject:[[NSMutableArray alloc] init]];
            }
            sourceNodeContainer = levelGraph[0];
            [sourceNodeContainer addObject:node];
        }
        NSUInteger sourceNodeContainerIndex = [levelGraph indexOfObject:sourceNodeContainer];
        assert(sourceNodeContainerIndex != NSNotFound);
        NSUInteger targetNodeContainerIndex = sourceNodeContainerIndex + 1;
        NSMutableArray<ASFGNode *> *targetNodeContainer = nil;
        assert(targetNodeContainerIndex <= levelGraph.count);
        if (targetNodeContainerIndex == levelGraph.count)
        {
            [levelGraph addObject:[[NSMutableArray alloc] init]];
        }
        targetNodeContainer = levelGraph[targetNodeContainerIndex];

        __block BOOL needMoveNodeUp = NO;
        NSArray<ASFGConnection *> *connections = graph[node.filePath];
        [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull conn, NSUInteger idx, BOOL * _Nonnull stop) {
            ASFGNode *targetNode = conn.targetNode;
            NSMutableArray<ASFGNode *> *existedTargetNodeContainer = nodeContainerInLevelGraph[targetNode.filePath];
            if (existedTargetNodeContainer == nil)
            {
                [targetNodeContainer addObject:targetNode];
                nodeContainerInLevelGraph[targetNode.filePath] = targetNodeContainer;
            }
            else if (existedTargetNodeContainer == sourceNodeContainer)
            {
                needMoveNodeUp = YES;
            }
        }];

        if (needMoveNodeUp)
        {
            // if need to move up the dependecies??
            
            [sourceNodeContainer removeObject:node];

            [levelGraph insertObject:[[NSMutableArray alloc] init] atIndex:sourceNodeContainerIndex];
            sourceNodeContainer = levelGraph[sourceNodeContainerIndex];
            [sourceNodeContainer addObject:node];
        }
        
        if (targetNodeContainer.count == 0)
        {
            [levelGraph removeObject:targetNodeContainer];
        }
        
        nodeContainerInLevelGraph[node.filePath] = sourceNodeContainer;
    }];
    
#elif LEVEL_GRAPH_BUILD_METHOD == 3
    
    // ----------------------------------- method 3 start
    // algorithm:
    // 1. first put all nodes into two level
    // - level one: all the input nodes
    // - level two: all the depedency nodes excluding the input nodes
    // 2. process the level one to generate the 'next level set' below level one, if need
    // - iterate each node, if the node has depedency nodes, put the dependency nodes into the 'next level set'
    // == notice the 'circular dependency' case, the first dependency node would go to the 'next level'
    // - insert the 'next level set' into the level two, so that there are 3 level
    // 3. process the new level with the same logic in 2, until no 'new level' created
    
    NSMutableArray<NSMutableArray<ASFGNode *> *> *levelGraph = [[NSMutableArray alloc] init];
    NSMutableArray<ASFGNode *> *inputLevel = [inputNodes mutableCopy];
    NSMutableDictionary<NSString *, ASFGNode *> *dependencyLevelDict = [[NSMutableDictionary alloc] init];
    [graph enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<ASFGConnection *> * _Nonnull connections, BOOL * _Nonnull stop) {
        [connections enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull conn, NSUInteger idx, BOOL * _Nonnull stop) {
            if (graph[conn.targetNode.filePath] == nil)
            {
                dependencyLevelDict[conn.targetNode.filePath] = conn.targetNode;
            }
        }];
    }];
    if (inputLevel.count > 0)
    {
        [levelGraph addObject:inputLevel];
    }
    if (dependencyLevelDict.count > 0)
    {
        NSMutableArray<ASFGNode *> *dependencyLevel = [[dependencyLevelDict allValues] mutableCopy];
        [levelGraph addObject:dependencyLevel];
    }
    
    NSMutableArray<ASFGNode *> *processLevel = inputLevel;
    NSUInteger processLevelIndex = 0;
    while (processLevel.count > 1)
    {
        NSMutableDictionary<NSString *, NSNumber *> *processLevelDict = [[NSMutableDictionary alloc] init];
        [processLevel enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            processLevelDict[node.filePath] = @(idx);
        }];
        
        NSMutableDictionary<NSString *, NSString *> *nextLevelData = [[NSMutableDictionary alloc] init];
        NSMutableIndexSet *removeIndexInProcessLevel = [[NSMutableIndexSet alloc] init];
        [processLevel enumerateObjectsUsingBlock:^(ASFGNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            [graph[node.filePath] enumerateObjectsUsingBlock:^(ASFGConnection * _Nonnull conn, NSUInteger idx, BOOL * _Nonnull stop) {
                if (processLevelDict[conn.targetNode.filePath] != nil
                    && ![nextLevelData[conn.targetNode.filePath] isEqualToString:node.filePath])
                {
                    nextLevelData[conn.targetNode.filePath] = node.filePath;
                    
                    [removeIndexInProcessLevel addIndex:[processLevelDict[conn.targetNode.filePath] unsignedIntegerValue]];
                }
            }];
        }];
        
        NSMutableArray<ASFGNode *> *nextLevel = [[NSMutableArray alloc] init];
        [nextLevelData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull filePath, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [nextLevel addObject:allNodes[filePath]];
        }];
        
        // remove nodes from processLevel
        [processLevel removeObjectsAtIndexes:removeIndexInProcessLevel];
        // add level
        if (nextLevel.count > 0)
        {
            [levelGraph insertObject:nextLevel atIndex:(processLevelIndex + 1)];
        }
        
        processLevel = nextLevel;
        processLevelIndex += 1;
    }
    
#endif
    
    [levelGraph enumerateObjectsUsingBlock:^(NSMutableArray<ASFGNode *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        assert(obj.count > 0);
        
        [obj sortUsingComparator:^NSComparisonResult(ASFGNode * _Nonnull node1, ASFGNode * _Nonnull node2) {
            return [node1.filePath compare:node2.filePath];
        }];
    }];
    
    return levelGraph;
}

@end
