# Version History & Function Dictionary

## Current Version: 1.6

### Date Released: 2026-07-20

Below is a dictionary of all custom handlers (functions) implemented in the `mailmaven-to-obsidian.applescript` script:

#### 1. Active Session Verification
- **Functionality:**
    - Automatically checks that MailMaven is running and at least one message viewer window is open before executing, preventing silent failures or script timeouts.
 
#### 2. Batch Processing of Selections
**- Functionality:**
    - Retrieves all currently selected email messages in the front MailMaven viewer and iterates over them to perform bulk exports.

#### 3. Structured Metadata Extraction
**- Functionality:**
    - Extracts the original date received, subject, and the sender's full RFC2822 address comment.
    - Extracts and formats all `To` and `Cc` recipients into comma-separated lists.
    - Extracts the native `maven-message://` URL for deep-linking.

#### 4. Resilient Body Recovery 
**- Functionality:**
    - Attempts to dynamically read the rich HTML body of the message. If the HTML dictionary query fails, it gracefully falls back to retrieving the plain text `content` of the message.

#### 5. Obsidian Frontmatter Generation 
**- Functionality:**
    - Creates a standardized YAML metadata block at the top of each note, configuring properties like title, aliases, tags (nested tags supported), publishing status, creation date, and last modified date.

#### 6. Layout-Preserved HTML Wrapper 
**- Functionality:**
    - Wraps the processed message body inside a custom CSS-styled `div` wrapper (`white-space: pre-wrap; font-family: sans-serif; line-height: 1.5; color: var(--text-normal);`). This ensures fonts, spacing, and formatting match the original email view inside Obsidian's dark/light modes.

#### 7. Obsidian Vault File Writing
**- Functionality:**
    - Converts the HFS folder path to a POSIX path and uses the macOS shell `printf` utility to output the Markdown file. This ensures the output is saved in native UTF-8 format, preventing carriage return/linefeed corruption and encoding mismatch bugs.

#### 8. Sanitizes and enhances links in the email body.
- **Functionality:** 
  - Automatically identifies "naked" URLs (such as `google.com`) and turns them into clickable HTML links.
  - Excludes domains that are part of email addresses (preceded by `@`) to prevent breaking mail headers.
  - Normalizes Unicode Line Separators (`\u2028`) and Paragraph Separators (`\u2029`) into standard newlines (`\n`) for layout preservation.

#### 9. Dynamically fetches HTML content for a message
- **Functionality:**
    - Queries MailMaven dynamically at runtime to retrieve the HTML body corresponding to the message ID. Using dynamic execution avoids strict compile-time errors in case of application dictionary discrepancies.

#### 10. Normalizes email subjects for safe macOS and Obsidian filenames.
- **Functionality:**
    - Replaces all illegal path and filename characters (such as colons `:`, slashes `/`, etc.) with `" - "` (space-dash-space). It also collapses double spaces and trims the final string to ensure neat filenames.

#### 11. String whitespace utility.
- **Functionality:**
    - Trims any leading and trailing spaces from a given string.

####  12. Custom date padder and formatting utility.
- **Functionality:**
    - Normalizes the message's `date received` property into a 24-hour timestamp string (`YYYY-MM-DD-HHMMSS`). This logic is contained outside the MailMaven `tell` block to bypass terminology collisions with MailMaven's custom `year` definition.

#### 13. Visually separates nested replies in email threads.
- **Functionality:**
    - Pre-processes the message body by inserting a separator line of 25 underscores followed by two line breaks (`_________________________` + `\n\n`) before any `From:` headers in the email thread (active when the `sub-divide-replies` user setting is enabled).







7. **

