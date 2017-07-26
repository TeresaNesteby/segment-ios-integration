# Segment-Kahuna Wrapper 

[![Version](https://img.shields.io/cocoapods/v/Segment-Kahuna.svg?style=flat)](http://cocoapods.org/pods/Segment-Kahuna)
[![License](https://img.shields.io/cocoapods/l/Segment-Kahuna.svg?style=flat)](http://cocoapods.org/pods/Segment-Kahuna)

Kahuna integration for analytics-ios.

## Installation

To install the Segment-Kahuna integration, simply add this line to your [CocoaPods](http://cocoapods.org) `Podfile`:

```ruby
pod "Segment-Kahuna"
```

## Usage

After adding the dependency, you must register the integration.  To do this, import the Kahuna integration in your `AppDelegate`:

```
#import <Segment-Kahuna/SEGKahunaIntegrationFactory.h>
```

And add the following lines:

```
NSString *const SEGMENT_WRITE_KEY = @" ... ";
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];

[config use:[SEGKahunaIntegrationFactory instance]];

[SEGAnalytics setupWithConfiguration:config];

```
