import Foundation

/// 依赖注入容器 - 管理所有服务的生命周期和依赖关系
public final class DIContainer {
    
    // MARK: - Singleton
    
    public static let shared = DIContainer()
    
    // MARK: - Properties
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Registration
    
    /// 注册单例服务
    public func register<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        services[key] = instance
    }
    
    /// 注册工厂方法
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// 注册懒加载单例
    public func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        factories[key] = { [weak self] in
            if let existingInstance = self?.services[key] as? T {
                return existingInstance
            } else {
                let newInstance = factory()
                self?.services[key] = newInstance
                return newInstance
            }
        }
    }
    
    // MARK: - Resolution
    
    /// 解析服务
    public func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        // 首先检查已注册的实例
        if let instance = services[key] as? T {
            return instance
        }
        
        // 然后检查工厂方法
        if let factory = factories[key] {
            if let instance = factory() as? T {
                return instance
            }
        }
        
        fatalError("Service of type \(type) is not registered")
    }
    
    /// 可选解析服务
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        if let instance = services[key] as? T {
            return instance
        }
        
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    // MARK: - Cleanup
    
    /// 清除所有服务
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        factories.removeAll()
    }
    
    /// 移除特定服务
    public func remove<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultServices() {
        // 注册配置服务
        registerLazySingleton(GameConfigurationProtocol.self) {
            GameConfiguration()
        }
        
        // 注册音效服务
        registerLazySingleton(AudioServiceProtocol.self) {
            AudioService()
        }
        
        // 注册特效服务
        registerLazySingleton(EffectsServiceProtocol.self) {
            EffectsService()
        }
        
        // 注册分数计算器
        registerLazySingleton(ScoreCalculator.self) {
            ScoreCalculator()
        }
        
        // 注册关卡配置管理器
        registerLazySingleton(LevelConfigurationManager.self) {
            LevelConfigurationManager()
        }
        
        // 注册游戏状态管理器
        registerLazySingleton(GameStateManager.self) {
            GameStateManager()
        }
        
        // 注册存储服务
        registerLazySingleton(StorageServiceProtocol.self) {
            UserDefaultsStorageService()
        }
    }
}

// MARK: - Convenience Extensions

extension DIContainer {
    
    /// 创建游戏用例
    public func createGamePlayUseCase(for level: Level) -> GamePlayUseCase {
        let gridConfig = GridConfiguration(
            radius: 3,
            hexSize: 40,
            center: CGPoint(x: 0, y: 0)
        )
        
        let gameGrid = GameGrid(config: gridConfig)
        let matchEngine = MatchEngine(gameGrid: gameGrid)
        let scoreCalculator = resolve(ScoreCalculator.self)
        let audioService = resolve(AudioServiceProtocol.self)
        let effectsService = resolve(EffectsServiceProtocol.self)
        
        return GamePlayUseCase(
            gameGrid: gameGrid,
            matchEngine: matchEngine,
            scoreCalculator: scoreCalculator,
            audioService: audioService,
            effectsService: effectsService,
            levelConfig: level
        )
    }
    
    /// 创建游戏场景视图模型
    public func createGameSceneViewModel(for level: Level) -> GameSceneViewModel {
        let gamePlayUseCase = createGamePlayUseCase(for: level)
        let gameStateManager = resolve(GameStateManager.self)
        
        return GameSceneViewModel(
            gamePlayUseCase: gamePlayUseCase,
            gameStateManager: gameStateManager,
            level: level
        )
    }
}

// MARK: - Property Wrapper

/// 属性包装器，用于自动注入依赖
@propertyWrapper
public struct Injected<T> {
    private let container: DIContainer
    
    public init(container: DIContainer = .shared) {
        self.container = container
    }
    
    public var wrappedValue: T {
        return container.resolve(T.self)
    }
}

/// 可选依赖注入属性包装器
@propertyWrapper
public struct OptionalInjected<T> {
    private let container: DIContainer
    
    public init(container: DIContainer = .shared) {
        self.container = container
    }
    
    public var wrappedValue: T? {
        return container.resolveOptional(T.self)
    }
}