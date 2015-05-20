# Portability Issues

To do this we try to use more generic descriptions for the "meta"
information.  Here we describe some of the more difficult [Core Data]
types.

## Time
The number of seconds from January 1, 1970 at 12:00 a.m. GMT.

## Binary Data
Binary data, where the programmer gives no indication of type is
described as "base64" and should be considered of mime-type
"application/octet-stream".

## Transformable Data
[Core Data] applications can provide a class that can transform an
object into some serialized form.  The name of this "Transformer
Class" and the mime-type is stored along with the base64 encoding of
the result.  The mime-type by default is "application/octet-stream".

To increase portability, it is recommended, where possible, that the
programmer add an additional class method called `+MIMEType` that
returns the mime-type of encoded result.  Example method for a class
that transforms to a PNG image.

```objc
+ (NSString *)MIMEType {
    return @"image/png";
}
```

## Arbitrary Decimal Numbers
The `NSDecimalNumber` is described by Apple as:
>  An instance can represent any number that can be expressed as
>  mantissa x 10^exponent where mantissa is a decimal integer up to 38
>  digits long, and exponent is an integer from –128 through 127.

This number is represented in the data-store as a string representation.
> ***Note***: unfortunately this means that you cannot really use this
> value for any predicate based fetches since proper comparison is
> currently impossible.

## Special Floating Point Values
The values `+/-infinity` and `NaN` cannot be expressed in a JSON based
store so they are tokenized accordingly.  In an effort to make
`+/-infinity` evaluated in your predicates, we give them a value of
`+/-MAX_FLT`. See the discussion on Doubles below.

## Double values
Depending on your JSON library, the string encoding and decoding of
doubles can lose some detail.

> ***Note***: This loss of detail may effect how your predicate
> evaluations work.

Regardless of this loss, it is important that the precise original
double value is restored for the [Core Data] objects.  In order to
deal with this inevitable corruption, we also store the IEEE 754
64-bit image as an integer number.

> ***Note***: Since we store the image as a number, there are ***no
> endian issues***.


<!-- refs -->

[core data]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/cdProgrammingGuide.html "Introduction to Core Data Programming Guide"




<!--  LocalWords:  MIMEType PNG objc NSString png NSDecimalNumber NaN
 -->
<!--  LocalWords:  JSON tokenized IEEE endian
 -->
