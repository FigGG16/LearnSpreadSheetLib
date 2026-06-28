//
//  SpreadsheetViewDataSource.swift
//  SpreadsheetView
//
//  Created by Kishikawa Katsumi on 4/21/17.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

/// 实现该协议，为 `SpreadsheetView` 提供数据。
public protocol SpreadsheetViewDataSource: class {
    /// 向数据源询问表格视图的列数。
    ///
    /// - Parameter spreadsheetView: 请求该信息的表格视图。
    /// - Returns: `spreadsheetView` 中的列数。
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int
    /// 向数据源询问表格视图的行数。
    ///
    /// - Parameter spreadsheetView: 请求该信息的表格视图。
    /// - Returns: `spreadsheetView` 中的行数。
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int

    /// 向数据源询问指定列应使用的宽度。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 请求该信息的表格视图。
    ///   - column: 列索引。
    /// - Returns: 指定该列宽度（单位为点）的非负浮点值。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat
    /// 向数据源询问指定行应使用的高度。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 请求该信息的表格视图。
    ///   - row: 行索引。
    /// - Returns: 指定该行高度（单位为点）的非负浮点值。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat

    /// 向数据源请求表格视图中指定位置对应的单元格。
    /// 返回的单元格必须通过 `dequeueReusableCell(withReuseIdentifier:for:)` 获取。
    ///
    /// - Parameters:
    ///   - spreadsheetView: 请求该信息的表格视图。
    ///   - indexPath: 单元格的位置。
    /// - Returns: 要在该位置显示的单元格对象。
    ///   如果该方法返回 `nil`，默认显示空白单元格。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell?

    /// 向数据源请求表格视图中的合并单元格范围数组。
    ///
    /// - Parameter spreadsheetView: 请求该信息的表格视图。
    /// - Returns: 表示各个合并单元格范围的数组。
    func mergedCells(in spreadsheetView: SpreadsheetView) -> [CellRange]
    /// 向数据源询问表格视图中需要冻结为固定列表头的列数。
    ///
    /// - Parameter spreadsheetView: 请求该信息的表格视图。
    /// - Returns: 要冻结的列数。
    func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int
    /// 向数据源询问表格视图中需要冻结为固定行表头的行数。
    ///
    /// - Parameter spreadsheetView: 请求该信息的表格视图。
    /// - Returns: 要冻结的行数。
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int
}

extension SpreadsheetViewDataSource {
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? { return nil }
    public func mergedCells(in spreadsheetView: SpreadsheetView) -> [CellRange] { return [] }
    public func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int { return 0 }
    public func frozenRows(in spreadsheetView: SpreadsheetView) -> Int { return 0 }
}
