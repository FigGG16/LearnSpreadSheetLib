//
//  SpreadsheetView.swift
//  SpreadsheetView
//
//  Created by Kishikawa Katsumi on 3/16/17.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

public class SpreadsheetView: UIView {
    /// 为表格视图提供数据的对象。
    ///
    /// - Note: 数据源必须遵循 `SpreadsheetViewDataSource` 协议。
    ///   表格视图仅持有数据源对象的弱引用。
    public weak var dataSource: SpreadsheetViewDataSource? {
        didSet {
            resetTouchHandlers(to: [tableView, columnHeaderView, rowHeaderView, cornerView])
            setNeedsReload()
        }
    }
    /// 作为表格视图代理的对象。
    /// - Note: 代理必须遵循 `SpreadsheetViewDelegate` 协议。
    ///   表格视图仅持有代理对象的弱引用。
    ///
    ///   代理对象负责管理选择行为以及与各个单元格的交互。
    public weak var delegate: SpreadsheetViewDelegate?

    /// 单元格之间的水平和垂直间距。
    /// 
    /// - Note: 默认间距为 `(1.0, 1.0)`，不支持负值。
    public var intercellSpacing = CGSize(width: 1, height: 1)
    public var gridStyle: GridStyle = .solid(width: 1, color: .lightGray)

    /// 指示用户能否选中表格单元格的布尔值。
    ///
    /// - Note: 该属性为 `true`（默认值）时，用户可以选中单元格。
    ///   如果需要更精细地控制单元格选择行为，
    ///   必须提供代理对象，并实现 `SpreadsheetViewDelegate` 协议中的相应方法。
    ///
    /// - SeeAlso: `allowsMultipleSelection`
    public var allowsSelection = true {
        didSet {
            if !allowsSelection {
                allowsMultipleSelection = false
            }
        }
    }
    /// 决定用户能否在表格中同时选中多个单元格的布尔值。
    ///
    /// - Note: 该属性控制是否可以同时选中多个单元格，默认值为 `false`。
    ///
    ///   该属性为 `true` 时，点击单元格会将其加入当前选择集合（前提是代理允许选中该单元格）。
    ///   再次点击同一单元格会将其移出选择集合。
    ///
    /// - SeeAlso: `allowsSelection`
    public var allowsMultipleSelection = false {
        didSet {
            if allowsMultipleSelection {
                allowsSelection = true
            }
        }
    }

    /// 控制是否显示垂直滚动指示器的布尔值。
    ///
    /// 默认值为 `true`。拖动期间指示器可见，拖动结束后会逐渐淡出。
    public var showsVerticalScrollIndicator = true {
        didSet {
            overlayView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
    }
    /// 控制是否显示水平滚动指示器的布尔值。
    ///
    /// 默认值为 `true`。拖动期间指示器可见，拖动结束后会逐渐淡出。
    public var showsHorizontalScrollIndicator = true {
        didSet {
            overlayView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
    }

    /// 控制是否启用“滚动到顶部”手势的布尔值。
    ///
    /// - Note: “滚动到顶部”手势是点击状态栏。用户执行该手势时，
    /// 系统会请求距离状态栏最近的滚动视图滚动到顶部。
    /// 如果该滚动视图的 `scrollsToTop` 为 `false`、代理从 `scrollViewShouldScrollToTop(_:)` 返回 `false`，
    /// 或内容已经位于顶部，则不会发生任何操作。
    ///
    /// 滚动视图到达内容顶部后，会向代理发送 `scrollViewDidScrollToTop(_:)` 消息。
    ///
    /// `scrollsToTop` 的默认值为 `true`。
    ///
    /// 在 iPhone 上，如果屏幕中有多个滚动视图的 `scrollsToTop` 都为 `true`，该手势不会生效。
    public var scrollsToTop: Bool = true {
        didSet {
            tableView.scrollsToTop = scrollsToTop
        }
    }

    public var circularScrolling: CircularScrollingConfiguration = CircularScrolling.Configuration.none {
        didSet {
            circularScrollingOptions = circularScrolling.options
            if circularScrollingOptions.direction.contains(.horizontally) {
                showsHorizontalScrollIndicator = false
            }
            if circularScrollingOptions.direction.contains(.vertically) {
                showsVerticalScrollIndicator = false
                scrollsToTop = false
            }
        }
    }
    var circularScrollingOptions = CircularScrolling.Configuration.none.options
    var circularScrollScalingFactor: (horizontal: Int, vertical: Int) = (1, 1)
    var centerOffset = CGPoint.zero

    /// 提供背景外观的视图。
    ///
    /// - Note: 该属性中的视图（如果存在）位于所有其他内容下方，并自动调整大小以填满表格视图的整个边界。
    /// 背景视图不会随表格的其他内容滚动。表格视图会强引用该背景视图对象。
    ///
    /// 该属性默认为 `nil`，此时显示表格视图自身的背景色。
    public var backgroundView: UIView? {
        willSet {
            backgroundView?.removeFromSuperview()
        }
        didSet {
            if let backgroundView = backgroundView {
                backgroundView.frame = bounds
                backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                guard #available(iOS 11.0, *) else {
                    super.insertSubview(backgroundView, at: 0)
                    return
                }
            }
        }
    }

    @available(iOS 11.0, *)
    public override func safeAreaInsetsDidChange() {
        if let backgroundView = backgroundView {
            backgroundView.removeFromSuperview()
            super.insertSubview(backgroundView, at: 0)
        }
    }

    /// 返回表格视图当前显示的所有可见单元格。
    ///
    /// - Note: 该属性返回当前显示的完整可见单元格列表。
    ///
    /// - Returns: `Cell` 对象数组。没有可见单元格时返回空数组。
    public var visibleCells: [Cell] {
        let cells: [Cell] = Array(columnHeaderView.visibleCells) + Array(rowHeaderView.visibleCells)
            + Array(cornerView.visibleCells) + Array(tableView.visibleCells)
        return cells.sorted()
    }


    /// 表格视图中可见项的索引路径数组。
    /// - Note: 该属性是已排序的 `IndexPath` 数组，每个索引路径对应一个可见单元格。
    /// 没有可见项时，该属性为空数组。
    ///
    /// - SeeAlso: `visibleCells`
    public var indexPathsForVisibleItems: [IndexPath] {
        return visibleCells.map { $0.indexPath }
    }

    public var indexPathForSelectedItem: IndexPath? {
        return Array(selectedIndexPaths).sorted().first
    }

    /// 已选中项的索引路径。
    /// - Note: 该属性是 `IndexPath` 对象数组，每个索引路径对应一个已选中项。
    /// 没有选中项时返回空数组。
    public var indexPathsForSelectedItems: [IndexPath] {
        return Array(selectedIndexPaths).sorted()
    }

    /// 决定是否将滚动锁定在某一个方向的布尔值。
    /// - Note: 该属性为 `false` 时，允许水平和垂直双向滚动。
    /// 该属性为 `true` 且用户主要沿水平或垂直方向开始拖动时，滚动视图会禁用另一方向的滚动。
    /// 如果拖动方向是对角线，则不会锁定方向，用户可以在拖动结束前沿任意方向移动。
    /// 默认值为 `false`。
    public var isDirectionalLockEnabled = false {
        didSet {
            tableView.isDirectionalLockEnabled = isDirectionalLockEnabled
        }
    }

    /// 控制滚动视图越过内容边缘后是否回弹的布尔值。
    /// - Note: 该属性为 `true` 时，滚动视图到达内容边界后会回弹。
    /// 回弹效果用于直观提示用户已经滚动到内容边缘。
    /// 该属性为 `false` 时，滚动会在内容边界立即停止，不产生回弹。
    /// 默认值为 `true`。
    ///
    /// - SeeAlso: `alwaysBounceHorizontal`, `alwaysBounceVertical`
    public var bounces: Bool {
        get {
            return tableView.bounces
        }
        set {
            tableView.bounces = newValue
        }
    }

    /// 决定垂直方向是否始终允许回弹的布尔值。
    /// - Note: 如果该属性和 `bounces` 都为 `true`，即使内容高度小于滚动视图边界，也允许垂直拖动。
    /// 默认值为 `false`。
    ///
    /// - SeeAlso: `alwaysBounceHorizontal`
    public var alwaysBounceVertical: Bool {
        get {
            return tableView.alwaysBounceVertical
        }
        set {
            tableView.alwaysBounceVertical = newValue
        }
    }

    /// 决定水平方向是否始终允许回弹的布尔值。
    /// - Note: 如果该属性和 `bounces` 都为 `true`，即使内容宽度小于滚动视图边界，也允许水平拖动。
    /// 默认值为 `false`。
    ///
    /// - SeeAlso: `alwaysBounceVertical`
    public var alwaysBounceHorizontal: Bool {
        get {
            return tableView.alwaysBounceHorizontal
        }
        set {
            tableView.alwaysBounceHorizontal = newValue
        }
    }

    /// 决定冻结行表头是否始终保持吸附的布尔值。
    /// - Note: `bounces` 必须为 `true`，并且至少存在一个 `frozenRow`。
    /// 默认值为 `false`。
    ///
    /// - SeeAlso: `stickyColumnHeader`
    public var stickyRowHeader: Bool = false
    /// 决定冻结列表头是否始终保持吸附的布尔值。
    /// - Note: `bounces` 必须为 `true`，并且至少存在一个 `frozenColumn`。
    /// 默认值为 `false`。
    ///
    /// - SeeAlso: `stickyRowHeader`
    public var stickyColumnHeader: Bool = false

    /// 决定是否启用分页滚动的布尔值。
    /// - Note: 该属性为 `true` 时，用户滚动后，滚动视图会停在其边界尺寸的整数倍位置。
    /// 默认值为 `false`。
    public var isPagingEnabled: Bool {
        get {
            return tableView.isPagingEnabled
        }
        set {
            tableView.isPagingEnabled = newValue
        }
    }

    /// 决定是否允许滚动的布尔值。
    /// - Note: 该属性为 `true` 时允许滚动，为 `false` 时禁用滚动。默认值为 `true`。
    ///
    /// 禁用滚动后，滚动视图不会接收触摸事件，而是将事件沿响应链向上传递。
    public var isScrollEnabled: Bool {
        get {
            return tableView.isScrollEnabled
        }
        set {
            tableView.isScrollEnabled = newValue
            overlayView.isScrollEnabled = newValue
        }
    }

    /// 滚动指示器的样式。
    /// - Note: 默认样式为 `default`。各常量的说明请参阅 `UIScrollViewIndicatorStyle`。
    public var indicatorStyle: UIScrollView.IndicatorStyle {
        get {
            return overlayView.indicatorStyle
        }
        set {
            overlayView.indicatorStyle = newValue
        }
    }

    /// 决定用户抬起手指后减速速率的浮点值。
    /// - Note: 可使用 `UIScrollViewDecelerationRateNormal` 和 `UIScrollViewDecelerationRateFast` 常量作为合理减速速率的参考。
    public var decelerationRate: CGFloat {
        get {
            return tableView.decelerationRate.rawValue
        }
        set {
            tableView.decelerationRate = UIScrollView.DecelerationRate(rawValue: newValue)
        }
    }

    public var numberOfColumns: Int {
        return layoutProperties.numberOfColumns
    }
    public var numberOfRows: Int {
        return layoutProperties.numberOfRows
    }
    public var frozenColumns: Int {
        return layoutProperties.frozenColumns
    }
    public var frozenRows: Int {
        return layoutProperties.frozenRows
    }
    public var mergedCells: [CellRange] {
        return layoutProperties.mergedCells
    }

    public var scrollView: UIScrollView {
        return overlayView
    }

    var layoutProperties = LayoutProperties()

    // LEARNING: 冻结行列不是通过移动单个 Cell 实现的，而是把表格拆成四个独立的
    // ScrollView。rootView 承载四块真实内容；overlayView 只暴露统一的滚动条等外观。
    let rootView = UIScrollView()
    let overlayView = UIScrollView()

    let columnHeaderView = ScrollView()
    let rowHeaderView = ScrollView()
    let cornerView = ScrollView()
    let tableView = ScrollView()

    private var cellClasses = [String: Cell.Type]()
    private var cellNibs = [String: UINib]()
    var cellReuseQueues = [String: ReuseQueue<Cell>]()
    let blankCellReuseIdentifier = UUID().uuidString

    var horizontalGridlineReuseQueue = ReuseQueue<Gridline>()
    var verticalGridlineReuseQueue = ReuseQueue<Gridline>()
    var borderReuseQueue = ReuseQueue<Border>()

    var highlightedIndexPaths = Set<IndexPath>()
    var selectedIndexPaths = Set<IndexPath>()
    var pendingSelectionIndexPath: IndexPath?
    var currentTouch: UITouch?

    private var needsReload = true

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    /// LEARNING-SCROLL 阅读顺序（在工程中搜索 `LEARNING-SCROLL` 可逐步阅读）：
    /// 1. 本方法：认识五个 ScrollView、视图层级和共享拖拽入口；
    /// 2. SpreadsheetView+UIScrollView.swift：公开 contentOffset 实际代理给 tableView；
    /// 3. SpreadsheetView+UIScrollViewDelegate.swift：一次滚动如何同步两个表头；
    /// 4. SpreadsheetView+Layout.swift/layoutSubviews：offset 如何触发四块区域重新布局；
    /// 5. LayoutEngine.init/layout：每块区域如何用自己的 offset 计算可见矩形；
    /// 6. resetScrollViewFrame/resetScrollViewArrangement：四块区域的 frame 与层级。
    ///
    /// 名称特别容易看反：rowHeaderView 承载“冻结行”，所以跟随主表横向滚动；
    /// columnHeaderView 承载“冻结列”，所以跟随主表纵向滚动。
    private func setup() {
        rootView.frame = bounds
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        rootView.showsHorizontalScrollIndicator = false
        rootView.showsVerticalScrollIndicator = false
        rootView.delegate = self
        super.addSubview(rootView)

        tableView.frame = bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.autoresizesSubviews = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self

        columnHeaderView.frame = bounds
        columnHeaderView.frame.size.width = 0
        columnHeaderView.autoresizingMask = [.flexibleHeight]
        columnHeaderView.autoresizesSubviews = false
        columnHeaderView.showsHorizontalScrollIndicator = false
        columnHeaderView.showsVerticalScrollIndicator = false
        columnHeaderView.isHidden = true
        columnHeaderView.delegate = self

        rowHeaderView.frame = bounds
        rowHeaderView.frame.size.height = 0
        rowHeaderView.autoresizingMask = [.flexibleWidth]
        rowHeaderView.autoresizesSubviews = false
        rowHeaderView.showsHorizontalScrollIndicator = false
        rowHeaderView.showsVerticalScrollIndicator = false
        rowHeaderView.isHidden = true
        rowHeaderView.delegate = self

        cornerView.autoresizesSubviews = false
        cornerView.isHidden = true
        cornerView.delegate = self

        overlayView.frame = bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.autoresizesSubviews = false
        overlayView.isUserInteractionEnabled = false

        rootView.addSubview(tableView)
        rootView.addSubview(columnHeaderView)
        rootView.addSubview(rowHeaderView)
        rootView.addSubview(cornerView)
        super.addSubview(overlayView)

        // LEARNING-SCROLL 1/8：库把各内部 UIScrollView 的 panGestureRecognizer
        // 统一挂到 SpreadsheetView。用户从普通区、固定行、固定列或角落开始拖拽，
        // 都能推动相应 UIScrollView，并最终进入同一个 scrollViewDidScroll 回调。
        [tableView, columnHeaderView, rowHeaderView, cornerView, overlayView].forEach {
            addGestureRecognizer($0.panGestureRecognizer)
            if #available(iOS 11.0, *) {
                $0.contentInsetAdjustmentBehavior = .never
            }
        }
    }

    @objc(registerClass:forCellWithReuseIdentifier:)
    public func register(_ cellClass: Cell.Type, forCellWithReuseIdentifier identifier: String) {
        cellClasses[identifier] = cellClass
    }

    @objc(registerNib:forCellWithReuseIdentifier:)
    public func register(_ nib: UINib, forCellWithReuseIdentifier identifier: String) {
        cellNibs[identifier] = nib
    }

    /// LEARNING: 全量刷新的总入口。阅读顺序建议如下：
    /// 1. resetLayoutProperties：向数据源读取数量、尺寸、冻结和合并配置；
    /// 2. layoutAttributeFor...：确定四个 ScrollView 分别负责哪些行列；
    /// 3. resetContentSize：把每行每列的起点保存为 records；
    /// 4. setNeedsLayout：交给 layoutSubviews 计算当前可见 Cell。
    public func reloadData() {
        layoutProperties = resetLayoutProperties()
        circularScrollScalingFactor = determineCircularScrollScalingFactor()
        centerOffset = calculateCenterOffset()

        cornerView.layoutAttributes = layoutAttributeForCornerView()
        columnHeaderView.layoutAttributes = layoutAttributeForColumnHeaderView()
        rowHeaderView.layoutAttributes = layoutAttributeForRowHeaderView()
        tableView.layoutAttributes = layoutAttributeForTableView()

        cornerView.resetReusableObjects()
        columnHeaderView.resetReusableObjects()
        rowHeaderView.resetReusableObjects()
        tableView.resetReusableObjects()

        resetContentSize(of: cornerView)
        resetContentSize(of: columnHeaderView)
        resetContentSize(of: rowHeaderView)
        resetContentSize(of: tableView)

        resetScrollViewFrame()
        resetScrollViewArrangement()

        if circularScrollingOptions.direction.contains(.horizontally) && tableView.contentOffset.x == 0 {
            scrollToHorizontalCenter()
        }
        if circularScrollingOptions.direction.contains(.vertically) && tableView.contentOffset.y == 0 {
            scrollToVerticalCenter()
        }

        needsReload = false
        setNeedsLayout()
    }

    func reloadDataIfNeeded() {
        if needsReload {
            reloadData()
        }
    }

    private func setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }

    /// LEARNING: 复用池中有对象时先调用 prepareForReuse；没有对象时才根据注册的
    /// class 或 nib 创建。indexPath 在这里没有参与查找，它由 LayoutEngine 随后写入 Cell。
    public func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> Cell {
        if let reuseQueue = cellReuseQueues[identifier] {
            if let cell = reuseQueue.dequeue() {
                cell.prepareForReuse()
                return cell
            }
        } else {
            let reuseQueue = ReuseQueue<Cell>()
            cellReuseQueues[identifier] = reuseQueue
        }
        if identifier == blankCellReuseIdentifier {
            let cell = BlankCell()
            cell.reuseIdentifier = identifier
            return cell
        }
        if let clazz = cellClasses[identifier] {
            let cell = clazz.init()
            cell.reuseIdentifier = identifier
            return cell
        }
        if let nib = cellNibs[identifier] {
            if let cell = nib.instantiate(withOwner: nil, options: nil).first as? Cell {
                cell.reuseIdentifier = identifier
                return cell
            }
        }
        fatalError("could not dequeue a view with identifier cell - must register a nib or a class for the identifier")
    }

    private func resetTouchHandlers(to scrollViews: [ScrollView]) {
        scrollViews.forEach {
            if let _ = dataSource {
                $0.touchesBegan = { [weak self] (touches, event) in
                    self?.touchesBegan(touches, event)
                }
                $0.touchesEnded = { [weak self] (touches, event) in
                    self?.touchesEnded(touches, event)
                }
                $0.touchesCancelled = { [weak self] (touches, event) in
                    self?.touchesCancelled(touches, event)
                }
            } else {
                $0.touchesBegan = nil
                $0.touchesEnded = nil
                $0.touchesCancelled = nil
            }
        }
    }

    public func scrollToItem(at indexPath: IndexPath, at scrollPosition: ScrollPosition, animated: Bool) {
        let contentOffset = contentOffsetForScrollingToItem(at: indexPath, at: scrollPosition)
        tableView.setContentOffset(contentOffset, animated: animated)
    }

    private func contentOffsetForScrollingToItem(at indexPath: IndexPath, at scrollPosition: ScrollPosition) -> CGPoint {
        let (column, row) = (indexPath.column, indexPath.row)
        guard column < numberOfColumns && row < numberOfRows else {
            fatalError("attempt to scroll to invalid index path: {column = \(column), row = \(row)}")
        }

        let columnRecords = columnHeaderView.columnRecords + tableView.columnRecords
        let rowRecords = rowHeaderView.rowRecords + tableView.rowRecords
        var contentOffset = CGPoint(x: columnRecords[column], y: rowRecords[row])

        let width: CGFloat
        let height: CGFloat
        if let mergedCell = mergedCell(for: Location(indexPath: indexPath)) {
            width = (mergedCell.from.column...mergedCell.to.column).reduce(0) { $0 + layoutProperties.columnWidthCache[$1] } + intercellSpacing.width
            height = (mergedCell.from.row...mergedCell.to.row).reduce(0) { $0 + layoutProperties.rowHeightCache[$1] } + intercellSpacing.height
        } else {
            width = layoutProperties.columnWidthCache[indexPath.column]
            height = layoutProperties.rowHeightCache[indexPath.row]
        }

        if circularScrollingOptions.direction.contains(.horizontally) {
            if contentOffset.x > centerOffset.x {
                contentOffset.x -= centerOffset.x
            } else {
                contentOffset.x += centerOffset.x
            }
        }

        var horizontalGroupCount = 0
        if scrollPosition.contains(.left) {
            horizontalGroupCount += 1
        }
        if scrollPosition.contains(.centeredHorizontally) {
            horizontalGroupCount += 1
            contentOffset.x = max(tableView.contentOffset.x + (contentOffset.x - (tableView.contentOffset.x + (tableView.frame.width - (width + intercellSpacing.width * 2)) / 2)), 0)
        }
        if scrollPosition.contains(.right) {
            horizontalGroupCount += 1
            contentOffset.x = max(contentOffset.x - tableView.frame.width + width + intercellSpacing.width * 2, 0)
        }

        if circularScrollingOptions.direction.contains(.vertically) {
            if contentOffset.y > centerOffset.y {
                contentOffset.y -= centerOffset.y
            } else {
                contentOffset.y += centerOffset.y
            }
        }

        var verticalGroupCount = 0
        if scrollPosition.contains(.top) {
            verticalGroupCount += 1
        }
        if scrollPosition.contains(.centeredVertically) {
            verticalGroupCount += 1
            contentOffset.y = max(tableView.contentOffset.y + contentOffset.y - (tableView.contentOffset.y + (tableView.frame.height - (height + intercellSpacing.height * 2)) / 2), 0)
        }
        if scrollPosition.contains(.bottom) {
            verticalGroupCount += 1
            contentOffset.y = max(contentOffset.y - tableView.frame.height + height + intercellSpacing.height * 2, 0)
        }

        let distanceFromRightEdge = tableView.contentSize.width - contentOffset.x
        if distanceFromRightEdge < tableView.frame.width {
            contentOffset.x -= tableView.frame.width - distanceFromRightEdge
        }
        let distanceFromBottomEdge = tableView.contentSize.height - contentOffset.y
        if distanceFromBottomEdge < tableView.frame.height {
            contentOffset.y -= tableView.frame.height - distanceFromBottomEdge
        }

        if horizontalGroupCount > 1 {
            fatalError("attempt to use a scroll position with multiple horizontal positioning styles")
        }
        if verticalGroupCount > 1 {
            fatalError("attempt to use a scroll position with multiple vertical positioning styles")
        }

        if contentOffset.x < 0 {
            contentOffset.x = 0
        }
        if contentOffset.y < 0 {
            contentOffset.y = 0
        }

        return contentOffset
    }

    public func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: ScrollPosition) {
        guard let indexPath = indexPath else {
            deselectAllItems(animated: animated)
            return
        }
        guard allowsSelection else {
            return
        }

        if !allowsMultipleSelection {
            selectedIndexPaths.remove(indexPath)
            deselectAllItems(animated: animated)
        }
        if selectedIndexPaths.insert(indexPath).inserted {
            if !scrollPosition.isEmpty {
                scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
                if animated {
                    pendingSelectionIndexPath = indexPath
                    return
                }
            }
            cellsForItem(at: indexPath).forEach {
                $0.setSelected(true, animated: animated)
            }
        }
    }

    public func deselectItem(at indexPath: IndexPath, animated: Bool) {
        cellsForItem(at: indexPath).forEach {
            $0.setSelected(false, animated: animated)
        }
        selectedIndexPaths.remove(indexPath)
    }

    private func deselectAllItems(animated: Bool) {
        selectedIndexPaths.forEach { deselectItem(at: $0, animated: animated) }
    }

    public func indexPathForItem(at point: CGPoint) -> IndexPath? {
        var row = 0
        var column = 0
        if tableView.convert(tableView.bounds, to: self).contains(point), let indexPath = indexPathForItem(at: point, in: tableView) {
            (row, column) = (indexPath.row + frozenRows, indexPath.column + frozenColumns)
        } else if rowHeaderView.convert(rowHeaderView.bounds, to: self).contains(point), let indexPath = indexPathForItem(at: point, in: rowHeaderView) {
            (row, column) = (indexPath.row, indexPath.column + frozenColumns)
        } else if columnHeaderView.convert(columnHeaderView.bounds, to: self).contains(point), let indexPath = indexPathForItem(at: point, in: columnHeaderView) {
            (row, column) = (indexPath.row + frozenRows, indexPath.column)
        } else if cornerView.convert(cornerView.bounds, to: self).contains(point), let indexPath = indexPathForItem(at: point, in: cornerView) {
            (row, column) = (indexPath.row, indexPath.column)
        } else {
            return nil
        }

        row = row % numberOfRows
        column = column % numberOfColumns

        let location = Location(row: row, column: column)
        if let mergedCell = mergedCell(for: location) {
            return IndexPath(row: mergedCell.from.row, column: mergedCell.from.column)
        }
        return IndexPath(row: location.row, column: location.column)
    }

    private func indexPathForItem(at location: CGPoint, in scrollView: ScrollView) -> IndexPath? {
        let insetX = scrollView.layoutAttributes.insets.x
        let insetY = scrollView.layoutAttributes.insets.y

        func isPointInColumn(x: CGFloat, column: Int) -> Bool {
            guard column < scrollView.columnRecords.count else {
                return false
            }
            let minX = scrollView.columnRecords[column] + intercellSpacing.width
            let maxX = minX + layoutProperties.columnWidthCache[(column + scrollView.layoutAttributes.startColumn) % numberOfColumns]
            return x >= minX && x <= maxX
        }
        func isPointInRow(y: CGFloat, row: Int) -> Bool {
            guard row < scrollView.rowRecords.count else {
                return false
            }
            let minY = scrollView.rowRecords[row] + intercellSpacing.height
            let maxY = minY + layoutProperties.rowHeightCache[(row + scrollView.layoutAttributes.startRow) % numberOfRows]
            return y >= minY && y <= maxY
        }

        let point = convert(location, to: scrollView)
        let column = findIndex(in: scrollView.columnRecords, for: point.x - insetX)
        let row = findIndex(in: scrollView.rowRecords, for: point.y - insetY)

        switch (isPointInColumn(x: point.x - insetX, column: column), isPointInRow(y: point.y, row: row)) {
        case (true, true):
            return IndexPath(row: row, column: column)
        case (true, false):
            if isPointInRow(y: point.y - insetY, row: row + 1) {
                return IndexPath(row: row + 1, column: column)
            }
            return nil
        case (false, true):
            if isPointInColumn(x: point.x - insetX, column: column + 1) {
                return IndexPath(row: row, column: column + 1)
            }
            return nil
        case (false, false):
            if isPointInColumn(x: point.x - insetX, column: column + 1) && isPointInRow(y: point.y - insetY, row: row + 1) {
                return IndexPath(row: row + 1, column: column + 1)
            }
            return nil
        }
    }

    public func cellForItem(at indexPath: IndexPath) -> Cell? {
        if let cell = tableView.visibleCells.pairs
            .filter({ $0.key.row == indexPath.row && $0.key.column == indexPath.column })
            .map({ return $1 })
            .first {
            return cell
        }
        if let cell = rowHeaderView.visibleCells.pairs
            .filter({ $0.key.row == indexPath.row && $0.key.column == indexPath.column })
            .map({ return $1 })
            .first {
            return cell
        }
        if let cell = columnHeaderView.visibleCells.pairs
            .filter({ $0.key.row == indexPath.row && $0.key.column == indexPath.column })
            .map({ return $1 })
            .first {
            return cell
        }
        if let cell = cornerView.visibleCells.pairs
            .filter({ $0.key.row == indexPath.row && $0.key.column == indexPath.column })
            .map({ return $1 })
            .first {
            return cell
        }
        return nil
    }

    public func cellsForItem(at indexPath: IndexPath) -> [Cell] {
        var cells = [Cell]()
        cells.append(contentsOf:
            tableView.visibleCells.pairs
                .filter { $0.key.row == indexPath.row && $0.key.column == indexPath.column }
                .map { return $1 }
        )
        cells.append(contentsOf:
            rowHeaderView.visibleCells.pairs
                .filter { $0.key.row == indexPath.row && $0.key.column == indexPath.column }
                .map { return $1 }
        )
        cells.append(contentsOf:
            columnHeaderView.visibleCells.pairs
                .filter { $0.key.row == indexPath.row && $0.key.column == indexPath.column }
                .map { return $1 }
        )
        cells.append(contentsOf:
            cornerView.visibleCells.pairs
                .filter { $0.key.row == indexPath.row && $0.key.column == indexPath.column }
                .map { return $1 }
        )
        return cells
    }

    public func rectForItem(at indexPath: IndexPath) -> CGRect {
        let (column, row) = (indexPath.column, indexPath.row)
        guard column >= 0 && column < numberOfColumns && row >= 0 && row < numberOfRows else {
            return .zero
        }

        let columnRecords = columnHeaderView.columnRecords + tableView.columnRecords
        let rowRecords = rowHeaderView.rowRecords + tableView.rowRecords

        let origin: CGPoint
        let size: CGSize
        func originFor(column: Int, row: Int) -> CGPoint {
            let x = columnRecords[column] + (column >= frozenColumns ? tableView.frame.origin.x : 0) + intercellSpacing.width
            let y = rowRecords[row] + (row >= frozenRows ? tableView.frame.origin.y : 0) + intercellSpacing.height
            return CGPoint(x: x, y: y)
        }
        if let mergedCell = mergedCell(for: Location(row: row, column: column)) {
            origin = originFor(column: mergedCell.from.column, row: mergedCell.from.row)

            var width: CGFloat = 0
            var height: CGFloat = 0
            for column in mergedCell.from.column...mergedCell.to.column {
                width += layoutProperties.columnWidthCache[column]
            }
            for row in mergedCell.from.row...mergedCell.to.row {
                height += layoutProperties.rowHeightCache[row]
            }
            size = CGSize(width: width + intercellSpacing.width * CGFloat(mergedCell.columnCount - 1),
                          height: height + intercellSpacing.height * CGFloat(mergedCell.rowCount - 1))
        } else {
            origin = originFor(column: column, row: row)

            let width = layoutProperties.columnWidthCache[column]
            let height = layoutProperties.rowHeightCache[row]
            size = CGSize(width: width, height: height)
        }
        return CGRect(origin: origin, size: size)
    }

    func mergedCell(for indexPath: Location) -> CellRange? {
        return layoutProperties.mergedCellLayouts[indexPath]
    }
}
