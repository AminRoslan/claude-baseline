---
pack: social
agent: social-reviewer
escalate_in_qa_pass: false
---
Enable for: social networks, communities, messaging/chat, comments/reviews, marketplaces with user listings, any user-generated content (UGC) platform.

Route social-reviewer when the diff touches:
- paths/names containing: post, feed, comment, reply, like, follow, friend, block, mute, report, moderation, message, chat, dm, group, community, profile, visibility, privacy, notification, mention, share, upload, media
- visibility/permission rules for content between users
- fan-out, feed ranking, notification delivery
