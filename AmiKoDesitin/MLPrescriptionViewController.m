//
//  MLPrescriptionViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionViewController.h"
#import "SWRevealViewController.h"

@interface MLPrescriptionViewController ()

@end

@implementation MLPrescriptionViewController

- (void)viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // SWRevealViewController extends UIViewController!
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];

    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:revealController
                                                                        action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    // PanGestureRecognizer goes here
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
