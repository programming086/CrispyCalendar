//
//  CPCCalendarUnit_CalendarWrapper.swift
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

import Swift

/// Wraps a Calendar instance into a reference type to enable short-circuit equality evaluation using identity operator.
internal final class CPCCalendarWrapper: NSObject {
	private static var instances = UnfairThreadsafeStorage (UnownedDictionary <Calendar, CPCCalendarWrapper> ());
	
	/// Wrapped Calendar instance
	internal let calendar: Calendar;
	private let calendarHashValue: Int;
	
	internal override var hash: Int {
		return self.calendarHashValue;
	}

	internal var unitSpecificCaches = UnfairThreadsafeStorage ([ObjectIdentifier: UnitSpecificCacheProtocol] ());

	private var lastCachesPurgeTimestamp = Date.timeIntervalSinceReferenceDate;
	private var mainRunLoopObserver: CFRunLoopObserver?;
	
	internal static func == (lhs: CPCCalendarWrapper, rhs: CPCCalendarWrapper) -> Bool {
		return (lhs === rhs);
	}
	
	fileprivate static func wrap (_ calendar: Calendar) -> CPCCalendarWrapper {
		return self.instances.withMutableStoredValue {
			if let existingWrapper = $0 [calendar] {
				return existingWrapper;
			}
			
			let wrapper = CPCCalendarWrapper (calendar);
			$0 [calendar] = wrapper;
			return wrapper;
		};
	}
	
	/// Initializes a new CalendarWrapper
	///
	/// - Parameter calendar: Calendar to wrap
	private init (_ calendar: Calendar) {
		self.calendar = calendar;
		self.calendarHashValue = calendar.hashValue;
		super.init ();

		var context = CFRunLoopObserverContext (version: 0, info: Unmanaged.passUnretained (self).toOpaque (), retain: nil, release: nil, copyDescription: nil);
		let observer = CFRunLoopObserverCreate (kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0, CPCCalendarViewMainRunLoopObserver, &context);
		self.mainRunLoopObserver = observer;
		CFRunLoopAddObserver (CFRunLoopGetMain (), observer, CFRunLoopMode.commonModes);
	}
	
	deinit {
		self.mainRunLoopObserver.map {
			CFRunLoopRemoveObserver (CFRunLoopGetMain (), $0, CFRunLoopMode.commonModes);
		}
		
		CPCCalendarWrapper.instances.withMutableStoredValue {
			$0 [self.calendar] = nil;
		};
	}
	
	internal override func isEqual (_ object: Any?) -> Bool {
		return self === object as? CPCCalendarWrapper;
	}
	
	internal func mainRunLoopWillStartWaiting () {
		let currentTimestamp = Date.timeIntervalSinceReferenceDate;
		guard (currentTimestamp - self.lastCachesPurgeTimestamp) > 10.0 else {
			return;
		}
		self.lastCachesPurgeTimestamp = currentTimestamp;
		self.purgeCacheIfNeeded ();
	}
}

private func CPCCalendarViewMainRunLoopObserver (observer: CFRunLoopObserver!, activity: CFRunLoopActivity, calendarPtr: UnsafeMutableRawPointer?) {
	guard let calendarWrapper = calendarPtr.map ({ Unmanaged <CPCCalendarWrapper>.fromOpaque ($0).takeUnretainedValue () }) else {
		return;
	}
	calendarWrapper.mainRunLoopWillStartWaiting ();
}

public extension Calendar {
	internal func wrapped () -> CPCCalendarWrapper {
		return CPCCalendarWrapper.wrap (self);
	}
}
