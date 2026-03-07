import Foundation

final class PermissionManager {

    private let settingsPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/settings.json"
    }()

    private var backupPath: String {
        settingsPath + ".yolo_backup"
    }

    // All MCP tools + standard tools to allow in YOLO mode
    private let yoloAllowRules: [String] = [
        "Bash(*)",
        "Read(*)",
        "Write(*)",
        "Edit(*)",
        "WebFetch(*)",
        "WebSearch(*)",
        "Skill(*)",
        "Agent(*)",
        "TodoWrite(*)",
        "NotebookEdit(*)",
        "Glob(*)",
        "Grep(*)",
        "EnterPlanMode(*)",
        "ExitPlanMode(*)",
        "AskUserQuestion(*)",
        "EnterWorktree(*)",
        // MCP servers - Desktop Commander
        "mcp__Desktop_Commander__get_config",
        "mcp__Desktop_Commander__set_config_value",
        "mcp__Desktop_Commander__read_file",
        "mcp__Desktop_Commander__read_multiple_files",
        "mcp__Desktop_Commander__write_file",
        "mcp__Desktop_Commander__write_pdf",
        "mcp__Desktop_Commander__create_directory",
        "mcp__Desktop_Commander__list_directory",
        "mcp__Desktop_Commander__move_file",
        "mcp__Desktop_Commander__start_search",
        "mcp__Desktop_Commander__get_more_search_results",
        "mcp__Desktop_Commander__stop_search",
        "mcp__Desktop_Commander__list_searches",
        "mcp__Desktop_Commander__get_file_info",
        "mcp__Desktop_Commander__edit_block",
        "mcp__Desktop_Commander__start_process",
        "mcp__Desktop_Commander__read_process_output",
        "mcp__Desktop_Commander__interact_with_process",
        "mcp__Desktop_Commander__force_terminate",
        "mcp__Desktop_Commander__list_sessions",
        "mcp__Desktop_Commander__list_processes",
        "mcp__Desktop_Commander__kill_process",
        "mcp__Desktop_Commander__get_usage_stats",
        "mcp__Desktop_Commander__get_recent_tool_calls",
        "mcp__Desktop_Commander__give_feedback_to_desktop_commander",
        "mcp__Desktop_Commander__get_prompts",
        // desktop-commander (duplicate server)
        "mcp__desktop-commander__get_config",
        "mcp__desktop-commander__set_config_value",
        "mcp__desktop-commander__read_file",
        "mcp__desktop-commander__read_multiple_files",
        "mcp__desktop-commander__write_file",
        "mcp__desktop-commander__write_pdf",
        "mcp__desktop-commander__create_directory",
        "mcp__desktop-commander__list_directory",
        "mcp__desktop-commander__move_file",
        "mcp__desktop-commander__start_search",
        "mcp__desktop-commander__get_more_search_results",
        "mcp__desktop-commander__stop_search",
        "mcp__desktop-commander__list_searches",
        "mcp__desktop-commander__get_file_info",
        "mcp__desktop-commander__edit_block",
        "mcp__desktop-commander__start_process",
        "mcp__desktop-commander__read_process_output",
        "mcp__desktop-commander__interact_with_process",
        "mcp__desktop-commander__force_terminate",
        "mcp__desktop-commander__list_sessions",
        "mcp__desktop-commander__list_processes",
        "mcp__desktop-commander__kill_process",
        "mcp__desktop-commander__get_usage_stats",
        "mcp__desktop-commander__get_recent_tool_calls",
        "mcp__desktop-commander__give_feedback_to_desktop_commander",
        "mcp__desktop-commander__get_prompts",
        // Playwright
        "mcp__playwright__browser_close",
        "mcp__playwright__browser_resize",
        "mcp__playwright__browser_console_messages",
        "mcp__playwright__browser_handle_dialog",
        "mcp__playwright__browser_evaluate",
        "mcp__playwright__browser_file_upload",
        "mcp__playwright__browser_fill_form",
        "mcp__playwright__browser_install",
        "mcp__playwright__browser_press_key",
        "mcp__playwright__browser_type",
        "mcp__playwright__browser_navigate",
        "mcp__playwright__browser_navigate_back",
        "mcp__playwright__browser_network_requests",
        "mcp__playwright__browser_run_code",
        "mcp__playwright__browser_take_screenshot",
        "mcp__playwright__browser_snapshot",
        "mcp__playwright__browser_click",
        "mcp__playwright__browser_drag",
        "mcp__playwright__browser_hover",
        "mcp__playwright__browser_select_option",
        "mcp__playwright__browser_tabs",
        "mcp__playwright__browser_wait_for",
        // Notion MCP
        "mcp__notion-mcp__API-get-user",
        "mcp__notion-mcp__API-get-users",
        "mcp__notion-mcp__API-get-self",
        "mcp__notion-mcp__API-post-search",
        "mcp__notion-mcp__API-get-block-children",
        "mcp__notion-mcp__API-patch-block-children",
        "mcp__notion-mcp__API-retrieve-a-block",
        "mcp__notion-mcp__API-update-a-block",
        "mcp__notion-mcp__API-delete-a-block",
        "mcp__notion-mcp__API-retrieve-a-page",
        "mcp__notion-mcp__API-patch-page",
        "mcp__notion-mcp__API-post-page",
        "mcp__notion-mcp__API-retrieve-a-page-property",
        "mcp__notion-mcp__API-retrieve-a-comment",
        "mcp__notion-mcp__API-create-a-comment",
        "mcp__notion-mcp__API-query-data-source",
        "mcp__notion-mcp__API-retrieve-a-data-source",
        "mcp__notion-mcp__API-update-a-data-source",
        "mcp__notion-mcp__API-create-a-data-source",
        "mcp__notion-mcp__API-list-data-source-templates",
        "mcp__notion-mcp__API-retrieve-a-database",
        "mcp__notion-mcp__API-move-page",
        // Notion enhanced (fe16d9f3)
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-search",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-fetch",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-create-pages",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-update-page",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-create-database",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-update-data-source",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-create-comment",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-get-comments",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-get-users",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-get-teams",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-move-pages",
        "mcp__fe16d9f3-c896-421e-969d-5b9142a7b0bb__notion-duplicate-page",
        // Figma MCP (88927f0b)
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_screenshot",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__create_design_system_rules",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_design_context",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_metadata",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_variable_defs",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_figjam",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__generate_diagram",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_code_connect_map",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__whoami",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__add_code_connect_map",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__get_code_connect_suggestions",
        "mcp__88927f0b-49d0-4606-ba95-5ebacdaed946__send_code_connect_mappings",
        // Google Calendar (a2e4a03b)
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_create_event",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_delete_event",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_find_meeting_times",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_find_my_free_time",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_get_event",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_list_calendars",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_list_events",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_respond_to_event",
        "mcp__a2e4a03b-8418-4c05-9592-b90f59539f4c__gcal_update_event",
        // Claude in Chrome
        "mcp__Claude_in_Chrome__javascript_tool",
        "mcp__Claude_in_Chrome__read_page",
        "mcp__Claude_in_Chrome__find",
        "mcp__Claude_in_Chrome__form_input",
        "mcp__Claude_in_Chrome__computer",
        "mcp__Claude_in_Chrome__navigate",
        "mcp__Claude_in_Chrome__resize_window",
        "mcp__Claude_in_Chrome__gif_creator",
        "mcp__Claude_in_Chrome__upload_image",
        "mcp__Claude_in_Chrome__get_page_text",
        "mcp__Claude_in_Chrome__tabs_context_mcp",
        "mcp__Claude_in_Chrome__tabs_create_mcp",
        "mcp__Claude_in_Chrome__read_console_messages",
        "mcp__Claude_in_Chrome__read_network_requests",
        "mcp__Claude_in_Chrome__shortcuts_list",
        "mcp__Claude_in_Chrome__shortcuts_execute",
        "mcp__Claude_in_Chrome__file_upload",
        "mcp__Claude_in_Chrome__switch_browser",
        // Claude Preview
        "mcp__Claude_Preview__preview_start",
        "mcp__Claude_Preview__preview_stop",
        "mcp__Claude_Preview__preview_list",
        "mcp__Claude_Preview__preview_logs",
        "mcp__Claude_Preview__preview_console_logs",
        "mcp__Claude_Preview__preview_screenshot",
        "mcp__Claude_Preview__preview_snapshot",
        "mcp__Claude_Preview__preview_inspect",
        "mcp__Claude_Preview__preview_click",
        "mcp__Claude_Preview__preview_fill",
        "mcp__Claude_Preview__preview_eval",
        "mcp__Claude_Preview__preview_network",
        "mcp__Claude_Preview__preview_resize",
        // Control Chrome
        "mcp__Control_Chrome__open_url",
        "mcp__Control_Chrome__get_current_tab",
        "mcp__Control_Chrome__list_tabs",
        "mcp__Control_Chrome__close_tab",
        "mcp__Control_Chrome__switch_to_tab",
        "mcp__Control_Chrome__reload_tab",
        "mcp__Control_Chrome__go_back",
        "mcp__Control_Chrome__go_forward",
        "mcp__Control_Chrome__execute_javascript",
        "mcp__Control_Chrome__get_page_content",
        // Control your Mac
        "mcp__Control_your_Mac__osascript",
        // PowerPoint
        "mcp__PowerPoint__By_Anthropic___create_presentation",
        "mcp__PowerPoint__By_Anthropic___open_presentation",
        "mcp__PowerPoint__By_Anthropic___add_slide",
        "mcp__PowerPoint__By_Anthropic___get_slide_content",
        "mcp__PowerPoint__By_Anthropic___set_slide_title",
        "mcp__PowerPoint__By_Anthropic___add_text_to_slide",
        "mcp__PowerPoint__By_Anthropic___insert_image",
        "mcp__PowerPoint__By_Anthropic___delete_slide",
        "mcp__PowerPoint__By_Anthropic___save_presentation",
        "mcp__PowerPoint__By_Anthropic___close_presentation",
        "mcp__PowerPoint__By_Anthropic___export_pdf",
        // Figma (local)
        "mcp__Figma__get_design_context",
        "mcp__Figma__get_screenshot",
        "mcp__Figma__get_metadata",
        "mcp__Figma__get_variable_defs",
        "mcp__Figma__get_code_connect_map",
        "mcp__Figma__add_code_connect_map",
        "mcp__Figma__create_design_system_rules",
        // PDF Tools
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__list_pdfs",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__read_pdf_fields",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__fill_pdf",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__bulk_fill_from_csv",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__save_profile",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__load_profile",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__list_profiles",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__fill_with_profile",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__extract_to_csv",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__validate_pdf",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__read_pdf_content",
        "mcp__PDF_Tools_-_Analyze__Extract__Fill__Compare__get_pdf_resource_uri",
        // Scheduled Tasks
        "mcp__scheduled-tasks__list_scheduled_tasks",
        "mcp__scheduled-tasks__create_scheduled_task",
        "mcp__scheduled-tasks__update_scheduled_task",
        // MCP Registry
        "mcp__mcp-registry__search_mcp_registry",
        "mcp__mcp-registry__suggest_connectors",
    ]

    // MARK: - Inject YOLO Permissions

    func injectYoloPermissions() -> Bool {
        // Backup original
        let fm = FileManager.default
        if fm.fileExists(atPath: settingsPath) && !fm.fileExists(atPath: backupPath) {
            do {
                try fm.copyItem(atPath: settingsPath, toPath: backupPath)
            } catch {
                print("YOLObot: Failed to backup settings: \(error)")
                return false
            }
        }

        // Read current settings
        var settings: [String: Any] = [:]
        if let data = fm.contents(atPath: settingsPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = json
        }

        // Merge allow rules
        var permissions = settings["permissions"] as? [String: Any] ?? [:]
        var currentAllow = permissions["allow"] as? [String] ?? []

        // Add YOLO rules that aren't already present
        for rule in yoloAllowRules {
            if !currentAllow.contains(rule) {
                currentAllow.append(rule)
            }
        }

        permissions["allow"] = currentAllow
        settings["permissions"] = permissions

        // Atomic write
        return atomicWriteJSON(settings, to: settingsPath)
    }

    // MARK: - Restore Original

    func restoreOriginalPermissions() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: backupPath) else {
            print("YOLObot: No backup found, nothing to restore")
            return
        }

        do {
            if fm.fileExists(atPath: settingsPath) {
                try fm.removeItem(atPath: settingsPath)
            }
            try fm.moveItem(atPath: backupPath, toPath: settingsPath)
            print("YOLObot: Settings restored from backup")
        } catch {
            print("YOLObot: Failed to restore settings: \(error)")
        }
    }

    // MARK: - Atomic Write

    private func atomicWriteJSON(_ json: [String: Any], to path: String) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            let tempPath = path + ".tmp_\(ProcessInfo.processInfo.processIdentifier)"
            try data.write(to: URL(fileURLWithPath: tempPath))
            let fm = FileManager.default
            if fm.fileExists(atPath: path) {
                try fm.removeItem(atPath: path)
            }
            try fm.moveItem(atPath: tempPath, toPath: path)
            return true
        } catch {
            print("YOLObot: Failed to write settings: \(error)")
            return false
        }
    }
}
