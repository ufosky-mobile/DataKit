//
//  DKFile.m
//  DataKit
//
//  Created by Erik Aigner on 13.03.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKFile.h"

#import "DKManager.h"
#import "DKRequest.h"

@interface DKFile ()
@property (nonatomic, assign, readwrite) BOOL isVolatile;
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) DKFileSaveResultBlock saveResultBlock;
@property (nonatomic, copy) DKFileLoadResultBlock loadResultBlock;
@property (nonatomic, copy) DKFileProgressBlock uploadProgressBlock;
@property (nonatomic, copy) DKFileProgressBlock downloadProgressBlock;
@end

@implementation DKFile
DKSynthesize(isVolatile)
DKSynthesize(URL)
DKSynthesize(name)
DKSynthesize(data)
DKSynthesize(saveResultBlock)
DKSynthesize(loadResultBlock)
DKSynthesize(uploadProgressBlock)
DKSynthesize(downloadProgressBlock);

+ (DKFile *)fileWithName:(NSString *)name {
  return [self fileWithData:nil name:name];
}

+ (DKFile *)fileWithData:(NSData *)data {
  return [self fileWithData:data name:nil];
}

+ (DKFile *)fileWithData:(NSData *)data name:(NSString *)name {
  return [[self alloc] initWithData:data name:name];
}

- (id)initWithName:(NSString *)name {
  return [self initWithData:nil name:name];
}

- (id)initWithData:(NSData *)data name:(NSString *)name {
  self = [self init];
  if (self) {
    self.data = data;
    self.name = name;
  }
  return self;
}

+ (BOOL)deleteFile:(NSString *)fileName error:(NSError **)error {
  return [self deleteFiles:[NSArray arrayWithObject:fileName] error:error];
}

+ (BOOL)deleteFiles:(NSArray *)fileNames error:(NSError **)error {
  // Create the request  
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSDictionary *dict = [NSDictionary dictionaryWithObject:fileNames forKey:@"files"];
  
  NSError *requestError = nil;
  [request sendRequestWithObject:dict method:@"unlink" error:&requestError];
  if (requestError != nil) {
    if (error != nil) {
      *error = requestError;
    }
    return NO;
  }
  return YES;
}

- (BOOL)delete {
  return [self delete:NULL];
}

- (BOOL)delete:(NSError **)error {
  return [isa deleteFile:self.name error:error];
}

- (void)deleteInBackgroundWithBlock:(DKFileDeleteResultBlock)block {
  block = [block copy];
  dispatch_queue_t q = dispatch_get_current_queue();
  dispatch_async([DKManager queue], ^{
    NSError *error = nil;
    BOOL success = [self delete:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(success, error); 
      });
    }
  });
}

- (BOOL)saveSynchronous:(BOOL)saveSync
            resultBlock:(DKFileSaveResultBlock)resultBlock
          progressBlock:(DKFileProgressBlock)progressBlock
                  error:(NSError **)error {  
  // Create url request
  NSURL *URL = [DKManager endpointForMethod:@"store"];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
  
  // DEVNOTE: Timeout interval is quirky
  // https://devforums.apple.com/thread/25282
  req.timeoutInterval = 20.0;
  req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  req.HTTPBody = self.data;
  req.HTTPMethod = @"POST";
  
  NSString *contentLen = [NSString stringWithFormat:@"%lu", self.data.length];
  
  [req setValue:contentLen forHTTPHeaderField:@"Content-Length"];
  [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
  [req setValue:[DKManager APISecret] forHTTPHeaderField:@"x-datakit-secret"];
  if (name_.length > 0) {
    [req setValue:name_ forHTTPHeaderField:@"x-datakit-filename"];
  }
  
  // Save synchronous
  if (saveSync) {
    NSError *reqError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&reqError];
    
    NSError *parseErr = nil;
    [DKRequest parseResponse:response withData:data error:&parseErr];
    
    if (parseErr == nil) {
      self.isVolatile = NO;
      return YES;
    }
    else {
      if (error != NULL) {
        *error = parseErr;
      }
    }
  }
  
  // Save asynchronous
  else {
    self.saveResultBlock = resultBlock;
    self.loadResultBlock = nil;
    self.downloadProgressBlock = nil;
    self.uploadProgressBlock = progressBlock;
    
    [[NSURLConnection connectionWithRequest:req delegate:self] start];
  }
  
  return NO;
}

- (BOOL)save {
  return [self save:NULL];
}

- (BOOL)save:(NSError **)error {
  return [self saveSynchronous:YES resultBlock:NULL progressBlock:NULL error:error];
}

- (void)saveInBackgroundWithBlock:(DKFileSaveResultBlock)block {
  [self saveSynchronous:NO resultBlock:block progressBlock:NULL error:NULL];
}

- (void)saveInBackgroundWithBlock:(DKFileSaveResultBlock)block progressBlock:(DKFileProgressBlock)progressBlock {
  [self saveSynchronous:NO resultBlock:block progressBlock:progressBlock error:NULL];
}

- (NSData *)loadData {
  return [self loadData:NULL];
}

- (NSData *)loadData:(NSError **)error {
  return nil;
}

- (void)loadDataInBackgroundWithBlock:(DKFileLoadResultBlock)block {
  
}

- (void)loadDataInBackgroundWithBlock:(DKFileLoadResultBlock)block progressBlock:(DKFileProgressBlock)progressBlock {
  
}

- (void)abort {
  
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [connection cancel];
  if (self.saveResultBlock != nil) {
    self.saveResultBlock(NO, error);
  }
}

#pragma mark - NSURLConnectionDownloadDelegate

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
  if (self.downloadProgressBlock != nil) {
    self.downloadProgressBlock(totalBytesWritten, expectedTotalBytes);
  }
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
  self.data = [NSData dataWithContentsOfURL:destinationURL];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  // implement?
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSError *error = nil;
    NSHTTPURLResponse *httpResponse = (id)response;
    
    if (httpResponse.statusCode == 201 /* HTTP: Created */) {
      self.isVolatile = NO;
      
      if (self.saveResultBlock != nil) {
        self.saveResultBlock(YES, nil);
      }
    }
    else if (httpResponse.statusCode == 409 /* HTTP: Conflict */) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File already exists", nil)
                                                           forKey:NSLocalizedDescriptionKey];
      error = [NSError errorWithDomain:NSCocoaErrorDomain code:409 userInfo:userInfo];
    }
    else {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown server response", nil)
                                                           forKey:NSLocalizedDescriptionKey];
      error = [NSError errorWithDomain:NSCocoaErrorDomain code:500 userInfo:userInfo];
    }
    
    // Abort and pass error
    if (error != NULL) {
      [connection cancel];
      
      if (self.saveResultBlock != nil) {
        self.saveResultBlock(NO, error);
      }
    }
  }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  if (self.uploadProgressBlock != nil) {
    self.uploadProgressBlock(totalBytesWritten, totalBytesExpectedToWrite);
  }
}

@end