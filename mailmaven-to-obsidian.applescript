# ===========================================================
# MailMaven to Markdown Export 
# Optimized for Obsidian & Layout Preservation
# Version: 1.1
# ===========================================================

-- 1. USER SETTINGS
-- Use HFS format (colons instead of slashes)
-- Example: "Macintosh HD:Users:Username:Documents:Vault:Emails:"
property saveFolder : "Macintosh HD:Users:EXAMPLE_USER:PATH:TO:YOUR:VAULT:"

-- Comma-separated list of tags to be added to YAML Frontmatter
property tagList : "Resources/Email, Work/Inbox"

-- Split replies in the email body by adding a horizontal rule line separator (true or false)
property |sub-divide-replies| : true

# ===========================================================
# MAIN SCRIPT LOGIC
# ===========================================================

tell application "MailMaven"
	activate
	
	if (count of viewers) is 0 then
		display dialog "Please open a MailMaven viewer window first." buttons {"OK"} default button "OK"
		return
	end if
	
	set selectedMessages to selected messages of viewer 1
	if (count of selectedMessages) is 0 then
		display dialog "Please select one or more messages first." buttons {"OK"} default button "OK"
		return
	end if
	
	set currentISOFormattedDate to (do shell script "date '+%Y-%m-%d'")
	
	repeat with eachMessage in selectedMessages
		-- Metadata Extraction
		set msgDate to date received of eachMessage
		set msgSubject to subject of eachMessage
		
		-- Sender Extraction (senders is an element relationship in MailMaven)
		set msgSender to ""
		try
			if (count of senders of eachMessage) > 0 then
				set msgSender to contents of first sender of eachMessage
			end if
		end try
		
		-- Link URL Extraction
		set mavenURL to ""
		try
			set mavenURL to maven url of eachMessage
		end try
		
		set internalID to id of eachMessage
		
		-- Recipient Extraction
		set toRecip to {}
		try
			repeat with r in (recipients of eachMessage)
				set end of toRecip to (address of r)
			end repeat
		end try
		
		set ccRecip to {}
		try
			repeat with r in (cc recipients of eachMessage)
				set end of ccRecip to (address of r)
			end repeat
		end try
		
		-- String Conversion
		set oldDelims to AppleScript's text item delimiters
		set AppleScript's text item delimiters to ", "
		set toStr to toRecip as string
		set ccStr to ccRecip as string
		set AppleScript's text item delimiters to oldDelims
		
		-- Fetch HTML Body (Using dynamic script to avoid compiler errors)
		try
			set rawHTML to my getHTMLByID(internalID)
		on error
			set rawHTML to content of eachMessage
		end try
		
		-- Apply Smart Linkifier (v2.7 "V-Preservation" Logic)
		set processedHTML to my htmlLinkify(rawHTML)
		
		-- Sub-divide replies if enabled
		if |sub-divide-replies| is true or |sub-divide-replies| is "true" then
			set processedHTML to my subDivideReplies(processedHTML)
		end if
		
		-- Date Component Formatting
		set {y, m, d, h, min, s} to my formatDate(msgDate)
		
		set filePrefix to (y & "-" & m & "-" & d & "-" & h & min & s) as string
		set safeSubject to my sanitizeFilename(msgSubject)
		set fileName to filePrefix & "-" & safeSubject & ".md"
		set filePath to (saveFolder & fileName) as string
		
		-- Construct Markdown with YAML Frontmatter
		set markdownContent to "---" & return
		set markdownContent to markdownContent & "title: " & filePrefix & " ~ " & safeSubject & return
		set markdownContent to markdownContent & "aliases: " & return
		set markdownContent to markdownContent & "Tags: " & return
		set AppleScript's text item delimiters to ","
		repeat with t in (text items of tagList)
			set markdownContent to markdownContent & "  - " & my trim(t) & return
		end repeat
		set AppleScript's text item delimiters to oldDelims
		set markdownContent to markdownContent & "description: " & return
		set markdownContent to markdownContent & "publish: false" & return
		set markdownContent to markdownContent & "draft: false" & return
		set markdownContent to markdownContent & "enableToc: false" & return
		set markdownContent to markdownContent & "created: " & y & "-" & m & "-" & d & return
		set markdownContent to markdownContent & "modified: " & currentISOFormattedDate & return
		set markdownContent to markdownContent & "---" & return & return
		-- End of YAML Frontmatter
		
		-- Setting a Banner Graphic for Email
		-- If you have a Graphic that you would like to use just put in the name here
		-- and make sure it is in your obsidian Vault. 
		-- Uncomment the following line if you want to use:
		-- set markdownContent to markdownContent & "![[My_Email_Banner.jpg]]" & return & return
		
		
		-- Start of Subject Line
		set markdownContent to markdownContent & "# Subject: " & msgSubject & return & return
		-- End of Subject Line
		-- Start oF Header Information
		set markdownContent to markdownContent & "## Header" & return
		set markdownContent to markdownContent & "**From:** " & msgSender & return
		set markdownContent to markdownContent & "**Date:** " & (msgDate as string) & return
		set markdownContent to markdownContent & "**To:** " & toStr & return
		if ccStr is not "" then set markdownContent to markdownContent & "**Cc:** " & ccStr & return
		if mavenURL is not "" then
			set markdownContent to markdownContent & "**Mail Link:** [Open in MailMaven](" & mavenURL & ")" & return
		else
			set markdownContent to markdownContent & "**Mail Link:** N/A" & return
		end if
		set markdownContent to markdownContent & "***" & return & return
		-- End of Header 
		
		-- Body with CSS preservation wrapper
		set markdownContent to markdownContent & "## Message Body" & return & return
		set markdownContent to markdownContent & "<div style=\"white-space: pre-wrap; font-family: sans-serif; line-height: 1.5; color: var(--text-normal);\">" & return
		set markdownContent to markdownContent & processedHTML & return
		set markdownContent to markdownContent & "</div>" & return & return
		-- End of Body
		-- Extra Notes Section
		set markdownContent to markdownContent & "***" & return & return
		set markdownContent to markdownContent & "## Notes Information" & return & return
		-- End of Notes Section
		-- Ability to attach files to the Email (Not automatically extracted)
		set markdownContent to markdownContent & "## Documents" & return & return
		-- End of File Attachments
		
		
		-- Save File
		try
			set posixFilePath to POSIX path of filePath
			do shell script "printf %s " & quoted form of markdownContent & " > " & quoted form of posixFilePath
		end try
	end repeat
end tell

# ===========================================================
# HANDLERS
# ===========================================================

on htmlLinkify(theText)
	try
		-- v2.8 Regex: Preserves first characters, avoids existing HTML tags, and excludes email address domains (preceded by @)
		-- Also normalizes Unicode Line/Paragraph Separators (\u2028 and \u2029) to standard newlines
		set perlCmarkdownContent to "perl -pe 's/\\xe2\\x80\\xa8/\\n/g; s/\\xe2\\x80\\xa9/\\n/g; s/(?<![\\/\\\"\\>\\=\\@])\\b([a-zA-Z0-9][a-zA-Z0-9.-]+\\.(com|net|org|io|it|gov|biz|info)[a-z0-9.\\/\\?#%_\\-]*)/<a href=\"http:\\/\\/\\1\">\\1<\\/a>/gi'"
		return do shell script "echo " & quoted form of theText & " | " & perlCmarkdownContent
	on error
		return theText
	end try
end htmlLinkify

on getHTMLByID(mID)
	return run script "tell application \"MailMaven\" to get html body of item 1 of (every message whose id is " & mID & ")"
end getHTMLByID

on sanitizeFilename(str)
	set illegal to {":", "/", "\\", "*", "?", "\"", "<", ">", "|"}
	set out to str
	repeat with c in illegal
		set AppleScript's text item delimiters to c
		set t to text items of out
		set AppleScript's text item delimiters to " - "
		set out to t as string
	end repeat
	repeat while out contains "  "
		set AppleScript's text item delimiters to "  "
		set t to text items of out
		set AppleScript's text item delimiters to " "
		set out to t as string
	end repeat
	set AppleScript's text item delimiters to ""
	return my trim(out)
end sanitizeFilename

on trim(t)
	repeat while t begins with " "
		set t to text 2 thru -1 of t
	end repeat
	repeat while t ends with " "
		set t to text 1 thru -2 of t
	end repeat
	return t
end trim

on formatDate(msgDate)
	set {y, m, d, h, min, s} to {year of msgDate, (month of msgDate as integer), day of msgDate, hours of msgDate, minutes of msgDate, seconds of msgDate}
	if (count of (m as string)) is 1 then set m to "0" & m
	if (count of (d as string)) is 1 then set d to "0" & d
	if (count of (h as string)) is 1 then set h to "0" & h
	if (count of (min as string)) is 1 then set min to "0" & min
	if (count of (s as string)) is 1 then set s to "0" & s
	return {y, m, d, h, min, s}
end formatDate

on subDivideReplies(theText)
	try
		-- Inserts a horizontal rule separator block (25 underscores followed by 2 newlines) before "From:" headers
		set perlCommand to "perl -pe 's/\\bFrom:/\\n_________________________\\n\\nFrom:/g'"
		return do shell script "echo " & quoted form of theText & " | " & perlCommand
	on error
		return theText
	end try
end subDivideReplies
