# DURabbitManager
An easy to use RabbitMQ integration to be used in iOS apps

This repository contains source code of the RabbitMQ Objective C client. The client is maintained by the Duriana team at Duriana Internet.

## Requirements
[![Platform iOS](https://img.shields.io/badge/Platform-iOS-blue.svg?style=fla)]()

#### DURabbitManager:-
[![Objective-c](https://img.shields.io/badge/Language-Objective C-blue.svg?style=flat)](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)

Minimum iOS Target: iOS 8.0

#### Demo Project:-

Minimum Xcode Version: Xcode 7.3

Installation
---

#### Cocoapod Method:-

***DURabbitManager (Objective-C):-*** DURabbitManager is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

`pod 'DURabbitManager'`

#### Source Code Method:-

***DURabbitManager (Objective-C):-*** Just ***drag and drop*** `DURabbitManager` directory from demo project to your project. And you can start to use.

How to use
---

```objc

DURabbitManager *rabbitManager = [DURabbitManager sharedManager];

// setting production and staging server(optional)
[rabbitManager setServer:@"localhost" stagingServer:@"localhost" port:8080];

//  start connection
[rabbitManager startWithExchange:@"" routingKey:@"hello" success:^(NSString *exchange, NSString *routingKey, NSString *type, NSDictionary *jsonMessage) {
    // connection succeed, receive message in this block
    } failed:^{
    // connection failed  
}];

// send message via created connection
[rabbitManager sendMesage:@"Hello World!" immedite:NO];

```
Contributions
---
Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.