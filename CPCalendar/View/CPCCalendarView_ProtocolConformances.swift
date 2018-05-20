//
//  CPCCalendarView_ProtocolConformances.swift
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

import UIKit

extension CPCCalendarView: CPCViewProtocol {
	@IBInspectable open var titleFont: UIFont {
		get { return self.contentView.titleFont }
		set { self.contentView.titleFont = newValue }
	}
	
	@IBInspectable open var titleColor: UIColor {
		get { return self.contentView.titleColor }
		set { self.contentView.titleColor = newValue }
	}
	
	open var titleStyle: TitleStyle {
		get { return self.contentView.titleStyle }
		set { self.contentView.titleStyle = newValue }
	}
	
	@IBInspectable open var titleMargins: UIEdgeInsets {
		get { return self.contentView.titleMargins }
		set { self.contentView.titleMargins = newValue }
	}
	
	@IBInspectable open var dayCellFont: UIFont {
		get { return self.contentView.dayCellFont }
		set { self.contentView.dayCellFont = newValue }
	}
	
	@IBInspectable open var dayCellTextColor: UIColor {
		get { return self.contentView.dayCellTextColor }
		set { self.contentView.dayCellTextColor = newValue }
	}
	
	@IBInspectable open var separatorColor: UIColor {
		get { return self.contentView.separatorColor }
		set { self.contentView.separatorColor = newValue }
	}
	
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.contentView.dayCellBackgroundColor (for: state);
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.contentView.setDayCellBackgroundColor (backgroundColor, for: state);
	}
}

extension CPCCalendarView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCCalendarViewSelectionDelegate;
	
	internal var selectionHandler: SelectionHandler {
		get {
			return self.contentView.selectionHandler;
		}
		set {
			self.contentView.selectionHandler = newValue;
		}
	}
	
	internal func selectionValue (of delegate: SelectionDelegateType) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: SelectionDelegateType) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: SelectionDelegateType) {}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.calendarView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.calendarView (self, shouldDeselect: day);
	}
}

extension CPCCalendarView: UIContentSizeCategoryAdjusting {
	open var adjustsFontForContentSizeCategory: Bool {
		get {
			return self.contentView.adjustsFontForContentSizeCategory;
		}
		set {
			self.contentView.adjustsFontForContentSizeCategory = newValue;
		}
	}
}