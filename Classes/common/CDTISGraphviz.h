//
//  CDTISGraphviz.h
//  CDTIncrementalStore
//
//  Created by Jimi Xenidis on 2/14/15.
//
//  Copyright (c) 2015 IBM. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <CoreData/CoreData.h>
#import <CloudantSync.h>
#import "CDTIncrementalStore.h"
#import "CDTISObjectModel.h"

/**
 *  CDTISGraphviz creates a graph representation of the datastore using the
 *  [Graphviz](http://www.graphviz.org/) "dot" format.
 *  See the Graphviz docuementation on how to display the output.
 */

@interface CDTISGraphviz : NSObject

/**
 *  This creates the "dot" output
 *
 *  @param datastore The Datastore to graph
 *  @param objectModel The object model that decribes the datastore
 *
 *  @return NSData stucture or `nil` on error
 */
+ (NSData *)dotDatastore:(CDTDatastore *)datastore withObjectModel:(CDTISObjectModel *)objectModel;

@end
