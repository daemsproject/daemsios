// 

#import "DMCHashID.h"
#import "DMCData.h"

NSData* DMCHashFromID(NSString* identifier) {
    return DMCReversedData(DMCDataFromHex(identifier));
}

NSString* DMCIDFromHash(NSData* hash) {
    return DMCHexFromData(DMCReversedData(hash));
}
