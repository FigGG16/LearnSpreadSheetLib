//
//  SpreadsheetView+UIScrollViewDelegate.swift
//  SpreadsheetView
//
//  Created by Kishikawa Katsumi on 5/1/17.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

extension SpreadsheetView: UIScrollViewDelegate {
    /// LEARNING-SCROLL 3/8：tableView 是滚动基准。固定行区域只同步横向 offset，固定列区域只同步
    /// 纵向 offset；随后 setNeedsLayout 触发布局引擎更新四个区域各自的可见 Cell。
    /// 注意历史命名：rowHeaderView 实际承载冻结行，columnHeaderView 实际承载冻结列。
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        rowHeaderView.delegate = nil
        columnHeaderView.delegate = nil
        tableView.delegate = nil
        defer {
            rowHeaderView.delegate = self
            columnHeaderView.delegate = self
            tableView.delegate = self
        }

        // LEARNING-SCROLL 4/8：以下两段只处理“拉过边界”的 bounce 外观。
        // x < 0 时，若 stickyColumnHeader=false，固定列和左上角会被向右拉动；
        // y < 0 时，若 stickyRowHeader=false，固定行和左上角会被向下拉动。
        // 它们改变的是区域 frame，不是正常滚动时的 contentOffset 同步。
        if tableView.contentOffset.x < 0 && !stickyColumnHeader {
            let offset = tableView.contentOffset.x * -1
            cornerView.frame.origin.x = offset
            columnHeaderView.frame.origin.x = offset
        } else {
            cornerView.frame.origin.x = 0
            columnHeaderView.frame.origin.x = 0
        }
        if tableView.contentOffset.y < 0 && !stickyRowHeader {
            let offset = tableView.contentOffset.y * -1
            cornerView.frame.origin.y = offset
            rowHeaderView.frame.origin.y = offset
        } else {
            cornerView.frame.origin.y = 0
            rowHeaderView.frame.origin.y = 0
        }

        // LEARNING-SCROLL 5/8，四种滚动关系的核心只有下面两行：
        // ① 普通表格横向：tableView.contentOffset.x 自己变化；
        // ② 普通表格纵向：tableView.contentOffset.y 自己变化；
        // ③ 表头横向（冻结行）：rowHeaderView 复制主表的 x，y 保持 0；
        // ④ 表头纵向（冻结列）：columnHeaderView 复制主表的 y，x 保持 0。
        // cornerView 两个方向都不复制，所以左上角始终固定。
        rowHeaderView.contentOffset.x = tableView.contentOffset.x
        columnHeaderView.contentOffset.y = tableView.contentOffset.y

        // offset 同步后不在这里直接创建 Cell，而是请求下一轮 layoutSubviews。
        setNeedsLayout()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let indexPath = pendingSelectionIndexPath else {
            return
        }
        cellsForItem(at: indexPath).forEach { $0.setSelected(true, animated: true) }
        delegate?.spreadsheetView(self, didSelectItemAt: indexPath)
        pendingSelectionIndexPath = nil
    }

    @available(iOS 11.0, *)
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        resetScrollViewFrame()
    }
}
