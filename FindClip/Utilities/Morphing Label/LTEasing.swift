//
//  LTEasing.swift
//  LTMorphingLabelDemo
//
//  Created by Lex on 7/1/14.
//  Copyright (c) 2015 lexrus.com. All rights reserved.
//

import Foundation

// http://gsgd.co.uk/sandbox/jquery/easing/jquery.easing.1.3.js
// t = currentTime
// b = beginning
// c = change
// d = duration

public enum LTEasing {
    public static func easeOutQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float = 1.0) -> Float {
        return { (f: Float) in
            c * (pow(f, 5) + 1.0) + b
        }(t / d - 1.0)
    }
    
    public static func easeInQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float = 1.0) -> Float {
        return { (f: Float) in
            c * pow(f, 5) + b
        }(t / d)
    }
    
    public static func easeOutBack(_ t: Float, _ b: Float, _ c: Float, _ d: Float = 1.0) -> Float {
        let s: Float = 2.70158
        let t2: Float = t / d - 1.0
        return Float(c * (t2 * t2 * ((s + 1.0) * t2 + s) + 1.0)) + b
    }
    
    public static func easeOutBounce(_ t: Float, _ b: Float, _ c: Float, _ d: Float = 1.0) -> Float {
        return { (f: Float) in
            if f < 1 / 2.75 {
                return c * 7.5625 * f * f + b
            } else if f < 2 / 2.75 {
                let t = f - 1.5 / 2.75
                return c * (7.5625 * t * t + 0.75) + b
            } else if f < 2.5 / 2.75 {
                let t = f - 2.25 / 2.75
                return c * (7.5625 * t * t + 0.9375) + b
            } else {
                let t = f - 2.625 / 2.75
                return c * (7.5625 * t * t + 0.984375) + b
            }
        }(t / d)
    }
}
