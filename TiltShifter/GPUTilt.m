//
//  GPUTilt.m
//  TiltShifter
//
//  Created by Throwr on 19/01/2016.
//  Copyright © 2016 Throwr Pty Ltd. All rights reserved.
//

#import "GPUTilt.h"
#import "GPUImageGaussianSelectiveBlurFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageTwoInputFilter.h"

NSString *const kGPUImageGaussianSelectiveBlurFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 uniform highp float aspectRatio;
 uniform highp float angle;
 uniform lowp float isRadialBlur;
 
 void main()
 {
     lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     highp float distanceFromCenter;
     if ( isRadialBlur == 0 ) {
         // for radial blur
         highp vec2 textureCoordinateToUse = vec2(textureCoordinate2.x, (textureCoordinate2.y  + 0.5 - 0.5 * aspectRatio));
         distanceFromCenter = distance(excludeCirclePoint, textureCoordinateToUse);
     } else {
         // for linear blur
         distanceFromCenter = abs((textureCoordinate2.x - excludeCirclePoint.x)*aspectRatio*cos(angle) + (textureCoordinate2.y-excludeCirclePoint.y)*sin(angle));
     }
     
     gl_FragColor = mix(sharpImageColor, blurredImageColor, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, distanceFromCenter));
 }
 );

@implementation GPUTilt
@synthesize isRadial = _isRadial;

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    hasOverriddenAspectRatio = NO;
    _isRadial = false;

    
    return self;
}

- (void)setIsRadial:(BOOL)isRadial;
{
    _isRadial = isRadial;

    
    [selectiveFocusFilter setFloat:[NSNumber numberWithBool:_isRadial].floatValue forUniformName:@"isRadialBlur"];
}

@end
