#!/bin/bash

# Railmates - Git Commit Script
# Run this script to commit and push v3

echo "🚂 Railmates - Committing v3..."

# Check git status
echo ""
echo "📊 Current status:"
git status

# Confirm
echo ""
read -p "⚠️  Commit and push these changes? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Add all files
    echo "📦 Adding files..."
    git add .
    
    # Commit
    echo "💾 Committing..."
    git commit -m "Complete v3: Authentication, Happenings, Notifications & Polish

Implemented all 4 phases of v3:
- Phase 1: Email/password auth, user profiles, favorite cities
- Phase 2: Event creation, browsing, join/leave, attendee tracking
- Phase 3: Local notifications, permission handling, FCM ready
- Phase 4: Search, filters, category icons, sharing

New Features:
- User authentication with Firebase Auth
- User profiles with display names and favorite cities
- Create happenings/meetups in cities
- Join/leave events with capacity limits
- Local notifications 1 hour before events
- Search events by text
- Filter by city, category, or 'My Events'
- Share events via share sheet
- Beautiful category icons and colors
- Tab-based navigation (Tips, Events, Profile)

Technical:
- 11 new files (models, managers, views)
- Modified app structure for auth flow
- Optional FCM support with conditional compilation
- async/await throughout
- Complete documentation

Documentation:
- SESSION_SUMMARY.md (complete session log)
- START_HERE.md (quick reference)
- PROJECT_STATUS.md (updated to v3)
- V3_PLANNING.md
- V3_IMPLEMENTATION_SUMMARY.md
- V3_PHASES_3_4_SUMMARY.md

v3 complete! Ready for testing and polish. 🚂✨"
    
    # Push
    echo "🚀 Pushing to remote..."
    git push origin main
    
    echo ""
    echo "✅ Done! v3 committed and pushed!"
else
    echo "❌ Cancelled. No changes made."
fi
