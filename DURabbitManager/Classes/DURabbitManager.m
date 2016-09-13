//
//  RabbitManager.m
//  rabbitmqtest
//
//  Created by griff on 17/3/16.
//  Copyright © 2016 grrr. All rights reserved.
//

#import "DURabbitManager.h"

#include <amqp_ssl_socket.h>
#include <amqp.h>
#include <amqp_framing.h>

NSString *const kSignedInStatusChangedNotification  = @"com.duriana.SignInManager.signedInStatusChangedNotification";
NSString *const kProfileRefreshCancelIdentifier     = @"com.duriana.RabbitManager.refreshCancel";
NSString *const kRabbitBiddingMessageReceived       = @"com.duriana.RabbitBiddingMessageReceived";
static const NSTimeInterval kRetryInterval                 = 1.0 * 60.0;

#define _f(string, ...) ([NSString stringWithFormat:string, __VA_ARGS__])

#pragma mark - Convinience

static void (^errorLoggerBlock)(NSString *) = ^(NSString *log) {
    NSLog(@"Rabbit: %@", log);
};

static NSString *RabbitErrorString(amqp_rpc_reply_t reply, NSString *context) {
    switch (reply.reply_type) {
        case AMQP_RESPONSE_NORMAL :              return nil;
        case AMQP_RESPONSE_NONE :                return _f(@"%@: missing RPC reply type!", context);
        case AMQP_RESPONSE_LIBRARY_EXCEPTION :   return _f(@"%@: %s", context, amqp_error_string2(reply.library_error));
        case AMQP_RESPONSE_SERVER_EXCEPTION :
            switch (reply.reply.id) {
                case AMQP_CONNECTION_CLOSE_METHOD : {
                    amqp_connection_close_t *m = (amqp_connection_close_t *)reply.reply.decoded;
                    return _f(@"%@: server connection error %d, message: %.*s", context, m->reply_code, (int)m->reply_text.len, (char *)m->reply_text.bytes);
                }
                case AMQP_CHANNEL_CLOSE_METHOD : {
                    amqp_channel_close_t *m = (amqp_channel_close_t *)reply.reply.decoded;
                    return _f(@"%@: server channel error %d, message: %.*s", context, m->reply_code, (int)m->reply_text.len, (char *)m->reply_text.bytes);
                }
                default :
                    return _f(@"%@: unknown server error, method id 0x%08X", context, reply.reply.id);
            }
            break;
    }
    return nil;
}

static BOOL RabbitLogAMQPError(amqp_rpc_reply_t reply, NSString *context) {
    NSString *errorString = RabbitErrorString(reply, context);
    if (errorString) {
        errorLoggerBlock(errorString);
        return YES;
    }
    return NO;
}

static BOOL RabbitLogError(int errorCode, NSString *context) {
    if (errorCode < 0) {
        errorLoggerBlock(_f(@"%@: %s", context, amqp_error_string2(errorCode)));
        return YES;
    }
    return NO;
}

#pragma mark - RabbitConsumer

typedef void (^RabbitConsumerCallback)(NSString *exchange, NSString *routingKey, NSString *type, NSData *data);
typedef void (^RabbitConsumerErrorCallback)(amqp_rpc_reply_t res);

@interface RabbitConsumer : NSObject  {
    amqp_socket_t           *_socket;
    amqp_connection_state_t _conn;
}

@property (copy, nonatomic) NSString                    *hostname;
@property (copy, nonatomic) NSString                    *exchange;
@property (copy, nonatomic) NSString                    *routingKey;
@property (assign, nonatomic) NSInteger                 port;
@property (copy, nonatomic) RabbitConsumerCallback      callback;
@property (copy, nonatomic) RabbitConsumerErrorCallback fatalErrorCallback;
@property (assign, atomic) BOOL                         isConsuming;
@property (assign, atomic) BOOL                         isHTTPS;

- (instancetype)initWithHostname:(NSString *)hostname port:(NSInteger)port exchange:(NSString *)exchange routingKey:(NSString *)routingKey cacertpem:(NSString *)cacertpem keypem:(NSString *)keypem certpem:(NSString *)certpem;
- (void)startConsuming;  // start consuming infinite loop
- (void)stopConsuming;
-(void)sendMessage:(NSString *)message;

@end

@implementation RabbitConsumer

- (instancetype)initWithHostname:(NSString *)hostname port:(NSInteger)port exchange:(NSString *)exchange routingKey:(NSString *)routingKey cacertpem:(NSString *)cacertpem keypem:(NSString *)keypem certpem:(NSString *)certpem {
    if ((self = [super init])) {
        _hostname   = hostname;
        _port       = port;
        _exchange   = exchange;
        _routingKey = routingKey;
        _socket     = NULL;

        // connect over http if cacert not found
        _isHTTPS = cacertpem.length;

        if ((!certpem.length && keypem.length) || (certpem.length && !keypem.length) && _isHTTPS) {
            errorLoggerBlock(_f(@"bad client certificate/key\ncertpem: %@\nkeypem: %@", certpem, keypem));
            return nil;
        }

        const char *hostnameBytes   = _hostname.UTF8String;
        const char *exchangeBytes   = _exchange.UTF8String;
        const char *routingKeyBytes = _routingKey.UTF8String;

        if (!hostnameBytes || !exchangeBytes || !routingKeyBytes) {
            errorLoggerBlock(_f(@"hostname, exchange or routing key string is empty.\nhostname: %@\nexchange: %@\nrouting key: %@", _hostname, _exchange, _routingKey));
            return nil;
        }

        // new connection
        _conn = amqp_new_connection();

        // setup ssl certificates
        //TO DO -
        _socket = amqp_ssl_socket_new(_conn);
        if (!_socket) {
            errorLoggerBlock(@"Failed to create a socket");
            return nil;
        }

        // set peer validation to false, we only want to verify the server, on the server we have verify_none, so no need for client verification
        amqp_ssl_socket_set_verify_peer(_socket, false);

        if(_isHTTPS) {
            // set ca cert
            if (amqp_ssl_socket_set_cacert(_socket, cacertpem.UTF8String)) {
                errorLoggerBlock(@"Failed to set CA certificate");
                return nil;
            }

            // set client cert and key if provided
            if (certpem.length && keypem.length) {
                if (amqp_ssl_socket_set_key(_socket, certpem.UTF8String, keypem.UTF8String)) {
                    errorLoggerBlock(@"Failed to set Client certificate key");
                    return nil;
                }
            }
        }

        // open ssl socket
        int socketStatus = amqp_socket_open(_socket, hostnameBytes, (int)_port);
        if (socketStatus) {
            errorLoggerBlock(_f(@"Failed to open socket with hostname: %@:%zd: %s", _hostname, _port, amqp_error_string2(socketStatus)));
            return nil;
        }

        // open channel
        if (RabbitLogAMQPError(amqp_login(_conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, "duriana", "!iloveduriana!"), @"Loggin in")) {
            return nil;
        }

        amqp_channel_open(_conn, 1);
        if (RabbitLogAMQPError(amqp_get_rpc_reply(_conn), @"Opening channel")) {
            return nil;
        }

        // declare exchange
        amqp_bytes_t exchange_bytes = amqp_cstring_bytes(exchangeBytes);
        amqp_exchange_declare(_conn, 1, exchange_bytes, amqp_cstring_bytes("direct"), 0, 1, 0, 0, amqp_empty_table);
        if (RabbitLogAMQPError(amqp_get_rpc_reply(_conn), @"Declaring exchange")) {
            return nil;
        }

        // declare a queue
        amqp_queue_declare_ok_t *r = amqp_queue_declare(_conn, 1, amqp_empty_bytes, 0, 1, 1, 1, amqp_empty_table);
        if (RabbitLogAMQPError(amqp_get_rpc_reply(_conn), @"Declaring queue")) {
            return nil;
        }

        if (r) {
            // bind
            amqp_queue_bind(_conn, 1, r->queue, exchange_bytes, amqp_cstring_bytes(routingKeyBytes), amqp_empty_table);
            if (RabbitLogAMQPError(amqp_get_rpc_reply(_conn), @"Binding queue")) {
                return nil;
            }

            // consume
            amqp_basic_consume(_conn, 1, r->queue, amqp_empty_bytes, 0, 1, 0, amqp_empty_table);
            if (RabbitLogAMQPError(amqp_get_rpc_reply(_conn), @"Consuming")) {
                return nil;
            }
        }
    }
    return self;
}

- (void)dealloc {
    if (_conn) {
        RabbitLogAMQPError(amqp_channel_close(_conn, 1, AMQP_REPLY_SUCCESS), @"Closing channel");
        RabbitLogAMQPError(amqp_connection_close(_conn, AMQP_REPLY_SUCCESS), @"Closing connection");
        RabbitLogError(amqp_destroy_connection(_conn), @"Ending connection");
    }

    self.isConsuming = NO;
}

- (void)startConsuming {
    if (self.isConsuming) {
        return;
    }
    self.isConsuming = YES;

    while (self.isConsuming) {
        amqp_maybe_release_buffers(_conn);

        amqp_envelope_t envelope;

        struct timeval tv = {.tv_sec = 3, .tv_usec = 0};
        amqp_rpc_reply_t res = amqp_consume_message(_conn, &envelope, &tv, 0);

        if (res.reply_type == AMQP_RESPONSE_NORMAL) {
            // success
            NSString *exchange      = [[NSString alloc] initWithBytes:envelope.exchange.bytes length:envelope.exchange.len encoding:NSUTF8StringEncoding];
            NSString *routingKey    = [[NSString alloc] initWithBytes:envelope.routing_key.bytes length:envelope.routing_key.len encoding:NSUTF8StringEncoding];
            NSString *type          = [[NSString alloc] initWithBytes:envelope.message.properties.type.bytes length:envelope.message.properties.type.len encoding:NSUTF8StringEncoding];
            NSData *data            = [NSData dataWithBytes:envelope.message.body.bytes length:envelope.message.body.len];
            amqp_destroy_envelope(&envelope);

            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.callback) {
                    self.callback(exchange, routingKey, type, data);
                }
            });
        } else {
            // error
            if (AMQP_RESPONSE_LIBRARY_EXCEPTION == res.reply_type && res.library_error == AMQP_STATUS_UNEXPECTED_STATE) {
                amqp_frame_t frame;
                if (amqp_simple_wait_frame_noblock(_conn, &frame, &tv) != AMQP_STATUS_OK) {
                    self.isConsuming = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.fatalErrorCallback) {
                            self.fatalErrorCallback(res);
                        }
                    });
                    return;
                }
            }
            if (res.library_error != AMQP_STATUS_TIMEOUT) {
                self.isConsuming = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.fatalErrorCallback) {
                        self.fatalErrorCallback(res);
                    }
                });
            }
        }
    }
}

- (void)stopConsuming {
    self.isConsuming = NO;
}

-(void)sendMessage:(NSString *)message immedite:(BOOL)immediate{
    amqp_bytes_t exchangeBytes = amqp_cstring_bytes(_exchange.UTF8String);
    amqp_bytes_t routingKeyBytes = amqp_cstring_bytes(_routingKey.UTF8String);
    amqp_bytes_t messageBytes = amqp_cstring_bytes(message.UTF8String);
    struct amqp_basic_properties_t_ properties;
    amqp_status_enum status = amqp_basic_publish(_conn, 1, exchangeBytes, routingKeyBytes, YES, immediate, &properties, messageBytes);
}

@end

#pragma mark - DURabbitManager

@interface DURabbitManager ()
@property (retain, nonatomic) RabbitConsumer *consumer;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) NSString *routingKey;
@property (strong, nonatomic) NSString *exchange;
@end

@implementation DURabbitManager

+ (instancetype)sharedManager {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("com.duriana.rabbitmq", DISPATCH_QUEUE_CONCURRENT);
        _caCertPemName = @"cacertpem";

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kSignedInStatusChangedNotification object:nil];
    }
    return self;
}

- (void)setServer:(NSString *)rabbitServer stagingServer:(NSString *)rabbitServerStaging port:(NSInteger)port {
        _rabbitServer = rabbitServer;
        _rabbitServerStaging = rabbitServerStaging;
        _port = port;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startWithExchange:(NSString *)exchange routingKey:(NSString *)routingKey success:(void (^)(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage))successBlock failed:(void (^)(void))failedBlock {
    dispatch_async(self.queue, ^{
        self.exchange = exchange;
        self.routingKey = routingKey;
        NSString *cacertpem = [[NSBundle mainBundle] pathForResource:self.caCertPemName ofType:@"pem"];
        RabbitConsumer *consumer = [[RabbitConsumer alloc] initWithHostname:self.enableStaging ? self.rabbitServer : self.rabbitServerStaging port:self.port exchange:exchange routingKey:routingKey cacertpem:cacertpem keypem:nil certpem:nil];
        if (consumer) {
            consumer.callback = ^(NSString *exchange, NSString *routingKey, NSString *type, NSData *data) {
                NSError *error;
                NSDictionary *jsonMessage = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (!error) {
                    if ([type isEqualToString:@"bidding"]) {
                        successBlock(exchange, routingKey, type, jsonMessage);
                    } else {
                        errorLoggerBlock(_f(@"Unknown message type: %@", type));
                    }
                } else {
                    errorLoggerBlock(_f(@"JSON serialization error:\n%@\nmessage:\n%@", error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]));
                }
            };
            consumer.fatalErrorCallback = ^(amqp_rpc_reply_t res) {
                errorLoggerBlock(RabbitErrorString(res, @"Consuming fatal error"));
                self.consumer = nil;
                failedBlock();
            };

            @synchronized(self) {
                [self.consumer stopConsuming];
                self.consumer = consumer;
            }

            // start consuming infinite loop
            [consumer startConsuming];
        } else {
            if (failedBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failedBlock();
                });
            }
        }
    });
}

-(void)sendMesage:(NSString *)message {
    [self.consumer sendMessage:message immedite:NO];
}

- (void)refresh {
    if (self.isSignedIn) {
        NSString *routingKey;
        BOOL isConsuming;

        @synchronized(self) {
            routingKey = self.consumer.routingKey;
            isConsuming = self.consumer.isConsuming;
        }

        if (![routingKey isEqualToString:self.routingKey] || !isConsuming) {
            [self startWithExchange:self.exchange routingKey:self.routingKey success:^(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage) {
                
            } failed:^{
                [self refresh];
            }];
        }
    } else {
        [self stop];
    }
}

- (void)pauseConsuming {
    @synchronized(self) {
        [self.consumer stopConsuming];
    }
}

- (void)resumeConsuming {
    dispatch_async(self.queue, ^{
        [self.consumer startConsuming];
    });
}

- (void)stop {
    @synchronized(self) {
        [self pauseConsuming];
        self.consumer = nil;
    }
}

- (BOOL)isConsuming {
    @synchronized(self) {
        return self.consumer.isConsuming;
    }
}

@end
