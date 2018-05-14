//
//  CPCCalendarUnitCaching.swift
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

import Foundation

private protocol CPCCalendarUnitSpecificCacheProtocol {
	var count: Int { get };
	
	mutating func purge (factor: Double);
}

private protocol CPCCalendarUnitSingletonCacheProtocol: CPCCalendarUnitSpecificCacheProtocol {
	associatedtype Unit where Unit: CPCCalendarUnit;
	
	static func instance () -> Self;
	init ();
}

extension CPCCalendarUnitSingletonCacheProtocol {
	fileprivate static func instance () -> Self {
		return CPCCalendarUnitElementsCache.shared.unitSpecificCacheInstance ();
	}
}

private protocol CPCUnusedItemsPurgingCacheProtocol {
	associatedtype KeyType where KeyType: Hashable;
	associatedtype ValueType;
	
	subscript (key: KeyType) -> ValueType? { mutating get set };
}

private final class CPCCalendarUnitElementsCache {
	private typealias UnitSpecificCacheProtocol = CPCCalendarUnitSpecificCacheProtocol;
	
	fileprivate class UnitSpecificCacheBase <Unit>: UnitSpecificCacheProtocol where Unit: CPCCalendarUnit {
		private struct UnusedItemsPurgingCache <Key, Value>: CPCUnusedItemsPurgingCacheProtocol where Key: Hashable {
			fileprivate typealias KeyType = Key;
			fileprivate typealias ValueType = Value;
			
			private struct ValueWrapper {
				fileprivate let value: Value;
				fileprivate let usageCount: Int;
			}
			
			fileprivate var count: Int {
				return self.values.count;
			}
			
			private var values: [Key: ValueWrapper] = {
				var result = [Key: ValueWrapper] ();
				result.reserveCapacity (CPCCalendarUnitElementsCache.cacheSizeThreshold);
				return result;
			} ();
			
			fileprivate init () {}
			
			fileprivate subscript (key: Key) -> Value? {
				mutating get {
					guard let value = self.values [key] else {
						return nil;
					}
					
					self.values [key] = ValueWrapper (value: value.value, usageCount: value.usageCount + 1);
					return value.value;
				}
				set {
					if let newValue = newValue {
						self.values [key] = ValueWrapper (value: newValue, usageCount: 0);
					} else {
						self.values [key] = nil;
					}
				}
			}
			
			fileprivate mutating func purge (factor: Double) {
				guard let maxUsageCount = self.values.max (by: { $0.value.usageCount < $1.value.usageCount })?.value.usageCount else {
					return;
				}
				
				let threshold = (Double (maxUsageCount) * factor).integerRounded (.down);
				self.values = self.values.filter { $0.value.usageCount >= threshold };
			}
		}
		
		fileprivate struct ThreadsafePurgingCacheStorage <KeyComplement, Value>: CPCCalendarUnitSpecificCacheProtocol, CPCUnusedItemsPurgingCacheProtocol
			where KeyComplement: Hashable {
			
			fileprivate typealias KeyType = Key;
			fileprivate typealias ValueType = Value;
			
			fileprivate struct Key: Hashable {
				private let unit: Unit;
				private let complementValue: KeyComplement;
				
				fileprivate var hashValue: Int {
					return hashIntegers (self.complementValue.hashValue, self.unit.hashValue);
				}
				
				fileprivate init (_ unit: Unit, pairedWith complementValue: KeyComplement) {
					self.unit = unit;
					self.complementValue = complementValue;
				}
			}
			
			fileprivate var count: Int {
				return self.storage.withStoredValue { $0.count };
			}
			
			private var storage = UnfairThreadsafeStorage (UnusedItemsPurgingCache <Key, Value> ());
			
			fileprivate subscript (key: Key) -> Value? {
				mutating get {
					return self.storage.withMutableStoredValue { $0 [key] };
				}
				set {
					self.storage.withMutableStoredValue { $0 [key] = newValue };
				}
			}
			
			fileprivate mutating func purge (factor: Double) {
				self.storage.withMutableStoredValue { $0.purge (factor: factor) };
			}
		}
		
		fileprivate var count: Int {
			var result = 0;
			self.enumerateSubcaches { (subcache: CPCCalendarUnitSpecificCacheProtocol) in result += subcache.count };
			return result;
		}
		
		fileprivate func purge (factor: Double) {
			self.enumerateSubcaches { (subcache: inout CPCCalendarUnitSpecificCacheProtocol) in
				subcache.purge (factor: factor);
			};
		}
		
		fileprivate func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			self.enumerateSubcaches { (subcache: inout CPCCalendarUnitSpecificCacheProtocol) in
				block (subcache);
			};
		}
		
		fileprivate func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {}
	}
	
	fileprivate class UnitSpecificCache <Unit>: UnitSpecificCacheBase <Unit>, CPCCalendarUnitSingletonCacheProtocol where Unit: CPCCalendarUnit {
		private typealias UnitDistancesStorage = ThreadsafePurgingCacheStorage <Unit, Unit.Stride>;
		private typealias UnitAdvancesStorage = ThreadsafePurgingCacheStorage <Unit.Stride, Unit>;
		
		private var distancesCache = UnitDistancesStorage ();
		private var advancedUnitsCache = UnitAdvancesStorage ();
		
		fileprivate required override init () {}
		
		fileprivate func calendarUnit (_ unit: Unit, distanceTo otherUnit: Unit) -> Unit.Stride? {
			return self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheDistance distance: Unit.Stride, to otherUnit: Unit) {
			self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)] = distance;
			self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: distance)] = otherUnit;
			CPCCalendarUnitElementsCache.shared.purgeCacheIfNeeded ();
		}
		
		fileprivate func calendarUnit (_ unit: Unit, advancedBy value: Unit.Stride) -> Unit? {
			return self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: value)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheUnit otherUnit: Unit, asAdvancedBy value: Unit.Stride) {
			self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: value)] = otherUnit;
			self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)] = value;
			CPCCalendarUnitElementsCache.shared.purgeCacheIfNeeded ();
		}
		
		fileprivate override func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			block (self.advancedUnitsCache);
			block (self.distancesCache);
		}
		
		fileprivate override func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);
			
			var currentCache: CPCCalendarUnitSpecificCacheProtocol;
			currentCache = self.distancesCache; block (&currentCache); self.distancesCache = currentCache as! UnitDistancesStorage;
			currentCache = self.advancedUnitsCache; block (&currentCache); self.advancedUnitsCache = currentCache as! UnitAdvancesStorage;
		}
	}
	
	fileprivate final class CompoundUnitSpecificCache <Unit>: UnitSpecificCache <Unit> where Unit: CPCCompoundCalendarUnit {
		private typealias UnitValuesStorage = ThreadsafePurgingCacheStorage <Unit.Index, Unit.Element>;
		private typealias UnitIndexesStorage = ThreadsafePurgingCacheStorage <Unit.Element, Unit.Index>;
		
		private var smallerUnitValuesCache = UnitValuesStorage ();
		private var smallerUnitIndexesCache = UnitIndexesStorage ();
		
		fileprivate required init () {}

		fileprivate func calendarUnit (_ unit: Unit, elementAt index: Unit.Index) -> Unit.Element? {
			return self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheElement element: Unit.Element, for index: Unit.Index) {
			self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)] = element;
			self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)] = index;
			CPCCalendarUnitElementsCache.shared.purgeCacheIfNeeded ();
		}
		
		fileprivate func calendarUnit (_ unit: Unit, indexOf element: Unit.Element) -> Unit.Index? {
			return self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheIndex index: Unit.Index, for element: Unit.Element) {
			self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)] = index;
			self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)] = element;
			CPCCalendarUnitElementsCache.shared.purgeCacheIfNeeded ();
		}
		
		fileprivate override func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);

			block (self.smallerUnitValuesCache);
			block (self.smallerUnitIndexesCache);
		}
		
		fileprivate override func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);
			
			var currentCache: CPCCalendarUnitSpecificCacheProtocol;
			currentCache = self.smallerUnitValuesCache; block (&currentCache); self.smallerUnitValuesCache = currentCache as! UnitValuesStorage;
			currentCache = self.smallerUnitIndexesCache; block (&currentCache); self.smallerUnitIndexesCache = currentCache as! UnitIndexesStorage;
		}
	}

	fileprivate static let shared = CPCCalendarUnitElementsCache ();
	private static let cacheSizeThreshold = 20480;
	private static let cachePurgeFactor = 0.5;
	
	private var unitSpecificCaches = UnfairThreadsafeStorage ([ObjectIdentifier: UnitSpecificCacheProtocol] ());
	
	private var currentCacheSize: Int {
		return self.unitSpecificCaches.withStoredValue { $0.values.reduce (0) { $0 + $1.count } };
	}
	
	fileprivate func unitSpecificCacheInstance <Unit, Cache> (ofType type: Unit.Type = Unit.self) -> Cache where Cache: CPCCalendarUnitSingletonCacheProtocol, Cache.Unit == Unit {
		return self.unitSpecificCaches.withMutableStoredValue { caches in
			let typeID = ObjectIdentifier (Unit.self);
			if let existingCache = caches [typeID] as? Cache {
				return existingCache;
			}
			let instance = Cache ();
			caches [typeID] = instance;
			return instance;
		};
	}
	
	fileprivate func purgeCacheIfNeeded () {
		if (self.currentCacheSize > CPCCalendarUnitElementsCache.cacheSizeThreshold) {
			self.unitSpecificCaches.withMutableStoredValue {
				for key in $0.keys {
					$0 [key]?.purge (factor: CPCCalendarUnitElementsCache.cachePurgeFactor);
				}
			};
		}
	}
}

internal extension CPCCalendarUnit {
	internal func cachedDistance (to other: Self) -> Stride? {
		return CPCCalendarUnitElementsCache.UnitSpecificCache.instance ().calendarUnit (self, distanceTo: other);
	}
	
	internal func cacheDistance (_ distance: Stride, to other: Self) {
		return CPCCalendarUnitElementsCache.UnitSpecificCache.instance ().calendarUnit (self, cacheDistance: distance, to: other);
	}

	internal func cachedAdvancedUnit (by stride: Self.Stride) -> Self? {
		return CPCCalendarUnitElementsCache.UnitSpecificCache.instance ().calendarUnit (self, advancedBy: stride);
	}
	
	internal func cacheUnitValue (_ value: Self, advancedBy distance: Stride) {
		return CPCCalendarUnitElementsCache.UnitSpecificCache.instance ().calendarUnit (self, cacheUnit: value, asAdvancedBy: distance);
	}
}

internal extension CPCCompoundCalendarUnit {
	internal func cachedElement (at index: Index) -> Element? {
		return CPCCalendarUnitElementsCache.CompoundUnitSpecificCache.instance ().calendarUnit (self, elementAt: index);
	}
	
	internal func cacheElement (_ element: Element, for index: Index) {
		return CPCCalendarUnitElementsCache.CompoundUnitSpecificCache.instance ().calendarUnit (self, cacheElement: element, for: index);
	}
	
	internal func cachedIndex (of element: Element) -> Index? {
		return CPCCalendarUnitElementsCache.CompoundUnitSpecificCache.instance ().calendarUnit (self, indexOf: element);
	}
	
	internal func cacheIndex (_ index: Index, for element: Element) {
		return CPCCalendarUnitElementsCache.CompoundUnitSpecificCache.instance ().calendarUnit (self, cacheIndex: index, for: element);
	}
}
