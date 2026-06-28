//
//  SpreadsheetViewDelegate.swift
//  SpreadsheetView
//
//  Created by Kishikawa Katsumi on 4/21/17.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

/// `SpreadsheetViewDelegate` 协议定义了一组方法，用于管理表格视图中单元格的选择、
/// 高亮以及针对这些单元格执行的操作。
/// 该协议中的所有方法都有默认实现。
public protocol SpreadsheetViewDelegate: class {
    /// 询问代理在触摸跟踪期间是否应该高亮指定单元格。
    /// - Note: 收到触摸事件后，表格视图会预先高亮用户可能选中的单元格。
    ///   处理这些事件时，表格视图调用该方法，询问代理是否允许高亮指定单元格。
    ///   该方法只会响应用户交互而调用；通过代码设置单元格高亮状态时不会调用。
    ///
    ///   如果不自行实现该方法，默认返回 `true`。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 询问是否改变高亮状态的表格视图。
    ///   - indexPath: 要高亮的单元格索引路径。
    /// - Returns: 应该高亮时返回 `true`，否则返回 `false`。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
    /// 通知代理指定索引路径的单元格已被高亮。
    /// - Note: 表格视图只会在响应用户交互时调用该方法；
    ///   通过代码设置单元格高亮状态时不会调用。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 通知高亮状态变化的表格视图。
    ///   - indexPath: 已高亮单元格的索引路径。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didHighlightItemAt indexPath: IndexPath)
    /// 通知代理指定索引路径的单元格已取消高亮。
    /// - Note: 表格视图只会在响应用户交互时调用该方法；
    ///   通过代码改变单元格高亮状态时不会调用。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 通知高亮状态变化的表格视图。
    ///   - indexPath: 已取消高亮单元格的索引路径。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didUnhighlightItemAt indexPath: IndexPath)
    /// 询问代理是否应该选中指定单元格。
    /// - Note: 用户尝试选中表格中的单元格时，表格视图会调用该方法。
    ///   通过代码设置选中状态时不会调用。
    ///
    ///   如果不自行实现该方法，默认返回 `true`。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 询问是否改变选择状态的表格视图。
    ///   - indexPath: 要选中的单元格索引路径。
    /// - Returns: 应该选中时返回 `true`，否则返回 `false`。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    /// 询问代理是否应该取消选中指定单元格。
    /// - Note: 用户尝试取消选中表格中的单元格时，表格视图会调用该方法。
    ///   通过代码取消选中时不会调用。
    ///
    ///   如果不自行实现该方法，默认返回 `true`。
    ///
    ///   在多选模式下，用户点击一个已经选中的单元格时会调用该方法。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 询问是否改变选择状态的表格视图。
    ///   - indexPath: 要取消选中的单元格索引路径。
    /// - Returns: 应该取消选中时返回 `true`，否则返回 `false`。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
    /// 通知代理指定索引路径的单元格已被选中。
    /// - Note: 用户成功选中单元格时，表格视图会调用该方法。
    ///   通过代码设置选中状态时不会调用。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 通知选择状态变化的表格视图。
    ///   - indexPath: 已选中单元格的索引路径。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didSelectItemAt indexPath: IndexPath)
    /// 通知代理指定索引路径的单元格已取消选中。
    /// - Note: 用户成功取消选中单元格时，表格视图会调用该方法。
    ///   通过代码取消选中时不会调用。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 通知选择状态变化的表格视图。
    ///   - indexPath: 已取消选中单元格的索引路径。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didDeselectItemAt indexPath: IndexPath)
}

extension SpreadsheetViewDelegate {
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldHighlightItemAt indexPath: IndexPath) -> Bool { return true }
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, didHighlightItemAt indexPath: IndexPath) {}
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, didUnhighlightItemAt indexPath: IndexPath) {}
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldSelectItemAt indexPath: IndexPath) -> Bool { return true }
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, shouldDeselectItemAt indexPath: IndexPath) -> Bool { return true }
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, didSelectItemAt indexPath: IndexPath) {}
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, didDeselectItemAt indexPath: IndexPath) {}
}
