# TripStory Refactor - Implementation Guide

**Date**: 2026-08-03  
**Status**: In Progress 🚧  
**Goal**: Transform Journals → TripStories for post-trip storytelling  

---

## ✅ Completed Steps

### **Step 1: New Models** ✅
- ✅ Created `TripStory.swift`
- ✅ Created `TripStoryStore.swift`
- ✅ Added Legacy models for migration

---

## 🚧 Remaining Steps

### **Step 2: Create New Views**
- [ ] `TripStoriesListView.swift` (rename from JournalsListView)
- [ ] `CreateTripStoryView.swift` (rename from AddJournalView)
- [ ] `TripStoryDetailView.swift` (rename from JournalDetailView)
- [ ] `EditTripStoryView.swift`

### **Step 3: Update Navigation**
- [ ] Update `MainTabView.swift` ("Journals" → "Stories")
- [ ] Update tab icon (book → story/document icon)

### **Step 4: Data Migration**
- [ ] Create migration script
- [ ] Convert existing Journal docs to TripStory
- [ ] Merge JournalEntries into story text
- [ ] Preserve photos

### **Step 5: Update Firestore**
- [ ] Create new `tripStories` collection
- [ ] Set up indexes for search
- [ ] Update security rules

### **Step 6: Remove Old Code**
- [ ] Archive `Journal.swift`
- [ ] Archive `JournalStore.swift`
- [ ] Archive old views
- [ ] Clean up references

---

## 📊 Progress Tracking

**Files Created**: 2/6  
**Views Updated**: 0/4  
**Migration**: Not started  
**Testing**: Not started  

---

## 🎯 Next Immediate Steps

**Say to continue:**
> "Continue with Step 2 - create the new views"

**Or pause here to:**
- Review the models
- Test compilation
- Plan migration strategy

---

## 📁 File Structure

### **New Files (Created):**
```
Models/
  TripStory.swift ✅

Stores/
  TripStoryStore.swift ✅

Views/
  TripStoriesListView.swift 🔜
  CreateTripStoryView.swift 🔜
  TripStoryDetailView.swift 🔜
  EditTripStoryView.swift 🔜
```

### **Files to Update:**
```
MainTabView.swift
RailmatesApp.swift (if needed)
```

### **Files to Archive (After Migration):**
```
Journal.swift → LegacyJournal (kept in TripStory.swift)
JournalStore.swift → Will be removed
JournalsListView.swift → Replaced by TripStoriesListView
AddJournalView.swift → Replaced by CreateTripStoryView
JournalDetailView.swift → Replaced by TripStoryDetailView
```

---

## 🔄 Migration Strategy

### **Option A: Clean Start** ⭐ RECOMMENDED
1. Deploy new TripStory system
2. Keep old journals read-only
3. Let users manually recreate as stories
4. Eventually remove old system

### **Option B: Automatic Migration**
1. Write migration script
2. Convert all journals to stories
3. Merge entries into story text
4. One-time bulk update

### **Option C: Dual System**
1. Run both systems
2. Gradually migrate users
3. Sunset old system later

**Recommendation**: Option A (Clean Start) since:
- Simpler implementation
- Better data quality (users write proper stories)
- No complex migration bugs
- Fresh start with better UX

---

## 💾 Data Preservation

### **What to Keep:**
- User's journal titles → story titles
- Journal descriptions → start of story
- Entry notes → merged into story
- Photos → preserved in photos array
- Dates → tripStart/tripEnd

### **What Changes:**
- Multiple entries → single story text
- Structured fields → free-form narrative
- Real-time updates → post-trip stories

---

## 🧪 Testing Plan

### **Phase 1: Model Testing**
```
[ ] TripStory model encodes/decodes correctly
[ ] PlaceVisited works
[ ] StoryPhoto works
[ ] Computed properties work (duration, route)
[ ] Search keywords generate correctly
```

### **Phase 2: Store Testing**
```
[ ] Can create story
[ ] Can fetch public stories
[ ] Can fetch my stories
[ ] Can update story
[ ] Can delete story
[ ] Like/unlike works
[ ] View counter increments
```

### **Phase 3: UI Testing**
```
[ ] Can browse stories
[ ] Can create new story
[ ] Can edit own story
[ ] Can view story detail
[ ] Can search for cities
[ ] Can like stories
[ ] Photos display correctly
```

---

## 🎨 UI Components Needed

### **Story Card (List View):**
- Title
- Creator name
- Trip dates
- Route summary (Paris → Lyon → Geneva)
- Photo preview (first 3-4 photos)
- Engagement (views, likes)

### **Create Story Form:**
- Title field
- Date range picker
- Place selector (with + button)
- Large text editor (story)
- Photo uploader with captions
- Privacy toggle

### **Story Detail:**
- Full story text (scrollable)
- Photo gallery
- Route visualization
- Like button
- Share button
- View/like counts
- Comments (future)

---

## 🚀 Ready to Continue?

**Current status:** Models complete, ready for views  

**Next step:** Create the 4 main views  

**Estimated time:** 30-45 minutes  

---

**Let me know when you're ready to continue!** 📖✨
