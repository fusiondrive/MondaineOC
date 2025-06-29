//
//  ViewController.m
//  MondaineOC
//
//  Created by Steve on 2025/6/29.
//

#import "ViewController.h"
#import "ClockView.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ClockView *clockView = [[ClockView alloc] initWithFrame:self.view.bounds];
    
    clockView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.view addSubview:clockView];

}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
