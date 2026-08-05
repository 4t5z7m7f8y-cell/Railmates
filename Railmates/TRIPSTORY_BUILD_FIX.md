# Build Fix - TripStory Parameter Order

## ❌ Error:
```
error: Argument 'isPublic' must precede argument 'tripStart'
```

## 🔧 Fix Required:

The TripStory struct has parameters in a specific order. Any place we create a TripStory instance must match that order.

### **Correct Parameter Order:**
```swift
TripStory(
    id: String? = nil,
    title: String,
    story: String,
    createdBy: String,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    isPublic: Bool = true,           // ← comes BEFORE dates
    tripStart: Date,                 // ← comes AFTER isPublic
    tripEnd: Date,
    visitedPlaces: [PlaceVisited] = [],
    photos: [StoryPhoto] = [],
    viewCount: Int = 0,
    likeCount: Int = 0,
    likedBy: [String] = []
)
```

### **Files to Check:**

1. **CreateTripStoryView.swift** - Line ~280
2. **TripStoryDetailView.swift** - Preview at bottom
3. **EditTripStoryView.swift** - Preview at bottom

---

## Quick Fixes:

### **Fix 1: CreateTripStoryView (saveStory function)**

**Change FROM:**
```swift
let newStory = TripStory(
    title: title,
    story: story,
    createdBy: userId,
    tripStart: tripStart,
    tripEnd: tripEnd,
    visitedPlaces: visitedPlaces,
    photos: storyPhotos,
    isPublic: isPublic  // ← WRONG ORDER
)
```

**Change TO:**
```swift
let newStory = TripStory(
    title: title,
    story: story,
    createdBy: userId,
    isPublic: isPublic,  // ← MOVE BEFORE dates
    tripStart: tripStart,
    tripEnd: tripEnd,
    visitedPlaces: visitedPlaces,
    photos: storyPhotos
)
```

### **Fix 2: TripStoryDetailView (Preview)**

**Change FROM:**
```swift
TripStory(
    title: "Summer Interrail 2026",
    story: "This is my amazing trip story...",
    createdBy: "test",
    tripStart: Date(),
    tripEnd: Date()
)
```

**Change TO:**
```swift
TripStory(
    title: "Summer Interrail 2026",
    story: "This is my amazing trip story...",
    createdBy: "test",
    isPublic: true,      // ← ADD THIS
    tripStart: Date(),
    tripEnd: Date()
)
```

### **Fix 3: EditTripStoryView (Preview)**

**Change FROM:**
```swift
TripStory(
    title: "Test Story",
    story: "This is a test story with enough characters to pass validation.",
    createdBy: "test",
    tripStart: Date(),
    tripEnd: Date()
)
```

**Change TO:**
```swift
TripStory(
    title: "Test Story",
    story: "This is a test story with enough characters to pass validation.",
    createdBy: "test",
    isPublic: true,      // ← ADD THIS
    tripStart: Date(),
    tripEnd: Date()
)
```

---

## ✅ To Apply Fixes:

Since the new files aren't in Xcode yet, you need to:

1. **Add files to Xcode project:**
   - Right-click on project navigator
   - Add Files to "Railmates"
   - Select all 6 new files:
     - TripStory.swift
     - TripStoryStore.swift
     - TripStoriesListView.swift
     - CreateTripStoryView.swift
     - TripStoryDetailView.swift
     - EditTripStoryView.swift

2. **Then build** - you'll see the actual error locations

3. **Apply the fixes above** to those locations

---

## Alternative: Let Me Fix The Files

If you'd like, I can recreate the files with the correct parameter order. Just say:
> "Fix the parameter order in all files"

And I'll update them all at once! ✅
