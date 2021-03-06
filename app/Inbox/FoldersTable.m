#import "FoldersTable.h"
#import "DropZoneNode.h"
#import "cocos2d.h"
#import "FolderModel.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "Deps.h"

@interface FoldersTable()
@end

@implementation FoldersTable
@synthesize folders;
-(id)init{
    if (self = [super init]){
        table = [[SWTableView viewWithDataSource:self size:CGSizeMake(240, 748)] retain];
        [table setVerticalFillOrder:SWTableViewFillTopDown];
    }
    return self;
}

-(void)dealloc{
    [table release];
    self.folders = nil;
    [super dealloc];
}

-(CCNode*)view{
    return table;
}

-(void)setFolders:(NSArray *)f{
    [folders autorelease];
    folders = [f retain];
    [table reloadData];
    [table scrollToTop];
}


-(CGSize)cellSizeForTable:(SWTableView *)t{
    return CGSizeMake([DropZoneNode fullSize].width, [DropZoneNode fullSize].width + 30);
}

-(SWTableViewCell *)table:(SWTableView *)t cellAtIndex:(NSUInteger)idx{
    DropZoneNode* node =  [[[DropZoneNode alloc] init] autorelease];

    FolderModel* folder = (FolderModel*)[[Deps sharedInstance].coreDataManager.mainContext objectWithID:[self.folders objectAtIndex:idx]];
    if (folder){
        node.title = [folder hrTitle];
    }else{
        node.title =  @""; 
    }
    return node;
}

-(NSUInteger)numberOfCellsInTableView:(SWTableView *)t{
    if (self.folders){
        int count = [self.folders count];
        return count;
    }
    return 10;
}

-(FolderModel*) folderModelAtPoint:(CGPoint)point{
    int cellIndex = [table cellIndexAt:point];
    if (cellIndex!=-1){
        FolderModel* folder = (FolderModel*)[[Deps sharedInstance].coreDataManager.mainContext objectWithID:[self.folders objectAtIndex:cellIndex]];
        return folder;
    }
    return nil;
}

-(CGPoint) centerOfFolderAtPoint:(CGPoint)p{
    int cellIndex = [table cellIndexAt:p];
    CGSize size = [self cellSizeForTable:table];
    CGPoint point = p;//CGPointMake(size.width, size.height * cellIndex + size.height/2);
    point = [DropZoneNode visualCenterFromRealCenter:point];
    return [table.container convertToWorldSpace:point];
}

@end
