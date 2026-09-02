#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

# UPSTREAM ARCHIVED (2026-09-02)
# ilyamiro/imperative-dots is archived. Its install.sh is frozen at
# DOTS_VERSION="2.0.0" and will never advance, so the old polling loop reported a
# permanent phantom "update available" against our local 1.7.6-1. The successor,
# ilyamiro/serpantinum, is a different project (a shell, not dotfiles) whose
# installer discards the existing configuration - so it is NOT an update target
# and must never be triggered from the topbar. This notifier is therefore
# informational only: it clears the pending flag and says its piece once.

# State file that tells the topbar to show the update button
PENDING_FILE="$QS_CACHE_UPDATER/update_pending"
# Marker so the archive notice is shown only once, not on every login
NOTICE_FILE="$QS_CACHE_UPDATER/archive_notice_shown"

# No upgrade path exists: make sure the topbar update button stays hidden.
rm -f "$PENDING_FILE"

if [[ ! -f "$NOTICE_FILE" ]]; then
    touch "$NOTICE_FILE"
    notify-send -t 15000 -a 'Imperative Dots' -u normal \
        'Upstream archived' \
        'imperative-dots is no longer maintained. It has moved to ilyamiro/serpantinum, which is a separate project and not a drop-in update. Automatic updates are disabled.'
fi

exit 0
