//
//  RabbitManager.h
//  rabbitmqtest
//
//  Created by griff on 17/3/16.
//  Copyright © 2016 grrr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DURabbitManager : NSObject

+ (instancetype)sharedManager;

/*******************************************/

// CA Cert file name. Place file anywhere in project directory. Default is NO.
@property (strong, nonatomic) NSString *caCertPemName;

/*******************************************/

// Rabbit MQ server.
@property (strong, nonatomic) NSString *rabbitServer;

/*******************************************/

// Rabbit MQ stagging server.
@property (strong, nonatomic) NSString *rabbitServerStaging;

/*******************************************/

// Port number for server. Default is 80.
@property (assign, nonatomic) NSInteger port;

/*******************************************/

// Enable/disable staging environment. Default is NO.
@property (assign, nonatomic) BOOL enableStaging;

/*******************************************/

// User sign in status. Default is NO.
@property (assign, nonatomic) BOOL isSignedIn;

/*******************************************/

- (void)setServer:(NSString *)rabbitServer stagingServer:(NSString *)rabbitServerStaging port:(NSInteger)port username:(NSString *)username password:(NSString *)password;
- (void)startConsumingWithExchange:(NSString *)exchange routingKey:(NSString *)routingKey success:(void (^)(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage))successBlock failed:(void (^)(void))failedBlock;
- (void)pauseConsuming;
- (void)resumeConsuming;
- (void)stopConsuming;
- (BOOL)isConsuming;
- (void)sendMesage:(NSString *)message immedite:(BOOL)immediate;

@end
