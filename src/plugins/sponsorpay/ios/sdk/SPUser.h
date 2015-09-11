//
//  SPUser.h
//  SponsorPaySDK
//
//  Created by Piotr  on 08/07/14.
//  Copyright (c)2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPUserConstants.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

/**
 * Object that contains the information about the user. This is used to create segments of users.
 *
 */
@interface SPUser : NSObject

///-------------------------
/// Setters
///-------------------------

/**
 *  Sets the user's age.
 *
 *  @param age Age of the user. Pass `SPEntryIgnore` if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setAge:(NSInteger)age;

/**
 *  Sets the user's date of birth.
 *
 *  @param date Date of birth of the user. Pass `nil` if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setBirthdate:(NSDate *)date;

/**
 *  Sets the user's gender.
 *
 *  @param gender Gender of the user. Pass SPUserGenderUndefined if value needs to be ignored or to be removed, if already exists.
 * 
 *  @since v7.0.0
 */
- (void)setGender:(SPUserGender)gender;

/**
 *  Sets the user's sexual orientation.
 *
 *  @param sexualOrientation Sexual orientation of the user. Pass SPUserSexualOrientationUndefined if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setSexualOrientation:(SPUserSexualOrientation)sexualOrientation;

/**
 *  Sets the user's ethnicity.
 *
 *  @param ethnicity Ethnicity of the user. Pass SPUserEthnicityUndefined if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setEthnicity:(SPUserEthnicity)ethnicity;

/**
 *  Set the user's location.
 *
 *  @param geoLocation takes CLLocation. Pass nil if location needs to be ignored or to be removed, if already exists.
 * 
 *  @since v7.0.0
*/
- (void)setLocation:(CLLocation *)geoLocation;

/**
 *  Sets the user's marital status
 *
 *  @param status Marital status of the user. Pass SPUserMaritalStatusUndefined if value needs to be ignored or to be removed if already exists.
 *
 *  @since v7.0.0
 */
- (void)setMaritalStatus:(SPUserMaritalStatus)status;

/**
 *  Sets the user's number of children
 *
 *  @param numberOfChildren The number of children.
 */
- (void)setNumberOfChildren:(NSInteger)numberOfChildren;
/**
 *  Sets the user's annual household income.
 *
 *  @param income Annual household income of the user. Pass `SPEntryIgnore` if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setAnnualHouseholdIncome:(NSInteger)income;

/**
 *  Sets the user's educational background.
 *
 *  @param education Education of the user. Pass SPUserEducationUndefined if value needs to be ignored or to be removed, if already exists.
 *
 */
- (void)setEducation:(SPUserEducation)education;

/**
 *  Sets the user's zipcode.
 *
 *  @param zipcode Zipcode of the current living place of the user. Pass `nil` if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setZipcode:(NSString *)zipcode;

/**
 *  Set the user's list of interests.
 *
 *  @param interests List of interests of the user. Pass `nil` if value needs to be ignored or to be removed, if already exists.
 *
 *  @since v7.0.0
 */
- (void)setInterests:(NSArray *)interests;

/**
 *  Sets if in-app purchases are enabled.
 *
 *  @param flag Sets if in-app purchases are enabled.
 *
 *  @since v7.0.0
 */
- (void)setIap:(BOOL)flag;

/**
 *  Sets the amount that the user has already spent on in-app purchases.
 *
 *  @param amount The amount of money that the user has spent.
 *
 *  @since v7.0.0
 */
- (void)setIapAmount:(CGFloat)amount;

/**
 *  Sets the number of sessions.
 *
 *  @param numberOfSessions The number of sessions that had already been started
 *
 *  @since v7.0.0
 */
- (void)setNumberOfSessions:(NSInteger)numberOfSessions;

/**
 *  Sets the time spent on the current session.
 *
 *  @param timestamp The time spent on the current session.
 *
 *  @since v7.0.0
 */
- (void)setPsTime:(NSTimeInterval)timestamp;

/**
 *  Sets the duration of the last session.
 *
 *  @param session The duration of the last session.
 *
 *  @since v7.0.0
 */
- (void)setLastSession:(NSTimeInterval)session;

/**
 *  Sets the connection type used by the user
 *
 *  @param connectionType The connection type used by the user.
 *
 *  @see SPUserConnectionType
 *
 *  @since v7.0.0
 */
- (void)setConnectionType:(SPUserConnectionType)connectionType;

/**
 *  Sets the device used by the user.
 *
 *  @param device The device used by the user.
 *
 *  @see SPUserDevice
 *
 *  @since v7.0.0
 */
- (void)setDevice:(SPUserDevice)device;

/**
 *  Sets the app version.
 *
 *  @param version The version of the app that's currently executed.
 *
 *  @since v7.0.0
 */
- (void)setVersion:(NSString *)version;

/**
 *  Sets custom parameters that will be sent along with the standards parameters.
 *
 *  @param parameters The custom parameters that must be set
 *
 *  @since v7.0.0
 */
- (void)setCustomParameters:(NSDictionary *)parameters;

///-------------------------
/// Getters
///-------------------------

/**
 *  Returns the age of the user previously set using `-setAge:`
 *
 *  @return Age of the user. If the age is not added it returns `SPEntryIgnore`
 *
 *  @since v7.0.0
 */
- (NSInteger)age;

/**
 *  Returns the date of birth of the user previously set using `-setBirthDate:`
 *
 *  @return Date of birth of the user. If the birthdate is not added it returns `nil`
 *
 *  @since v7.0.0
 */
- (NSDate *)birthdate;

/**
 *  Returns the gender of the user previously set using `-setGender:`
 *
 *  @return Gender of the user. If the gender is not added it returns `SPUserGenderUndefined`
 *
 *  @since v7.0.0
 */
- (SPUserGender)gender;

/**
 *  Returns the sexual orientation of the user previously set using `-setSexualOrientation:`
 *
 *  @return Sexual orientation of the user. If sexual orientation is not added it returns `SPUserSexualOrientationUndefined`
 *
 *  @since v7.0.0
 */
- (SPUserSexualOrientation)sexualOrientation;

/**
 *  Returns the ethnicity of the user previously set using `-setEthnicity:`
 *
 *  @return Ethnicity of the user. If the ethnicity is not added it returns `SPUserEthnicityUndefined`
 *
 *  @since v7.0.0
 */
- (SPUserEthnicity)ethnicity;

/**
 *  Returns the current location of the user
 *
 *  @return User's current location. If location is not added it returns nil
 *
 *  @since v7.0.0
 */
- (CLLocation *)location;

/**
 *  Returns the marital status of the user previously set using `-setMaritalStatus:`
 *
 *  @return SPUserMaritalStatus type of user's marital status. If marital status is not added it returns `SPUserMaritalStatusUndefined`
 *
 *  @since v7.0.0
 */
- (SPUserMaritalStatus)maritalStatus;

/**
 *  Returns the number of childre of the user previously set using `-setNumberOfChildren:`
 *
 *  @return The number of children from the user.
 */
- (NSInteger)numberOfChildren;

/**
 *  Returns the information about the annual household income of the user previously set using `-setAnnualHouseholdIncome:`
 *
 *  @return Annual household income of the user. If annual household income is not added it returns `SPEntryIgnore`
 *
 *  @since v7.0.0
 */
- (NSInteger)annualHouseholdIncome;

/**
 *  Returns the education background of the user previously set using `-setEducation:`
 *
 *  @return SPUserEducation type of user's educational status. If education is not added it returns `SPUserEducationUndefined`
 *
 *  @since v7.0.0
 */
- (SPUserEducation)education;

/**
 *  Returns the zipcode of the user previously set using `-setZipCode:`
 *
 *  @return Zipcode of the current living place of the user
 *
 *  @since v7.0.0
 */
- (NSString *)zipcode;

/**
 *  Returns the list of interests of the user previously set using `-setInterests:`
 *
 *  @return Array containing strings of interests of current user
 *
 *  @since v7.0.0
 */
- (NSArray *)interests;

/**
 *  Requests user values in dictionary.
 *
 *  @return Dictionary containing all set up values for current user
 *
 *  @since v7.0.0
 */
- (NSDictionary *)data;

/**
 *  Returns the user values in dictionary with current location.
 *
 *  @param completionBlock The block to be executed on the completion of request. This block has no return value and takes 1 argument: the dictionary containing all set up values for current user including latest location. Location however is included ONLY if the user's app has `Core Location` service enabled or the location was not set manually by calling `-setLocation:`, otherwise the location is not included in returned dictionary.
 *
 *  @note Setting manually location by calling `-setLocation:` overrides automatic location parameters.
 *
 *  @see - setLocation:
 *
 *  @since v7.0.0
 */
- (void)dataWithCurrentLocation:(void (^)(NSDictionary *data))completionBlock;

/**
 *  Resets all user values
 *
 *  @since v7.0.0
 */
- (void)reset;

/**
 *  Returns the availability of in-app purchases previously set using `-setIap:`.
 *
 *  @return YES if enable, NO if disabled
 *
 *  @since v7.0.0
 */
- (BOOL)iap;

/**
 *  Returns the amount the user has spent on in-app purchases previously set using `-setIapAmount:`.
 *
 *  @return The amount spent on in-app purchases.
 *
 *  @since v7.0.0
 */
- (CGFloat)iapAmount;

/**
 *  Returns the number of sessions previously set using `-setNumberOfSessions`.
 *
 *  @return The number of sessions.
 *
 *  @since v7.0.0
 */
- (NSInteger)numberOfSessions;

/**
 *  Returns the time of the current session previously set using `-setPsTime:`.
 *
 *  @return The duration of the current session
 *
 *  @since v7.0.0
 */
- (NSTimeInterval)psTime;

/**
 *  Return the duration of the last session previously set using `-setLastSession:`.
 *
 *  @return The duration of the last session.
 *
 *  @since v7.0.0
 */
- (NSTimeInterval)lastSession;

/**
 *  Return the connection type previously set using `-setConnectionType:`.
 *
 *  @return The connection type
 *
 *  @see SPUserConnectionType
 *
 *  @since v7.0.0
 */
- (SPUserConnectionType)connectionType;

/**
 *  Returns the device previously set by `-setDevice:`.
 *
 *  @return The device model used by the user.
 *
 *  @see SPUserDevice
 *
 *  @since v7.0.0
 */
- (SPUserDevice)device;

/**
 *  Returns the version of the app previously set by `-setVersion:`.
 *
 *  @return The version of the app.
 *
 *  @since v7.0.0
 */
- (NSString *)version;

/**
 *  Returns a copy of the custom parameters previously set by `-setCustomParameters:`.
 *
 *  @return A copy of the custom parameters
 *
 *  @since v7.0.0
 */
- (NSDictionary *)customParameters;

@end
