// Background Service Worker for Cleansed Extension

console.log("Cleansed background service worker running.");

// Initialize default state on install
chrome.runtime.onInstalled.addListener(async () => {
  console.log("Extension installed or updated.");
  
  // Set initial storage values
  await chrome.storage.local.set({
    focusModeTargetEnd: null,
    isFocusModeActive: false,
    adBlockerEnabled: false
  });
});

// Listener for messages from popup
chrome.runtime.onMessage.addListener((request, _sender, sendResponse) => {
  if (request.type === 'START_FOCUS_SESSION') {
    console.log("Starting focus session from background...");
    handleFocusSessionStart(request.payload.domains || [], request.payload.durationMinutes || 25);
    sendResponse({ status: 'started' });
  } else if (request.type === 'TOGGLE_AD_BLOCKER') {
    toggleAdBlocker(request.payload.enabled);
    sendResponse({ status: 'toggled' });
  }
  return true;
});

async function toggleAdBlocker(enabled: boolean) {
  try {
    await chrome.storage.local.set({ adBlockerEnabled: enabled });
    await chrome.declarativeNetRequest.updateStaticRules({
      rulesetId: 'ad_blocker_rules',
      disableRuleIds: enabled ? [] : [1, 2, 3],
      enableRuleIds: enabled ? [1, 2, 3] : []
    });
    console.log("Ad blocker enabled:", enabled);
  } catch (error) {
    console.error("Failed to toggle ad blocker rules:", error);
  }
}

async function handleFocusSessionStart(domainsToBlock: string[], durationMinutes: number) {
  try {
    // Calculate end time
    const targetEnd = Date.now() + durationMinutes * 60 * 1000;
    await chrome.storage.local.set({
      focusModeTargetEnd: targetEnd,
      isFocusModeActive: true
    });

    // Create dynamic rules to block requested domains
    const dynamicRules = domainsToBlock.map((domain, index) => ({
      id: 1000 + index, // Dynamic rule IDs start at 1000 to avoid static rule collision
      priority: 2,
      action: { type: chrome.declarativeNetRequest.RuleActionType.BLOCK },
      condition: {
        urlFilter: `*://${domain}/*`,
        resourceTypes: [chrome.declarativeNetRequest.ResourceType.MAIN_FRAME]
      }
    }));

    // Apply the rules, removing any existing dynamic focus rules first
    const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
    const existingRuleIds = existingRules.map(rule => rule.id);

    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: existingRuleIds,
      addRules: dynamicRules
    });

    console.log("Focus session started blocking:", domainsToBlock);

    // Set an alarm to end the focus session
    chrome.alarms.create('endFocusSession', { delayInMinutes: durationMinutes });

  } catch (error) {
    console.error("Failed to start focus session:", error);
  }
}

// Listen for focus session alarm completion
chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'endFocusSession') {
    console.log("Focus session ended");
    await chrome.storage.local.set({
      focusModeTargetEnd: null,
      isFocusModeActive: false
    });

    // Clear dynamic blocking rules
    const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
    const existingRuleIds = existingRules.map(rule => rule.id);
    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: existingRuleIds
    });

    // Trigger notification
    chrome.notifications.create({
      type: 'basic',
      iconUrl: 'icon.png', // Fallback, we'll need an icon
      title: 'Focus Session Complete',
      message: 'Great job! Your focus session has successfully finished.'
    });
  }
});

