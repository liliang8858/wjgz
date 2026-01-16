import Foundation

struct Level {
    let id: Int
    let name: String
    let targetScore: Int
    let targetMerges: Int
    let maxMoves: Int?  // nil = infinite
    let starThresholds: [Int]  // 3 values for 1, 2, 3 stars

    func calculateStars(score: Int) -> Int {
        if score >= starThresholds[2] { return 3 }
        if score >= starThresholds[1] { return 2 }
        if score >= starThresholds[0] { return 1 }
        return 0
    }
}

class LevelConfig {
    static let shared = LevelConfig()

    private(set) var levels: [Level] = []
    private(set) var currentLevelIndex: Int = 0

    private init() {
        loadLevels()
        loadProgress()
    }

    private func loadLevels() {
        levels = [
            Level(id: 1, name: "初入剑门", targetScore: 100, targetMerges: 5, maxMoves: nil, starThresholds: [100, 150, 200]),
            Level(id: 2, name: "修炼剑诀", targetScore: 200, targetMerges: 8, maxMoves: nil, starThresholds: [200, 300, 400]),
            Level(id: 3, name: "剑意初成", targetScore: 300, targetMerges: 12, maxMoves: nil, starThresholds: [300, 450, 600]),
            Level(id: 4, name: "剑气纵横", targetScore: 500, targetMerges: 15, maxMoves: nil, starThresholds: [500, 750, 1000]),
            Level(id: 5, name: "剑道大成", targetScore: 800, targetMerges: 20, maxMoves: nil, starThresholds: [800, 1200, 1600]),
        ]
    }

    func getCurrentLevel() -> Level {
        return levels[min(currentLevelIndex, levels.count - 1)]
    }

    func completeLevel(stars: Int) {
        if stars > 0 && currentLevelIndex < levels.count - 1 {
            currentLevelIndex += 1
            saveProgress()
        }
    }

    func restartLevel() {
        // Current level stays the same
    }

    func goToNextLevel() {
        if currentLevelIndex < levels.count - 1 {
            currentLevelIndex += 1
            saveProgress()
        }
    }

    private func saveProgress() {
        UserDefaults.standard.set(currentLevelIndex, forKey: "currentLevel")
    }

    private func loadProgress() {
        currentLevelIndex = UserDefaults.standard.integer(forKey: "currentLevel")
    }

    func resetProgress() {
        currentLevelIndex = 0
        saveProgress()
    }
}
