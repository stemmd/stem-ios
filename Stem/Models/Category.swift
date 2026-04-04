import Foundation

struct StemCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
}

let allCategories: [StemCategory] = [
    StemCategory(id: "cat_architecture", name: "Architecture", emoji: "🏗️"),
    StemCategory(id: "cat_art",          name: "Art",          emoji: "🎨"),
    StemCategory(id: "cat_biology",      name: "Biology",      emoji: "🌿"),
    StemCategory(id: "cat_craft",        name: "Craft",        emoji: "🪡"),
    StemCategory(id: "cat_design",       name: "Design",       emoji: "✏️"),
    StemCategory(id: "cat_economics",    name: "Economics",    emoji: "📊"),
    StemCategory(id: "cat_film",         name: "Film",         emoji: "🎬"),
    StemCategory(id: "cat_food",         name: "Food",         emoji: "🍳"),
    StemCategory(id: "cat_health",       name: "Health",       emoji: "🫀"),
    StemCategory(id: "cat_history",      name: "History",      emoji: "🏛️"),
    StemCategory(id: "cat_linguistics",  name: "Linguistics",  emoji: "🗣️"),
    StemCategory(id: "cat_literature",   name: "Literature",   emoji: "📖"),
    StemCategory(id: "cat_mathematics",  name: "Mathematics",  emoji: "∑"),
    StemCategory(id: "cat_music",        name: "Music",        emoji: "🎵"),
    StemCategory(id: "cat_nature",       name: "Nature",       emoji: "🌲"),
    StemCategory(id: "cat_philosophy",   name: "Philosophy",   emoji: "🧠"),
    StemCategory(id: "cat_photography",  name: "Photography",  emoji: "📷"),
    StemCategory(id: "cat_physics",      name: "Physics",      emoji: "⚛️"),
    StemCategory(id: "cat_politics",     name: "Politics",     emoji: "🌐"),
    StemCategory(id: "cat_psychology",   name: "Psychology",    emoji: "🪞"),
    StemCategory(id: "cat_science",      name: "Science",      emoji: "🔬"),
    StemCategory(id: "cat_space",        name: "Space",        emoji: "🔭"),
    StemCategory(id: "cat_sport",        name: "Sport",        emoji: "⚽"),
    StemCategory(id: "cat_technology",   name: "Technology",   emoji: "💻"),
    StemCategory(id: "cat_urbanism",     name: "Urbanism",     emoji: "🏙️"),
]

func categoryById(_ id: String) -> StemCategory? {
    allCategories.first { $0.id == id }
}
