//
//  ALTargetingData.h
//  sdk
//
//  Created by Basil on 9/18/12.
//
//

#import <Foundation/Foundation.h>

@interface ALTargetingData : NSObject

#define kALGenderMale        'm'
#define kALGenderFemale      'f'

/**
 * Set carrier current device is on.
 */
@property(strong, nonatomic) NSString * carrier;

/**
 * Set a two-character ISO 3166-1 country code of the device.
 */
@property(strong, nonatomic) NSString * country;

/**
 * Set the year of birth of current user.
 */
@property(assign, nonatomic) UInt16 birthYear;

/**
 * Gender of the  current user. 
 * <p>
 * Following constants contain supported values: <code>kALGenderMale</code> and
 * <code>kALGenderFemale</code>.
 */
@property(assign, nonatomic) char gender;

/**
 * The language of the current user. Language is expressed as two-character
 * ISO 639-1 language code.
 */
@property(strong, nonatomic) NSString * language;

/**
 * Keywords for the application.
 */
@property(strong, nonatomic) NSArray * keywords;

/**
 * Interests for the user.
 */
@property(strong, nonatomic) NSArray * interests;

/**
 * Set the location of current user. The location represented as
 * longiture and latitude
 */
-(void) setLocationWithLatitude: (double) latitude longitude: (double)longitude;

/**
 * Put an extra targeting parameter
 *
 * @param key Key of the parameter. Must not be null.
 * @param value Parameter value.
 */
-(void) setExtraValue: (NSString *) value forKey: (NSString *)key;

/**
 * Clear all saved targeting data
 */
-(void) clearAll;

@end
