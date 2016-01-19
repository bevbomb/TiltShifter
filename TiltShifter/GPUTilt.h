//
//  GPUTilt.h
//  TiltShifter
//
//  Created by Throwr on 19/01/2016.
//  Copyright © 2016 Throwr Pty Ltd. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface GPUTilt : GPUImageGaussianSelectiveBlurFilter

@property (readwrite, nonatomic) BOOL isRadial;
@end
