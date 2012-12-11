//
//  AppDelegate.m
//  OsceletonWrapper
//
//  Created by Edwin Guggenbichler on 12/6/12.
//  Copyright (c) 2012 GraftInc. All rights reserved.
//

#import "AppDelegate.h"
#import <VVOSC/VVOSC.h>

#define INPORT  12350
#define OUTPORT 12340

@interface AppDelegate()
@property (strong) OSCManager   *manager;
@property (strong) OSCInPort    *inPort;
@property (strong) OSCOutPort   *outPort;
@property (weak) IBOutlet NSTextField *outPortTextField;
@property (strong) NSTask       *osceleton;
@end

@implementation AppDelegate
- (IBAction)textFieldDidChange:(id)sender {
    self.outPort.port = [self.outPortTextField integerValue];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    //    NSArray *runningApplications = [[NSWorkspace  sharedWorkspace] runningApplications];
    //
    //    for (NSRunningApplication *app in runningApplications) {
    //        NSLog(@"name: %@ - pid: %d",[app localizedName], [app processIdentifier]);
    //        if ([[app localizedName] isEqualToString:@"OsceletonWrapper"])
    //        {
    //            [app forceTerminate];
    //            while ( app.terminated == NO) {}
    //            break;
    //        }
    //    }
    
    
    self.osceleton = [[NSTask alloc] init];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"osceleton" ofType:@""];
    
    [self.osceleton setLaunchPath:filePath];
    
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-r", @"-p", @"12350", nil];
    [self.osceleton setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [self.osceleton setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    
    [self.osceleton launch];
    
    
    
    //    NSData *data;
    //    data = [file readDataToEndOfFile];
    //
    //
    //    NSString *string;
    //    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //    NSLog (@"%@", string);
    
    self.manager = [[OSCManager alloc] init];
    [self.manager setDelegate:self];
    
    self.inPort = [self.manager createNewInput];
    [self.inPort setPort:INPORT];
    self.outPort = [self.manager createNewOutputToAddress:@"127.0.0.1" atPort:OUTPORT];
}

- (void) receivedOSCMessage:(OSCMessage *)m	{
    //    NSLog(@"message: %@", m);
    
    NSString *outString = nil;
    
    if (m.valueCount > 1) {
        OSCValue *value = [m.valueArray objectAtIndex:0];
        
        if (value.type == OSCValString)
        {
            outString = [NSString stringWithFormat:@"%@/%@",m.address,[value stringValue]];
        }
    }
    
    
    
    //    NSLog(@"newMessage: %@",outString);
    
    
    
    OSCMessage *newMsg = [OSCMessage createWithAddress:outString];
    
    for (int i = 2; i < m.valueCount; i++)
    {
        OSCValue *value = [m.valueArray objectAtIndex:i];
        [newMsg addValue:value];
        
        //        if ([outString isEqualToString:@"/joint/r_hand"] && i == 4)
        //        {
        //            NSLog(@"ValueX: %f",[value floatValue] );
        //        }
    }
    
    [self.outPort sendThisMessage:newMsg];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.osceleton terminate];
    [self.osceleton waitUntilExit];
    NSLog(@"terminated");
}

@end