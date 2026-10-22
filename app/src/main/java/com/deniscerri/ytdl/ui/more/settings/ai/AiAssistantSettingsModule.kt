package com.deniscerri.ytdl.ui.more.settings.ai

import androidx.preference.Preference
import com.deniscerri.ytdl.ui.more.settings.SettingHost
import com.deniscerri.ytdl.ui.more.settings.SettingModule

/**
 * The AI assistant page manages its provider list itself ([AiAssistantSettingsFragment]); this
 * module only makes the page searchable. Search results without a click listener open the page.
 */
object AiAssistantSettingsModule : SettingModule {
    override fun bindLogic(pref: Preference, host: SettingHost) {}
}
