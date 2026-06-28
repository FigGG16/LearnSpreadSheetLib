//
//  ViewController.swift
//  LearnSpreadSheetLib
//
//  Created by Felix Huang on 2026/6/28.
//

import UIKit

/// SpreadsheetView 的最小学习 Demo。
///
/// 这个页面刻意只保留四件事：
/// 1. 3 行 3 列；
/// 2. 自定义 Cell；
/// 3. 固定首行和首列，并允许横向、纵向滚动；
/// 4. 修改模型后调用 `reloadData()`。
///
/// 学习建议：先在下面的数据源方法打断点，再从
/// `SpreadsheetView.reloadData()` 跟进 `LayoutEngine.layout()`。
final class ViewController: UIViewController {

    // MARK: - Demo model

    /// SpreadsheetView 不持有业务数据。控制器先修改这个二维数组，随后通知表格刷新。
    private var values = [
        ["项目", "第一季度", "第二季度"],
        ["收入", "¥12,000", "¥18,000"],
        ["支出", "¥8,000", "¥9,500"]
    ]

    private var refreshCount = 0

    // MARK: - Views

    private let spreadsheetView = SpreadsheetView()

    private lazy var refreshButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "修改数据并 reloadData"
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpreadsheetView 源码学习"
        view.backgroundColor = .systemBackground

        configureSpreadsheetView()
        configureLayout()
    }

    private func configureSpreadsheetView() {
        // 注册只描述“如何创建 Cell”。真正取出复用 Cell 的动作发生在 cellForItemAt 中。
        spreadsheetView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseIdentifier)
        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self

        // 故意让 3 列总宽、3 行总高超过屏幕可见区域，以便观察双向滚动和 Cell 回收。
        spreadsheetView.alwaysBounceHorizontal = true
        spreadsheetView.alwaysBounceVertical = true
    }

    private func configureLayout() {
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        spreadsheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)
        view.addSubview(spreadsheetView)

        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            spreadsheetView.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 12),
            spreadsheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spreadsheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spreadsheetView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func refreshData() {
        refreshCount += 1
        values[1][1] = "¥\(12_000 + refreshCount * 1_000)"
        values[2][2] = "刷新 #\(refreshCount)"

        // LEARNING: 这个版本没有局部刷新 API。reloadData 会重新读取行列数、尺寸和冻结配置，
        // 清空四个内部 ScrollView 的可见对象，然后在下一次 layoutSubviews 中重建可见 Cell。
        spreadsheetView.reloadData()
    }
}

// MARK: - SpreadsheetViewDataSource

extension ViewController: SpreadsheetViewDataSource {

    /// 必需方法 1/4：返回列数。
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        values.first?.count ?? 0
    }

    /// 必需方法 2/4：返回行数。
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        values.count
    }

    /// 必需方法 3/4：列宽会在 reloadData 阶段被读取并缓存，而不是为每个可见 Cell 单独查询。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        column == 0 ? 130 : 190
    }

    /// 必需方法 4/4：与列宽一样，行高会进入 `rowHeightCache`。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        row == 0 ? 70 : 190
    }

    /// LayoutEngine 发现某个地址刚进入可见区域时才调用这里。
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        let cell = spreadsheetView.dequeueReusableCell(
            withReuseIdentifier: DemoTextCell.reuseIdentifier,
            for: indexPath
        ) as! DemoTextCell

        cell.configure(
            text: values[indexPath.row][indexPath.column],
            isHeader: indexPath.row == 0 || indexPath.column == 0
        )
        return cell
    }

    /// 返回 1 表示第 0 列被分配到固定列相关的内部 ScrollView。
    func frozenColumns(in spreadsheetView: SpreadsheetView) -> Int { 1 }

    /// 返回 1 表示第 0 行被分配到固定行相关的内部 ScrollView。
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int { 1 }
}

// MARK: - SpreadsheetViewDelegate

extension ViewController: SpreadsheetViewDelegate {
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didSelectItemAt indexPath: IndexPath) {
        print("[SpreadsheetDemo] selected row=\(indexPath.row), column=\(indexPath.column)")
    }
}

// MARK: - Custom Cell

/// 最小自定义 Cell：业务子视图只放在 `contentView` 中，不接触库内部的 frame 和复用集合。
private final class DemoTextCell: Cell {
    static let reuseIdentifier = "DemoTextCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(text: String, isHeader: Bool) {
        label.text = text
        label.font = isHeader ? .preferredFont(forTextStyle: .headline) : .preferredFont(forTextStyle: .body)
        backgroundColor = isHeader ? .systemBlue.withAlphaComponent(0.16) : .secondarySystemBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // LEARNING: dequeue 命中复用池后，库会先调用这里，再把 Cell 交给 cellForItemAt。
        // 所有可能因上一次 indexPath 遗留的业务状态都应在这里恢复默认值。
        label.text = nil
        label.font = .preferredFont(forTextStyle: .body)
        backgroundColor = .secondarySystemBackground
    }
}
