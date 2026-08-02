# Railmates v3 Planning: Happenings & Meetups

## Overview
Enable users to create and join meetups/happenings in specific cities with notifications.

---

## Core Features

### 1. Happening Model
```swift
struct Happening: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var city: String
    var locationName: String?  // e.g. "Central Park entrance"
    var latitude: Double
    var longitude: Double
    var dateTime: Date
    var createdBy: String  // User ID
    var createdAt: Date = Date()
    var attendeeIds: [String] = []  // User IDs
    var maxAttendees: Int?  // Optional capacity limit
    var category: String  // e.g. "Meetup", "Party", "Day Trip", "Pub Crawl"
}
```

### 2. User Authentication
**Required for v3** - Need to track who's joining events
- Firebase Authentication (Email, Google, Apple Sign-In)
- Simple User model:
```swift
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String?
    var createdAt: Date = Date()
}
```

### 3. UI Components Needed

#### HappeningsListView
- List of upcoming happenings in selected city
- Filter by city/date
- "Create Happening" button
- Shows attendee count
- Shows distance from user

#### AddHappeningView
- Similar to AddLocationTipView
- Fields: title, description, city, location, date/time, category, max attendees
- Date picker for event time
- Geocoding for location

#### HappeningDetailView
- Full details
- "I'm Joining" / "Leave Event" button
- List of attendees (names/count)
- Map showing location
- Share button
- Edit/Delete (if creator)

### 4. Notifications

#### Push Notifications Setup
1. Enable Push Notifications in Xcode capabilities
2. Add Firebase Cloud Messaging (FCM)
3. Request notification permissions from user

#### Notification Triggers
- **New happening in your area** (if user has favorited a city)
- **Happening starting soon** (1 hour before)
- **Someone joined your happening**
- **Happening canceled/updated**

#### Implementation Pattern
```swift
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func requestPermission() async throws -> Bool { ... }
    func scheduleLocalNotification(for happening: Happening) { ... }
    func sendPushToAttendees(happeningId: String, message: String) { ... }
}
```

### 5. Database Structure

```
happenings/
  {happeningId}/
    - title, description, city, etc.
    attendees/
      {userId}/
        - joinedAt: Date
        - notificationToken: String?

users/
  {userId}/
    - displayName, email, etc.
    favoriteCities: [String]
    notificationToken: String?
```

### 6. HappeningStore
```swift
class HappeningStore: ObservableObject {
    @Published var happenings: [Happening] = []
    
    func fetchUpcoming(in city: String?) { ... }
    func create(_ happening: Happening) { ... }
    func join(happeningId: String, userId: String) { ... }
    func leave(happeningId: String, userId: String) { ... }
    func delete(happeningId: String) { ... }
}
```

---

## Integration with Existing App

### Navigation Updates
Add a new tab or section:
- **Tips** (existing)
- **Happenings** (new)
- **Profile** (new - for managing joined events)

### ContentView Modification
```swift
TabView {
    TipsTabView()  // Current ContentView
        .tabItem { Label("Tips", systemImage: "map.fill") }
    
    HappeningsTabView()  // New
        .tabItem { Label("Events", systemImage: "calendar") }
    
    ProfileView()  // New
        .tabItem { Label("Profile", systemImage: "person.fill") }
}
```

---

## Development Steps

### Phase 1: Authentication (Required First)
- [ ] Add Firebase Authentication
- [ ] Create User model
- [ ] Add sign-in/sign-up views
- [ ] Store user profile in Firestore
- [ ] Update existing tip creation to include user ID

### Phase 2: Core Happening Features
- [ ] Create Happening model
- [ ] Create HappeningStore
- [ ] Build AddHappeningView
- [ ] Build HappeningsListView
- [ ] Build HappeningDetailView
- [ ] Implement join/leave functionality

### Phase 3: Notifications
- [ ] Request notification permissions
- [ ] Setup FCM
- [ ] Store device tokens in user profile
- [ ] Implement local notifications (1 hour before event)
- [ ] Implement push notifications (new events, updates)

### Phase 4: Polish
- [ ] Add filters (date range, category, city)
- [ ] Add search functionality
- [ ] Enable sharing happenings
- [ ] Add creator controls (edit/delete/cancel)
- [ ] Implement capacity limits
- [ ] Show "Event Full" state

---

## Technical Considerations

### Date Handling
- Use `Date` for storage
- Display in user's local timezone
- Consider timezone for international travelers
- Use `.formatted(date:time:)` for display

### Real-time Updates
- Use Firestore snapshots for attendee counts
- Update UI when someone joins/leaves
- Handle race conditions for capacity limits

### Privacy
- Let users choose display name (vs. real name)
- Option to hide from certain events
- Report/block functionality for safety

---

## Nice-to-Have Features
- Chat per happening
- Photo sharing after event
- "Happened" archive with photos
- Recurring events
- Private events (invite-only)
- Integration with trip journals (v4)

---

## Estimated Timeline
- **Phase 1 (Auth)**: 2-3 days
- **Phase 2 (Core)**: 3-4 days  
- **Phase 3 (Notifications)**: 2-3 days
- **Phase 4 (Polish)**: 1-2 days

**Total: ~10 days** for a solid v3

---

## Testing Checklist
- [ ] Create happening
- [ ] Join happening
- [ ] Leave happening
- [ ] Delete happening (as creator)
- [ ] Receive notification 1 hour before
- [ ] Event with max capacity
- [ ] Multiple users joining simultaneously
- [ ] Happenings in different timezones
- [ ] Notification permissions denied scenario
