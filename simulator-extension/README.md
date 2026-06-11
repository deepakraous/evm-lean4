# EVM Simulator Chrome Extension

This Chrome extension provides a secure interactive Ethereum EVM simulator.

## Security practices

- `manifest_version: 3` is used for the latest Chrome extension security model.
- No `permissions` or `host_permissions` are requested.
- The extension does not use `eval`, dynamic code execution, or inline script handlers.
- UI behavior is implemented in a module script (`popup.js`) loaded from a local file.
- CSS is loaded from a separate stylesheet (`styles.css`) and `popup.html` does not contain inline JavaScript.
- No external resources are fetched at runtime.

## Files

- `manifest.json` — extension metadata and permissions
- `popup.html` — secure popup UI
- `popup.js` — simulator logic and command parser
- `styles.css` — UI styling
- `icons/` — extension icons

## Installing locally for testing

1. Open Chrome and navigate to `chrome://extensions`.
2. Enable Developer mode.
3. Click `Load unpacked`.
4. Select the `simulator-extension/` folder.
5. Open the extension from the toolbar.

## Submitting to Chrome Web Store

1. Create a Google developer account and pay the one-time registration fee.
2. Go to the Chrome Web Store Developer Dashboard: https://chrome.google.com/webstore/developer/dashboard
3. Click `Add new item` and upload the zipped `simulator-extension/` directory.
4. Provide a clear title, description, and at least one screenshot.
5. Add a privacy policy if your extension stores or transmits user data. This extension does not.
6. Review the Chrome Web Store policies and make sure your extension does not request unnecessary permissions.
7. Submit the extension for review.

## Notes for publication

- Provide a detailed developer description explaining this is an educational EVM simulator.
- Use the lowest permission set possible. This extension uses none.
- Include a support URL or email in the developer dashboard if required.
- If you update the extension, increment `version` in `manifest.json`.
