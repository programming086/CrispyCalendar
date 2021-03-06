//
//  CPCViewTitleStyle.h
//  Copyright © 2018 Cleverpumpkin, Ltd. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>

/** Type of predefined month title styles.
 */
typedef NSString *CPCViewTitleStyle NS_TYPED_ENUM NS_REFINED_FOR_SWIFT;

NS_ASSUME_NONNULL_BEGIN

/** Month titles are not rendered.
 */
extern CPCViewTitleStyle const CPCViewTitleNoStyle NS_SWIFT_NAME(none);
/** Short title format: one-digit month number and full year.
 */
extern CPCViewTitleStyle const CPCViewTitleShortStyle NS_SWIFT_NAME(short);
/** Medium title format: two-digit zero-padded month number and full year.
 */
extern CPCViewTitleStyle const CPCViewTitleMediumStyle NS_SWIFT_NAME(medium);
/** Long title format: abbreviated month name and full year.
 */
extern CPCViewTitleStyle const CPCViewTitleLongStyle NS_SWIFT_NAME(long);
/** Full title format: full month name and full year.
 */
extern CPCViewTitleStyle const CPCViewTitleFullStyle NS_SWIFT_NAME(full);

NS_ASSUME_NONNULL_END
