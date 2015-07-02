//
//  SPUserConstants.h
//  SponsorPaySDK
//
//  Created by Piotr  on 24/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

static const NSInteger SPEntryIgnore = NSNotFound;
static double const SPGeoLocationValueNotFound = (double)SPEntryIgnore;

///-------------------------
/// Basic data
///-------------------------

/**
 *  The gender of the user
 */
typedef NS_ENUM(NSInteger, SPUserGender) {
    /**
     *  Gender: undefined
     */
    SPUserGenderUndefined = -1,
    /**
     *  Gender: male
     */
    SPUserGenderMale,
    /**
     *  Gender: female
     */
    SPUserGenderFemale,
    /**
     *  Gender: other
     */
    SPUserGenderOther
};

/**
 *  The sexual orientation of the user
 */
typedef NS_ENUM(NSInteger, SPUserSexualOrientation) {
    /**
     *  Sexual orientation: undefined
     */
    SPUserSexualOrientationUndefined = -1,
    /**
     *  Sexual orientation: straight
     */
    SPUserSexualOrientationStraight,
    /**
     *  Sexual orientation: bisexual
     */
    SPUserSexualOrientationBisexual,
    /**
     *  Sexual orientation: gay
     */
    SPUserSexualOrientationGay,
    /**
     *  Sexual orientation: unknown
     */
    SPUserSexualOrientationUnknown
};

/**
 *  The ethnicity of the user
 */
typedef NS_ENUM(NSInteger, SPUserEthnicity) {
    /**
     *  Ethnicity: undefined
     */
    SPUserEthnicityUndefined = -1,
    /**
     *  Ethnicity: asian
     */
    SPUserEthnicityAsian,
    /**
     *  Ethnicity: black
     */
    SPUserEthnicityBlack,
    /**
     *  Ethnicity: hispanic
     */
    SPUserEthnicityHispanic,
    /**
     *  Ethnicity: indian
     */
    SPUserEthnicityIndian,
    /**
     *  Ethnicity: middle eastern
     */
    SPUserEthnicityMiddleEastern,
    /**
     *  Ethnicity: native american
     */
    SPUserEthnicityNativeAmerican,
    /**
     *  Ethnicity: pacific islander
     */
    SPUserEthnicityPacificIslander,
    /**
     *  Ethnicity: white
     */
    SPUserEthnicityWhite,
    /**
     *  Ethnicity: other
     */
    SPUserEthnicityOther
};

/**
 *  The marital status of the user
 */
typedef NS_ENUM(NSInteger, SPUserMaritalStatus) {
    /**
     *  Marital status: undefined
     */
    SPUserMaritalStatusUndefined = -1,
    /**
     *  Marital status: single
     */
    SPUserMartialStatusSingle,
    /**
     *  Marital status: in a relationship
     */
    SPUserMartialStatusRelationship,
    /**
     *  Marital status: married
     */
    SPUserMartialStatusMarried,
    /**
     *  Marital status: divorced
     */
    SPUserMartialStatusDivorced,
    /**
     *  Marital status: engaged
     */
    SPUserMartialStatusEngaged
};

/**
 *  The education of the user
 */
typedef NS_ENUM(NSInteger, SPUserEducation) {
    /**
     *  Education: undefined
     */
    SPUserEducationUndefined = -1,
    /**
     *  Education: other
     */
    SPUserEducationOther,
    /**
     *  Education: none
     */
    SPUserEducationNone,
    /**
     *  Education: highschool
     */
    SPUserEducationHighSchool,
    /**
     *  Education: in college
     */
    SPUserEducationInCollege,
    /**
     *  Education: some college
     */
    SPUserEducationSomeCollege,
    /**
     *  Education: associates
     */
    SPUserEducationAssociates,
    /**
     *  Education: bachelors
     */
    SPUserEducationBachelors,
    /**
     *  Education: masters
     */
    SPUserEducationMasters,
    /**
     *  Education: doctorate
     */
    SPUserEducationDoctorate
};

///-------------------------
/// Extra
///-------------------------

/**
 *  The connection type of the user
 */
typedef NS_ENUM(NSInteger, SPUserConnectionType) {
    /**
     *  Connection type: undefined
     */
    SPUserConnectionTypeUndefined = -1,
    /**
     *  Connection type: Wifi
     */
    SPUserConnectionTypeWiFi,
    /**
     *  Connection type:  3G
     */
    SPUserConnectionType3G,
    /**
     *  Connection type: LTE
     */
    SPUserConnectionTypeLTE,
    /**
     *  Connection type: Edge
     */
    SPUserConnectionTypeEdge
};

/**
 *  The device of the user
 */
typedef NS_ENUM(NSInteger, SPUserDevice) {
    /**
     *  Device: undefined
     */
    SPUserDeviceUndefined = -1,
    /**
     *  Device: iPhone
     */
    SPUserDeviceIPhone,
    /**
     *  Device: iPad
     */
    SPUserDeviceIPad,
    /**
     *  Device: iPod
     */
    SPUserDeviceIPod
};

// MARK: Mapping keys

static NSString *const SPUserDateFormat = @"yyyy/MM/dd";

static NSString *const SPUserAgeKey = @"age";
static NSString *const SPUserBirthdateKey = @"birthdate";
static NSString *const SPUserGenderKey = @"gender";
static NSString *const SPUserSexualOrientationKey = @"sexual_orientation";
static NSString *const SPUserEthnicityKey = @"ethnicity";
static NSString *const SPUserLocationLongitude = @"longt";
static NSString *const SPUserLocationLatitude = @"lat";
static NSString *const SPUserMaritalStatusKey = @"marital_status";
static NSString *const SPUserAnnualHouseholdIncomeKey = @"annual_household_income";
static NSString *const SPUserEducationKey = @"education";
static NSString *const SPUserZipCodeKey = @"zipcode";
static NSString *const SPUserInterestsKey = @"interests";
static NSString *const SPUserNumberOfChildrenKey = @"children";

static NSString *const SPUserIapKey = @"iap";
static NSString *const SPUserIapAmountKey = @"iap_amount";
static NSString *const SPUserNumberOfSessionsKey = @"number_of_sessions";
static NSString *const SPUserPsTimeKey = @"ps_time";
static NSString *const SPUserLastSessionKey = @"last_session";
static NSString *const SPUserConnectionTypeKey = @"connection";
static NSString *const SPUserDeviceKey = @"device";
static NSString *const SPUserVersionKey = @"version";

// MARK: Mapping arrays

static NSString *const SPUserMappingGender[4] = {
    @"male",
    @"female",
    @"other",
    NULL
};

static NSString *const SPUserMappingSexualOrientation[5] = {
    @"straight",
    @"bisexual",
    @"gay",
    @"unknown",
    NULL
};

static NSString *const SPUserMappingEthnicity[10] = {
    @"asian",
    @"black",
    @"hispanic",
    @"indian",
    @"middle eastern",
    @"native american",
    @"pacific islander",
    @"white",
    @"other",
    NULL
};

static NSString *const SPUserMappingMaritalStatus[6] = {
    @"single",
    @"relationship",
    @"married",
    @"divorced",
    @"engaged",
    NULL
};

static NSString *const SPUserMappingEducation[10] = {
    @"other",
    @"none",
    @"high school",
    @"in college",
    @"some college",
    @"associates",
    @"bachelors",
    @"masters",
    @"doctorate",
    NULL
};

static NSString *const SPUserMappingDevice[4] = {
    @"iPhone",
    @"iPad",
    @"iPod",
    NULL
};

static NSString *const SPUserMappingConnectionType[5] = {
    @"wifi",
    @"3g",
    @"lte",
    @"edge",
    NULL
};
