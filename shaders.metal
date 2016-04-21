//
//  shaders.metal
//  InstaClip Player
//
//  Created by John Weeks on 10/16/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant half4 rgbaBlack = half4(0.0, 0.0, 0.0, 1.0);
constant half4 rgbaGrey = half4(169.0/255.0, 169.0/255.0, 169.0/255.0, 1.0);
constant half4 rgbaWhite = half4(1.0, 1.0, 1.0, 1.0);

struct Vertex {
    float4 position [[position]];
};

struct Uniform {
    float widthPixel;
    float leftTrimXPixel;
    float rightTrimXPixel;
};

vertex Vertex basic_vertex(constant Uniform &uniform [[buffer(0)]],
                           const device float* vertex_array [[buffer(1)]],
                           unsigned int vid [[vertex_id]]) {

    // calc x based on vertex index
    // need to paramaterize, will be different in portrait, landscape
    //float x = (vid/2) * (1.0 / (749.0/2.0)) - 1.0;
    //float x = (vid/2) * (1.0 / ((1334.0-1.0)/2.0)) - 1.0;
    float x = (vid/2) * (1.0 / ((uniform.widthPixel-1.0)/2.0)) - 1.0;
    Vertex vert;
    vert.position = float4(x, vertex_array[vid], 0.0, 1.0);
    return vert;
}

fragment half4 basic_fragment(Vertex vert [[stage_in]],
                              constant Uniform &uniform [[buffer(0)]]) {
    if (vert.position.x > uniform.leftTrimXPixel && vert.position.x < uniform.rightTrimXPixel) {
        return rgbaGrey;
    } else {
        return rgbaWhite;
    }
}
