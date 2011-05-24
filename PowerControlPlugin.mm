#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManager2.h>
#import <SpringBoard/SpringBoard.h>
#import <BluetoothManager/BluetoothManager.h>
#import <objc/runtime.h>
#include "Plugin.h"

// tethering
@class PSSpecifier;
@interface WirelessModemController : NSObject {
}
- (id)internetTethering:(PSSpecifier *)specifier;
- (void)setInternetTethering:(id)value specifier:(PSSpecifier *)specifier;
@end


// plugin
@interface PowerControlPlugin : NSObject <LIPluginController, LITableViewDelegate, UITableViewDataSource> 
{
	WirelessModemController *wirelessModemController;
  SBTelephonyManager *telephonyManager;
  BluetoothManager *bluetoothManager;
  SBWiFiManager *wiFiManager;
  SBOrientationLockManager *orientationLockManager;
  LIStyle *disabledStyle;
  LIStyle *enabledStyle;
}

@property (nonatomic, retain) LIPlugin *plugin;
@property (nonatomic, retain) LILabel *wifiLabel;
@property (nonatomic, retain) LILabel *locationLabel;
@property (nonatomic, retain) LILabel *tetheringLabel;
@property (nonatomic, retain) LILabel *bluetoothLabel;
@property (nonatomic, retain) LILabel *airplaneModeLabel;
@property (nonatomic, retain) LILabel *orientationLockLabel;

// wifi
- (void)flipWifi;
- (BOOL)wiFiEnabled;

// bluetooth
- (void)flipBluetooth;
- (BOOL)bluetoothEnabled;

// location
- (void)flipLocation;
- (BOOL)locationEnabled;

// airplane mode
- (void)flipAirplaneMode;
- (BOOL)airplaneModeEnabled;

// tethering
- (void)flipTethering;
- (BOOL)tetheringEnabled;

// orientation lock
- (void)flipOrientationLock;
- (BOOL)orientationLocked;

// ui update
- (void)update;

@end

@implementation PowerControlPlugin

@synthesize plugin, wifiLabel, locationLabel, tetheringLabel, bluetoothLabel, airplaneModeLabel, orientationLockLabel;

- (id)initWithPlugin:(LIPlugin*)thePlugin
{
	self = [super init];
	self.plugin = thePlugin;

	plugin.tableViewDataSource = self;
	plugin.tableViewDelegate = self;

  // tethering
  NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/WirelessModemSettings.bundle"];
  [bundle load];
  Class cls = objc_getClass("WirelessModemController");
  wirelessModemController = [[cls alloc] init];
  [bundle unload];

  // airplane
  telephonyManager = [objc_getClass("SBTelephonyManager") sharedTelephonyManager];

  // bluetooth
  bluetoothManager = [objc_getClass("BluetoothManager") sharedInstance];

  // wifi
  wiFiManager = [objc_getClass("SBWiFiManager") sharedInstance];

  // orientation lock
  orientationLockManager = [objc_getClass("SBOrientationLockManager") sharedInstance];

  // style
  disabledStyle = nil;
  enabledStyle = nil;

  // notification
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(update) name:LITimerNotification object:nil];
	[center addObserver:self selector:@selector(update) name:LIViewReadyNotification object:nil];

	return self;
}

- (void)dealloc
{
  [wirelessModemController release];

  self.wifiLabel = nil;
  self.locationLabel = nil;
  self.tetheringLabel = nil;
  self.bluetoothLabel = nil;
  self.airplaneModeLabel = nil;
  self.orientationLockLabel = nil;

  [disabledStyle release];
  [enabledStyle release];

  [super dealloc];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 1;
}

- (CGFloat)tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (disabledStyle == nil) {
    disabledStyle = tableView.theme.detailStyle;
    enabledStyle = tableView.theme.summaryStyle;
  }
  return [tableView defaultHeightForRow] * 2;
}

- (LILabel *)labelWithFrame:(CGRect)frame tableView:(LITableView *)tableView action:(SEL)action
{
  LILabel *label = [tableView labelWithFrame:frame];
  label.textAlignment = UITextAlignmentCenter;
  label.numberOfLines = 2;
  label.backgroundColor = [UIColor clearColor];

  if (action != nil) {
    UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    [label addGestureRecognizer:recognizer];
    [recognizer release];
  }

  return label;
}

#pragma mark LIPluginController
- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PowerControl"];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];

    float width = cell.contentView.frame.size.width / 3;
    // float height = cell.contentView.frame.size.height / 2;
    float height = [tableView defaultHeightForRow];
    float x = 0;
    float y = 0;

    self.wifiLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipWifi)];
    [cell.contentView addSubview:self.wifiLabel];
    x += width;

    self.locationLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipLocation)];
    [cell.contentView addSubview:self.locationLabel];
    x += width;

    self.bluetoothLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipBluetooth)];
    [cell.contentView addSubview:self.bluetoothLabel];
    x += width;

    x = 0;
    y += height;

    self.tetheringLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipTethering)];
    [cell.contentView addSubview:self.tetheringLabel];
    x += width;

    self.airplaneModeLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipAirplaneMode)];
    [cell.contentView addSubview:self.airplaneModeLabel];
    x += width;

    self.orientationLockLabel = [self labelWithFrame:CGRectMake(x, y, width, height) tableView:tableView action:@selector(flipOrientationLock)];
    [cell.contentView addSubview:self.orientationLockLabel];
    x += width;
  }

  [self update];

  return cell;
}

// wifi
- (void)flipWifi
{
  [wiFiManager setWiFiEnabled:![self wiFiEnabled]];

  [self update];
}

- (BOOL)wiFiEnabled
{
  return [wiFiManager wiFiEnabled];
}

// bluetooth
- (void)flipBluetooth
{
  [bluetoothManager setEnabled:![self bluetoothEnabled]];

  sleep(1);

  [self update];
}

- (BOOL)bluetoothEnabled
{
  return [bluetoothManager enabled];
}

// location
- (void)flipLocation
{
  [CLLocationManager setLocationServicesEnabled:![self locationEnabled]];

  [self update];
}

- (BOOL)locationEnabled
{
  return [CLLocationManager locationServicesEnabled];
}

// airplane mode
- (void)flipAirplaneMode
{
  [telephonyManager setIsInAirplaneMode:![self airplaneModeEnabled]];

  [self update];
}

- (BOOL)airplaneModeEnabled
{
  return [telephonyManager isInAirplaneMode];
}

// tethering
- (void)flipTethering
{
  [wirelessModemController setInternetTethering:[NSNumber numberWithBool:![self tetheringEnabled]] specifier:nil];

  [self update];
}

- (BOOL)tetheringEnabled
{
  return [[wirelessModemController internetTethering:nil] boolValue];
}

// orientationLock
- (void)flipOrientationLock
{
  [self orientationLocked] ? [orientationLockManager unlock] : [orientationLockManager lock];

  [self update];
}

- (BOOL)orientationLocked
{
  return [orientationLockManager isLocked];
}

// update view
- (void)update
{
  if (!self.plugin.enabled) {
    return;
  }

  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  self.wifiLabel.text = [@"WiFi\n" stringByAppendingString:[self wiFiEnabled] ? @"On" : @"Off"];
  self.wifiLabel.style = [self wiFiEnabled] ? enabledStyle : disabledStyle;

  self.locationLabel.text = [@"Location\n" stringByAppendingString:[self locationEnabled] ? @"On" : @"Off"];
  self.locationLabel.style = [self locationEnabled] ? enabledStyle : disabledStyle;

  self.bluetoothLabel.text = [@"Bluetooth\n" stringByAppendingString:[self bluetoothEnabled] ? @"On" : @"Off"];
  self.bluetoothLabel.style = [self bluetoothEnabled] ? enabledStyle : disabledStyle;

  self.tetheringLabel.text = [@"Tethering\n" stringByAppendingString:[self tetheringEnabled] ? @"On" : @"Off"];
  self.tetheringLabel.style = [self tetheringEnabled] ? enabledStyle : disabledStyle;

  self.airplaneModeLabel.text = [@"Airplane Mode\n" stringByAppendingString:[self airplaneModeEnabled] ? @"On" : @"Off"];
  self.airplaneModeLabel.style = [self airplaneModeEnabled] ? enabledStyle : disabledStyle;
  
  self.orientationLockLabel.text = [@"Orientation\n" stringByAppendingString:[self orientationLocked] ? @"Locked" : @"Unlocked"];
  self.orientationLockLabel.style = [self orientationLocked] ? enabledStyle : disabledStyle;

  [pool release];
}

@end
