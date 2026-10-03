/**
 * AriaNg LuCI Interaction Enhancer
 * Adds:
 * 1. Instant real-time parameter search & filter (AriaNg style)
 * 2. Multi-tab flattener (unfolds nested tabs into single scrollable view)
 * 3. Quick copy for IP/MAC addresses
 * Copyright (C) 2026 gcxixi
 */

(function () {
  'use strict';

  function initAriaNgEnhancer() {
    const mainContent = document.getElementById('maincontent') || document.querySelector('.main-right');
    if (!mainContent) return;

    // Only inject on pages that have configurable parameters (cbi-map, cbi-section, or form)
    const cbiMap = document.querySelector('.cbi-map, form.cbi-map, #cbi-network, .cbi-section');
    if (!cbiMap) return;

    // Prevent double injection
    if (document.getElementById('ariang-filter-toolbar')) return;

    // 1. Build & Insert AriaNg Filter Toolbar
    const toolbar = document.createElement('div');
    toolbar.id = 'ariang-filter-toolbar';
    toolbar.className = 'ariang-filter-toolbar';
    toolbar.innerHTML = `
      <div class="ariang-search-wrap">
        <svg class="ariang-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"></circle>
          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
        <input 
          type="text" 
          id="ariang-param-search" 
          class="ariang-search-input" 
          placeholder="⚡ Quick Filter parameters (e.g. gateway, dns, ip, netmask, nat, bbr, metric)..." 
          autocomplete="off"
        />
      </div>
      <span id="ariang-filter-stats" class="ariang-filter-badge" style="display: none;"></span>
      <button type="button" id="ariang-flatten-btn" class="ariang-btn" title="Expand all nested tabs into a single-page list">
        📜 Flatten Tabs
      </button>
    `;

    // Insert before the first map/section
    cbiMap.parentNode.insertBefore(toolbar, cbiMap);

    const searchInput = document.getElementById('ariang-param-search');
    const statsBadge = document.getElementById('ariang-filter-stats');
    const flattenBtn = document.getElementById('ariang-flatten-btn');

    // 2. Real-time Parameter Filter Logic
    searchInput.addEventListener('input', function (e) {
      const query = (e.target.value || '').trim().toLowerCase();
      const allRows = document.querySelectorAll('.cbi-value');
      
      if (!query) {
        // Reset all rows
        allRows.forEach(row => {
          row.style.display = '';
        });
        statsBadge.style.display = 'none';
        return;
      }

      let matchCount = 0;
      allRows.forEach(row => {
        const titleText = (row.querySelector('.cbi-value-title')?.textContent || '').toLowerCase();
        const descText = (row.querySelector('.cbi-value-description')?.textContent || '').toLowerCase();
        const fieldText = (row.querySelector('.cbi-value-field')?.textContent || '').toLowerCase();
        const inputVal = (row.querySelector('input, select')?.value || '').toLowerCase();
        const nameAttr = (row.querySelector('[name]')?.getAttribute('name') || '').toLowerCase();

        const isMatch = titleText.includes(query) || 
                        descText.includes(query) || 
                        fieldText.includes(query) || 
                        inputVal.includes(query) ||
                        nameAttr.includes(query);

        if (isMatch) {
          row.style.display = '';
          matchCount++;

          // If this row is inside a tabcontainer, unhide its parent tab so user sees it
          const parentTab = row.closest('.cbi-tabcontainer');
          if (parentTab) {
            parentTab.style.display = 'block';
            // Also highlight active tab in tabmenu if exists
            const tabId = parentTab.id || parentTab.getAttribute('data-tab');
            if (tabId) {
              const tabLink = document.querySelector(`.cbi-tabmenu a[href="#${tabId}"], .cbi-tabmenu [data-tab="${tabId}"]`);
              if (tabLink) {
                tabLink.closest('li')?.classList.add('cbi-tab');
              }
            }
          }
        } else {
          row.style.display = 'none';
        }
      });

      statsBadge.style.display = 'inline-block';
      statsBadge.textContent = `${matchCount} / ${allRows.length} matches`;
    });

    // Keyboard shortcut (Cmd+K or Ctrl+K) to focus search
    window.addEventListener('keydown', function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
    });

    // 3. Tab Flattener Toggle
    let isFlattened = false;
    flattenBtn.addEventListener('click', function () {
      isFlattened = !isFlattened;
      const containers = document.querySelectorAll('.cbi-tabcontainer');
      const tabMenus = document.querySelectorAll('.cbi-tabmenu');

      if (isFlattened) {
        document.body.classList.add('ariang-flattened');
        containers.forEach(container => {
          // Read tab title
          const tabId = container.id || container.getAttribute('data-tab');
          let tabTitle = container.getAttribute('data-tab-title');
          if (!tabTitle && tabId) {
            const link = document.querySelector(`.cbi-tabmenu a[href="#${tabId}"], .cbi-tabmenu [data-tab="${tabId}"]`);
            if (link) tabTitle = link.textContent.trim();
          }
          if (tabTitle) {
            container.setAttribute('data-tab-title', `▶ Tab: ${tabTitle}`);
          }
          container.style.display = 'block';
        });
        tabMenus.forEach(menu => menu.style.display = 'none');
        flattenBtn.innerHTML = '📑 Tab Mode';
        flattenBtn.classList.add('ariang-btn-primary');
      } else {
        document.body.classList.remove('ariang-flattened');
        tabMenus.forEach(menu => menu.style.display = '');
        containers.forEach((container, idx) => {
          container.style.display = (idx === 0) ? 'block' : 'none';
        });
        flattenBtn.innerHTML = '📜 Flatten Tabs';
        flattenBtn.classList.remove('ariang-btn-primary');
      }
    });

    // 4. One-click Copy for IP/MAC values
    const ipRegex = /\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/;
    const macRegex = /\b([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})\b/;

    document.querySelectorAll('.cbi-value-field, td').forEach(el => {
      const text = el.innerText || '';
      if ((ipRegex.test(text) || macRegex.test(text)) && !el.querySelector('input') && !el.querySelector('.ariang-copy-btn')) {
        const copyBtn = document.createElement('span');
        copyBtn.className = 'ariang-copy-btn';
        copyBtn.innerHTML = '📋';
        copyBtn.title = 'Copy to clipboard';
        copyBtn.style.cssText = 'cursor:pointer; margin-left:6px; font-size:11px; opacity:0.6;';
        copyBtn.addEventListener('click', function (e) {
          e.stopPropagation();
          const match = text.match(ipRegex) || text.match(macRegex);
          if (match) {
            navigator.clipboard.writeText(match[0]);
            copyBtn.innerHTML = '✓';
            setTimeout(() => copyBtn.innerHTML = '📋', 1500);
          }
        });
        el.appendChild(copyBtn);
      }
    });
  }

  // Hook into DOM ready and LuCI xhr updates
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAriaNgEnhancer);
  } else {
    initAriaNgEnhancer();
  }

  // LuCI JS dynamically re-renders parts of page via XHR
  const observer = new MutationObserver(function (mutations) {
    for (let mutation of mutations) {
      if (mutation.addedNodes.length > 0) {
        initAriaNgEnhancer();
        break;
      }
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });
})();
