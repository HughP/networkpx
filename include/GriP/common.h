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
	GriPMessage_ClickedNotification = GriPMessage__Start,
	GriPMessage_IgnoredNotification,
	GriPMessage_EnqueueMessage,
	GriPMessage_FlushPreferences,
	GriPMessage_UpdateTicket,
	GriPMessage_LaunchURL,
	GriPMessage_CheckEnabled,
	GriPMessage_CoalescedNotification,
	GriPMessage_DequeueMessages,
	GriPMessage__End = 1009,
	
	GPTVAMessage__Start = 1100,
	GPTVAMessage_Show = GPTVAMessage__Start,
	GPTVAMessage_Push,
	GPTVAMessage_ButtonClicked,
	GPTVAMessage_MovedItem,
	GPTVAMessage_Deleted,
	GPTVAMessage_Selected,
	GPTVAMessage_Dismiss,
	GPTVAMessage_AccessoryTouched,
	GPTVAMessage_DescriptionChanged,
	GPTVAMessage_CheckVisible,
	GPTVAMessage_UpdateEntry,
	GPTVAMessage_UpdateButtons,
	GPTVAMessage_Reload,
	GPTVAMessage_Pop,
	GPTVAMessage_GetCurrentIdentifier,
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

#define GRIP_PREFDICT GPSTR(/Library/GriP/GPPreferences.plist)

enum {
	GPPrioritySettings_Red,
	GPPrioritySettings_Green,
	GPPrioritySettings_Blue,
	GPPrioritySettings_Alpha,
	GPPrioritySettings_Enabled,
	GPPrioritySettings_Sticky,
	GPPrioritySettings_Timer,
	GPPrioritySettings_Gaming,
	GPPrioritySettings_Locked,
};

#endif