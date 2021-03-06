# Internal Details
Translating [Core Data] objects to a document store requires some
special treatment. Not only do we desire the resulting remote store to
be as portable as possible to other platforms and architectures, we
need to preserve the Meta Data that [Core Data] requires, and also
make sure that we do not compromise the integrity of each data
"entity".

There are two types of documents in the database:
1. ***Meta Data***: there is only one instance of this document and
   contains information about the rest of the documents in the
   database
1. ***Entity***: Every [Core Data] Entity is represented by a unique
   entity document.

## Meta Data
Each initialized database will contain at least one document that
describes the object model and the [Core Data] Meta Data. The document
ID is "CDTISMetaData" and it is described in the following JSON [Schema], draft v4:

```javascript
// validated by https://json-schema-validator.herokuapp.com/
{
    "id": "CDTISMetaData#",
    "title": "CDTISMetaData Schema",
    "definitions": {
        // We restrict this to C symbol character set
        "symbolicName": {
            "id": "#symbolicName",
            "type": "string",
            "pattern": "^[a-zA-Z][a-zA-Z0-9]*$"
        },

        // Used to contain 512 bit hash
        "hex64": {
            "id": "#hex64",
            "type": "string",
            "pattern": "^[a-fA-F0-9]{64}$"
        },

        // Types we support
        "typeName": {
            "id": "#typeName",
            "enum": [
                // string in UTF-8 encoding
                "utf8",
                // Number 0 for false and anything else for true
                "bool",
                // number of seconds since midnight 1970-01-01 GMT
                "date1970",
                // integer values
                "int16", "int32", "int64",
                // IEEE-754 floating point types
                "double", "float",
                // Large precision decimal values, created by
                // Apple.  Should be avoided for portability,
                "decimal",
                // Transformable Data, the application must provide
                // Class that can transform the stored data into an
                // object usable by the program.
                "xform",
                // An opaque binary WoS
                "binary",
                // Apple Core Data ID URI, this will only be
                // references by Core Data, and if missing will be
                // generated before used.
                "id",
                // Relation (pointer) to single object
                "relation-to-one",
                // Relation to several objects
                "relation-to-many"
            ]
        },

        // this describes the property
        "property": {
            "id": "#property",
            "title": "Property Schema",
            "type": "object",
            "required": [ "versionHash", "name" ],
            "properties": {
                // The hash for this property as generated by Core Data
                "versionHash": { "$ref": "#/definitions/hex64" },
                "typeName": { "$ref": "#/definitions/typeName" },
                // The name of the "class" that can transform the data
                // into a usable object by the platform. Where
                // possible, the mime-type is included to assist in
                // the transformation.
                "xform": { "$ref": "#/definitions/symbolicName" },
                // Destination Entity name for the relation
                "destination": { "$ref": "#/definitions/symbolicName" }
            }
        },

        // Entities are a collection of properties
        "entity": {
            "id": "#entity",
            "title": "Entity Schema",
            "type": "object",
            "required": [ "versionHash", "properties" ],
            "properties": {
                "versionHash": { "$ref": "#/definitions/hex64" },
                "properties": {
                    // A property can have any name, we should
                    // restrict to C symbols but for now we do not.
                    "patternProperties": {
                        "^[^ ]+$": { "$ref": "#/definitions/property" }
                    }
                }
            }
        },

        // Object models describe the stored objects in terms of
        // entities and properties
        "objectModel": {
            "title": "Object Model Schema",
            "type": "object",
            "patternProperties": {
                "^[^ ]+$": { "$ref": "#/definitions/entity" }
            }
        },

        // This is the MetaData as used by Core Data and should be
        // treated as opaque
        "APPLCoreDataMetaData": {
            "title": "Core Data Meta Data Object",
            "type": "object"
        },

        "type": "object",
        "required": [ "metaData", "objectModel" ],
        "properties": {
            "metaData": { "$ref": "#/definitions/APPLCoreDataMetaData" },
            "objectModel": { "$ref": "#/definitions/objectModel" },
            "run": { "type": "string" },
        }
    }
}
```

## Entity Data
All other documents should follow the following schema:

```javascript
// validated by https://json-schema-validator.herokuapp.com/
{
    "title": "CDTISObject",
    "definitions": {
        "symbolicName": {
            "id": "#symbolicName",
            "type": "string",
            "pattern": "^[^ ]+$"
        },

        // The actual storage of a scalar value. In JSON it always
        // comes down to either a number or a string
        "attribute": {
            "id": "#attribute",
            "oneOf": [
                {"type": "string"},
                {"type": "number"}
            ]
        },

        // The string is a Document ID in the database
        "relationToOne": {
            "id": "#relationToOne",
            "type": "string"
        },

        // This is array of Document IDs in the database
        "relationToMany": {
            "id": "#relationToMany",
            "type": "array",
            "items": {"$ref": "#/definitions/relationToOne" }
        },

        // A property is either an attribute or a relation
        "property": {
            "id": "#property",
            "oneOf": [
                { "$ref": "#/definitions/attribute" },
                { "$ref": "#/definitions/relationToOne" },
                { "$ref": "#/definitions/relationToMany" }
            ]
        },

        // The properties that are prefixed with "CDTISMeta_" are
        // objects that contain additional information to support the
        // accurate storage of the data.

        // Binary and Transformable objects have a MIME type
        "metaDataForBinary": {
            "id": "#metaDataForBinary",
            "type": "object",
            "required": [ "mime-type" ],
            "properties": {
                "mime-type": { "type": "string" }
            }
        },

        // Floating Non-Finite values like NaN and +/-Infinity
        // cannot be stored as JSON, so we have added an extra
        // property to capture this.
        "metaDataForFloatNonFinite": {
            "id": "#metaDataForFloatNonFinite",
            "enum": [ "infinity", "-infinity", "nan" ]
        },

        // IEEE single precision floating point values are
        // additionally represented as an integer that captures the
        // 32-bit image.  In C this is can be expressed as:
        //   uint32_t img = *((uint32_t *)&double_num);
        "metaDataForFloatSingle": {
            "id": "#metaDataForFloatSingle",
            "type": "object",
            "required": [ "ieee754_single" ],
            "properties": {
                "nonFinite": { "$ref": "#/definitions/metaDataForFloatNonFinite" },
                "ieee754_single": {"type": "integer" }
            }
        },

        // IEEE double precision floating point values are
        // additionally represented as an integer that captures the
        // 64-bit image.  In C this is can be expressed as:
        //   uint64_t img = *((uint64_t *)&double_num);
        "metaDataForFloatDouble": {
            "id": "#metaDataForFloatDouble",
            "type": "object",
            "required": [ "ieee754_double" ],
            "properties": {
                "nonFinite": { "$ref": "#/definitions/metaDataForFloatNonFinite" },
                "ieee754_double": {"type": "integer" }
            }
        },

        // Apple has a type called NSDecimal, we discourage its use
        // since it is not portable, but we allow it in case the
        // application does not care.
        // The image is a base64 encoding of the structure binary
        "metaDataForNSDecimal": {
            "id": "#metaDataForNSDecimal",
            "type": "object",
            "required": [ "nsdecimal" ],
            "properties": {
                "nonFinite": { "$ref": "#/definitions/metaDataForFloatNonFinite" },
                "nsdecimal": {"type": "string" }
            }
        },

        "metaData": {
            "id": "#metaData",
            "oneOf": [
                { "$ref": "#/definitions/metaDataForBinary" },
                { "$ref": "#/definitions/metaDataForFloatSingle" },
                { "$ref": "#/definitions/metaDataForFloatDouble" },
                { "$ref": "#/definitions/metaDataForNSDecimal" }
            ]
        }
    },

    "type": "object",
    "required": [
        "CDTISEntityName"
    ],

    "properties" : {
        // The entity that this data property belongs to
        "CDTISEntityName": { "$ref": "#/definitions/symbolicName" },

        // URI Generated by Core Data to track this object.  Should
        // never be removed, but this document is not created by Core
        // Data, it can be missing and will be generated once a core
        // data application sees it... I hope
        "CDTISIdentifier": { "type": "string" },

        // I'm only guessing I need this.. probably don't
        "CDTISObjectVersion": { "type": "string" },
    },
    "patternProperties": {
        // Regular properties need to be excluded, is there a better way?
        "^!(CDTIS)[^ ]+$": { "$ref": "#/definitions/property" },
        "^CDTISMeta_[^ ]+$": { "$ref": "#/definitions/metaData" }
    }
}

```


<!-- refs -->

[core data]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/cdProgrammingGuide.html "Introduction to Core Data Programming Guide"

[schema]: http://json-schema.org/ "The home of JSON Schema"


<!--  LocalWords:  CDTISMetaData JSON javascript symbolicName zA fA
 -->
<!--  LocalWords:  typeName enum UTF utf bool IEEE precisionion xform
 -->
<!--  LocalWords:  WoS URI versionHash patternProperties objectModel
 -->
<!--  LocalWords:  MetaData APPLCoreDataMetaData metaData CDTISObject
 -->
<!--  LocalWords:  oneOf relationToOne relationToMany CDTISMeta NaN
 -->
<!--  LocalWords:  metaDataForBinary metaDataForFloatNonFinite nan
 -->
<!--  LocalWords:  uint img num metaDataForFloatSingle ieee nonFinite
 -->
<!--  LocalWords:  metaDataForFloatDouble NSDecimal incase nsdecimal
 -->
<!--  LocalWords:  metaDataForNSDecimal CDTISEntityName propery CDTIS
 -->
<!--  LocalWords:  CDTISIdentifier CDTISObjectVersion
 -->
