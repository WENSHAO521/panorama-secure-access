import AppKit

final class TrayStatusItem {
    let statusItem: NSStatusItem

    private let contentView: TrayContentView

    init?(onMenuRequested: @escaping () -> Void) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        contentView = TrayContentView(onMenuRequested: onMenuRequested)

        guard let button = statusItem.button else {
            NSStatusBar.system.removeStatusItem(statusItem)
            return nil
        }
        button.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: button.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: NSStatusBar.system.thickness),
        ])
    }

    // Resizing the status item while its menu tracks drops the clicks on the
    // menu's items (#2933), so title and icon changes wait for it to close.
    private var isMenuOpen = false
    private var pendingTitle: String?
    private var pendingImage: (image: NSImage, position: String)?

    func setImage(_ image: NSImage, position: String) {
        if isMenuOpen {
            pendingImage = (image, position)
            return
        }
        if contentView.setImage(image, position: position) {
            statusItem.button?.sizeToFit()
        }
    }

    func setTitle(_ title: String) {
        if isMenuOpen {
            pendingTitle = title
            return
        }
        if contentView.setTitle(title) {
            statusItem.button?.sizeToFit()
        }
    }

    // `statusItem.menu` + `performClick` shows nothing while a full-screen app
    // owns the Space (#2965); popping the menu up from the button does.
    // popUp tracks the menu modally and returns once it has closed.
    func openMenu(_ menu: NSMenu) {
        guard !isMenuOpen, let button = statusItem.button else {
            return
        }
        isMenuOpen = true
        button.highlight(true)
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 5),
            in: button
        )
        button.highlight(false)
        closeMenu()
    }

    func closeMenu() {
        guard isMenuOpen else {
            return
        }
        isMenuOpen = false
        if let pending = pendingImage {
            pendingImage = nil
            setImage(pending.image, position: pending.position)
        }
        if let title = pendingTitle {
            pendingTitle = nil
            setTitle(title)
        }
    }

    func remove() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}

private final class TrayContentView: NSView {
    private let onMenuRequested: () -> Void

    private let imageView: NSImageView = {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyDown
        view.isHidden = true
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private let titleView = TrayTitleView()

    private let stackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.distribution = .equalSpacing
        return stack
    }()

    init(onMenuRequested: @escaping () -> Void) {
        self.onMenuRequested = onMenuRequested
        super.init(frame: .zero)

        titleView.isHidden = true
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])

        applyPosition("leading")
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.setContentHuggingPriority(.required, for: .horizontal)
        titleView.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            titleView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: TrayTitleView.width
            ),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: NSImage, position: String) -> Bool {
        let wasHidden = imageView.isHidden
        let previousSize = imageView.image?.size ?? .zero
        let sizeChanged = previousSize != image.size
        imageView.image = image
        imageView.isHidden = false
        applyPosition(position)
        return wasHidden != imageView.isHidden || sizeChanged
    }

    func setTitle(_ title: String) -> Bool {
        titleView.setTitle(title)
    }

    private func applyPosition(_ position: String) {
        let views: [NSView] = position == "trailing"
            ? [titleView, imageView]
            : [imageView, titleView]

        if stackView.arrangedSubviews == views {
            return
        }

        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        for (index, view) in views.enumerated() {
            stackView.insertArrangedSubview(view, at: index)
        }
    }

    override func mouseDown(with event: NSEvent) {
        onMenuRequested()
    }

    override func rightMouseDown(with event: NSEvent) {
        onMenuRequested()
    }
}
