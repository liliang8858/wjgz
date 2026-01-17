import UIKit
import SpriteKit
import Combine

/// 现代化的游戏视图控制器 - 使用 MVVM 架构
public final class ModernGameViewController: UIViewController {
    
    // MARK: - Properties
    
    private var gameScene: ModernGameScene!
    private var viewModel: GameSceneViewModel!
    private var skView: SKView!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    
    private var pauseButton: UIButton!
    private var settingsButton: UIButton!
    private var gameOverView: UIView!
    
    // MARK: - Initialization
    
    public init(level: Level) {
        super.init(nibName: nil, bundle: nil)
        
        // 创建 ViewModel
        viewModel = DIContainer.shared.createGameSceneViewModel(for: level)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // 从 storyboard 初始化时，使用当前关卡或默认关卡
        let currentLevel = LevelConfig.shared.getCurrentLevel()
        viewModel = DIContainer.shared.createGameSceneViewModel(for: currentLevel)
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupSKView()
        setupUI()
        setupBindings()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 在布局完成后设置游戏场景，确保尺寸正确
        if gameScene == nil {
            setupGameScene()
        } else {
            // 如果场景已存在，更新其尺寸以适应新的布局
            updateSceneSize()
        }
    }
    
    private func updateSceneSize() {
        guard let gameScene = gameScene else { return }
        
        let newSize = skView.bounds.size
        
        // 如果尺寸发生变化，重新设置场景
        if gameScene.size != newSize {
            gameScene.size = newSize
            
            // 重新设置锚点和位置
            gameScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            gameScene.position = CGPoint.zero
            gameScene.setScale(1.0)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 设置状态栏样式
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 开始游戏
        gameScene.isPaused = false
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 暂停游戏
        viewModel.pauseGame()
    }
    
    // MARK: - Status Bar
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = .black
    }
    
    private func setupSKView() {
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // SpriteKit 配置
        skView.showsFPS = GameConfiguration.shared.showFPS
        skView.showsNodeCount = GameConfiguration.shared.enablePerformanceMetrics
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = GameConfiguration.shared.targetFPS
        
        view.addSubview(skView)
    }
    
    private func setupGameScene() {
        // 确保使用正确的视图尺寸
        let sceneSize = skView.bounds.size
        
        gameScene = ModernGameScene(viewModel: viewModel, size: sceneSize)
        
        // 设置场景的缩放模式 - 尝试不同的模式来解决显示问题
        gameScene.scaleMode = .resizeFill  // 改为 resizeFill 确保填满整个视图
        
        // 设置特效服务的场景引用
        let effectsService = DIContainer.shared.resolve(EffectsServiceProtocol.self) as? EffectsService
        effectsService?.setScene(gameScene)
        
        skView.presentScene(gameScene)
    }
    
    private func setupUI() {
        setupTopButtons()
        setupGameOverView()
    }
    
    private func setupTopButtons() {
        // 暂停按钮
        pauseButton = UIButton(type: .system)
        pauseButton.setTitle("⏸", for: .normal)
        pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        pauseButton.tintColor = .white
        pauseButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        pauseButton.layer.cornerRadius = 20
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        
        view.addSubview(pauseButton)
        
        // 设置按钮
        settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙️", for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        settingsButton.tintColor = .white
        settingsButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        settingsButton.layer.cornerRadius = 20
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        view.addSubview(settingsButton)
        
        // 约束
        NSLayoutConstraint.activate([
            pauseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pauseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pauseButton.widthAnchor.constraint(equalToConstant: 40),
            pauseButton.heightAnchor.constraint(equalToConstant: 40),
            
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupGameOverView() {
        gameOverView = UIView()
        gameOverView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        gameOverView.translatesAutoresizingMaskIntoConstraints = false
        gameOverView.isHidden = true
        
        view.addSubview(gameOverView)
        
        // 游戏结束标签
        let gameOverLabel = UILabel()
        gameOverLabel.text = "游戏结束"
        gameOverLabel.font = UIFont.boldSystemFont(ofSize: 32)
        gameOverLabel.textColor = .white
        gameOverLabel.textAlignment = .center
        gameOverLabel.translatesAutoresizingMaskIntoConstraints = false
        
        gameOverView.addSubview(gameOverLabel)
        
        // 重新开始按钮
        let restartButton = UIButton(type: .system)
        restartButton.setTitle("重新开始", for: .normal)
        restartButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        restartButton.tintColor = .white
        restartButton.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        restartButton.layer.cornerRadius = 25
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.addTarget(self, action: #selector(restartButtonTapped), for: .touchUpInside)
        
        gameOverView.addSubview(restartButton)
        
        // 返回按钮
        let backButton = UIButton(type: .system)
        backButton.setTitle("返回", for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        backButton.layer.cornerRadius = 25
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        gameOverView.addSubview(backButton)
        
        // 约束
        NSLayoutConstraint.activate([
            gameOverView.topAnchor.constraint(equalTo: view.topAnchor),
            gameOverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameOverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameOverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            gameOverLabel.centerXAnchor.constraint(equalTo: gameOverView.centerXAnchor),
            gameOverLabel.centerYAnchor.constraint(equalTo: gameOverView.centerYAnchor, constant: -100),
            
            restartButton.centerXAnchor.constraint(equalTo: gameOverView.centerXAnchor),
            restartButton.topAnchor.constraint(equalTo: gameOverLabel.bottomAnchor, constant: 50),
            restartButton.widthAnchor.constraint(equalToConstant: 150),
            restartButton.heightAnchor.constraint(equalToConstant: 50),
            
            backButton.centerXAnchor.constraint(equalTo: gameOverView.centerXAnchor),
            backButton.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 150),
            backButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBindings() {
        // 监听游戏状态变化
        viewModel.$gameState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game State Handling
    
    private func handleGameStateChange(_ state: GameState) {
        switch state {
        case .idle:
            gameOverView.isHidden = true
            pauseButton.setTitle("▶️", for: .normal)
            
        case .playing:
            gameOverView.isHidden = true
            pauseButton.setTitle("⏸", for: .normal)
            gameScene.isPaused = false
            
        case .paused:
            pauseButton.setTitle("▶️", for: .normal)
            gameScene.isPaused = true
            
        case .gameOver(let reason):
            showGameOver(reason: reason)
        }
    }
    
    private func showGameOver(reason: GameEndReason) {
        gameOverView.isHidden = false
        
        // 更新游戏结束文本
        if let gameOverLabel = gameOverView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            switch reason {
            case .victory:
                gameOverLabel.text = "恭喜过关!"
                gameOverLabel.textColor = .systemGreen
            case .timeUp:
                gameOverLabel.text = "时间到!"
                gameOverLabel.textColor = .systemOrange
            case .movesExhausted:
                gameOverLabel.text = "步数用完!"
                gameOverLabel.textColor = .systemRed
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func pauseButtonTapped() {
        switch viewModel.gameState {
        case .playing:
            viewModel.pauseGame()
        case .paused:
            viewModel.resumeGame()
        default:
            break
        }
    }
    
    @objc private func settingsButtonTapped() {
        // 显示设置界面
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .overFullScreen
        present(settingsVC, animated: true)
    }
    
    @objc private func restartButtonTapped() {
        viewModel.restartGame()
    }
    
    @objc private func backButtonTapped() {
        // 返回关卡选择界面
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Memory Management
    
    deinit {
        // 清理资源
        gameScene?.removeFromParent()
        skView?.presentScene(nil)
    }
}

// MARK: - Settings View Controller

private class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // 设置界面内容
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "设置"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.backgroundColor = UIColor.systemBlue
        closeButton.tintColor = .white
        closeButton.layer.cornerRadius = 25
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 400),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}