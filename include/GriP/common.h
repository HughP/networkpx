/*

common.h ... Common definitions for GriP
 
Copyright (c) 2009, KennyTM~
All rights reserved.
 
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of the KennyTM~ nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/

#ifndef GRIP_COMMON_H
#define GRIP_COMMON_H

enum {
	GriPMessage__Start = 1000,
	GriPMessage_ClickedNotification = GriPMessage__Start,	// 1000
	GriPMessage_IgnoredNotification,	// 1001
	GriPMessage_EnqueueMessage,			// 1002
	GriPMessage_FlushPreferences,		// 1003
	GriPMessage_UpdateTicket,			// 1004
	GriPMessage_LaunchURL,				// 1005
	GriPMessage_CheckEnabled,			// 1006
	GriPMessage_CoalescedNotification,	// 1007
	GriPMessage_DequeueMessages,		// 1008
	GriPMessage_ResolveMultipleMessages,// 1009
	GriPMessage_ShowMessageLog,			// 1010
	GriPMessage__End = 1019,
	
	GPTVAMessage__Start = 1100,
	GPTVAMessage_Show = GPTVAMessage__Start,	// 1100
	GPTVAMessage_Push,					// 1101
	GPTVAMessage_ButtonClicked,			// 1102
	GPTVAMessage_MovedItem,				// 1103
	GPTVAMessage_Deleted,				// 1104
	GPTVAMessage_Selected,				// 1105
	GPTVAMessage_Dismiss,				// 1106
	GPTVAMessage_AccessoryTouched,		// 1107
	GPTVAMessage_DescriptionChanged,	// 1108
	GPTVAMessage_CheckVisible,			// 1109
	GPTVAMessage_UpdateEntry,			// 1110
	GPTVAMessage_UpdateButtons,			// 1111
	GPTVAMessage_Reload,				// 1112
	GPTVAMessage_Pop,					// 1113
	GPTVAMessage_GetCurrentIdentifier,	// 1114
	GPTVAMessage__End = 1119,
};

#if __OBJC__
#define GPSTR(s) @#s
#else
#define GPSTR(s) CFSTR(#s)
#endif

#define GRIP_TITLE    GPSTR(t)
#define GRIP_PID      GPSTR(p)
#define GRIP_DETAIL   GPSTR(d)
#define GRIP_NAME     GPSTR(n)
#define GRIP_ICON     GPSTR(i)
#define GRIP_PRIORITY GPSTR(!)
#define GRIP_STICKY   GPSTR(s)
#define GRIP_CONTEXT  GPSTR(c)
#define GRIP_ID       GPSTR(=)
#define GRIP_APPNAME  GPSTR(a)
#define GRIP_ISURL    GPSTR(u)

#define GRIP_MSGUID   GPSTR(M)
#define GRIP_QUEUEDATE    GPSTR(Q)
#define GRIP_SHOWDATE     GPSTR(D)
#define GRIP_RESOLVEDATE  GPSTR(R)
#define GRIP_STATUS   GPSTR(S)

#define GRIP_PREFDICT GPSTR(/Library/GriP/GPPreferences.plist)

enum {
	GPPrioritySettings_Red,			// 0
	GPPrioritySettings_Green,		// 1
	GPPrioritySettings_Blue,		// 2
	GPPrioritySettings_Alpha,		// 3
	GPPrioritySettings_Enabled,		// 4
	GPPrioritySettings_Sticky,		// 5
	GPPrioritySettings_Timer,		// 6
	GPPrioritySettings_Gaming,		// 7
	GPPrioritySettings_Locked,		// 8
};

#endif