# DURabbitManager
An easy to use RabbitMQ integration to be used in iOS apps

This repository contains source code of the RabbitMQ Objective-C client. The client is maintained by the Duriana team at Duriana Internet.


### Requirements
[![Platform iOS](https://img.shields.io/badge/Platform-iOS-blue.svg?style=fla)]()

### DURabbitManager
[![Objective-c](https://img.shields.io/badge/Language-Objective C-blue.svg?style=flat)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)

Minimum iOS Target: iOS 8.0

### Demo Project

Minimum Xcode Version: Xcode 8.0

### Installation
---

#### Cocoapod Method:

`DURabbitManager` is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

`pod 'DURabbitManager'`

#### Source Code Method:

***Just*** drag and drop `DURabbitManager` directory from demo project to your project. And you can start to use.

### How to use
---

```objc

DURabbitManager *rabbitManager = [DURabbitManager sharedManager];

// setting production and staging server(optional)
[rabbitManager setServer:@"localhost" stagingServer:@"localhost" port:8080];

//  start connection
[rabbitManager startConsumingWithExchange:@"MY" routingKey:@"123" success:^(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage) {
    // connection succeed, receive message in this block
    } failed:^{
    // connection failed
}];
```

### How to Try it out
---

- Install RabbitMQ server on your machine, you can use Homebrew to install on Mac `brew install rabbitmq`
- To be able to connect to it from your iPhone over the LAN, you need to tweak the server config a bit
    - Change the `NODE_IP_ADDRESS=localhost` to `NODE_IP_ADDRESS=0.0.0.0` in `/usr/local/etc/rabbitmq/rabbitmq-env.conf`
    - Change the config in `/usr/local/etc/rabbitmq/rabbitmq.config` to be
    ```
    [{rabbit, [{loopback_users, []}]}].
    ```
    This will enable the default guest user to connect to the server over the network and not only via localhost.
- Run the exmaple app.
- Enter the IP address and port of the server (default port is 5672), and hit connect.
- The app is now waiting for messages to be consumed, to try out you need to send it a message, you can use the RabbitMQ web interface to do so.
- Open `http://localhost:15672/` in the browser, go to exchanges and select MY exchange (the exchange which the example app is using).
- Scroll down to publish message section, enter 123 as routing key (the routing key which is the example app is using), enter the message payload (it should be a valid JSON), lets try `{ "hello": "world" }`, and hit publish message.
- The message now appears on the app, cool!
- That's it, it was easy :)

### TODO
---

- Ability to publish a message from the app, checkout https://github.com/duriana/DURabbitManager/blob/master/DURabbitManager/Classes/DURabbitManager.m#L274

### Contributions
---
Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.
