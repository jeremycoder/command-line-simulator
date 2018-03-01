;=====
;Program Name: G2P3.ASM
;Program Number: 2
;Group Number: 2
;Group Member Names:
;	BL
;	Jeremy Mwangelwa
;====


INCLUDE C:\Irvine\Irvine32.inc		;Must include these INCLUDE directives
;INCLUDELIB C:\Irvine\Irvine32.lib		;to access Irvine32 library subroutines

.386						;32 bits
;.MODEL flat, stdcall		;
.STACK 4096					;stack size is 4096

ExitProcess PROTO,dwExitCode:DWORD 

;=====DATA BEGINS HERE==========

;JOB RECORD STRUCTURE
;job status, 1 byte, "A", "H" or "R"
;job priority, 1 byte, "0 through 7"
;job name, 8 bytes, Any non-space, non-tab, characters
;job run time, 2 bytes, "1 through 50"
;job start time, 4 bytes, Depends on system time at start of job
;Total Job Record Size is 16 bytes

.DATA
;===Job Queue Constants
SIZE_OF_RECORD EQU 16
NUMBER_OF_RECORDS EQU 10

;===Introductory text
intro_text0 BYTE "Welcome to Program 3",10,0
options_text BYTE 10,"[QUIT][HELP][LOAD][RUN][HOLD][KILL][SHOW][STEP][CHANGE]",10,0
test_text BYTE "aBcDeFgHiJkLmNoPqRsTuVwXyZ123",10,10,10,0

;===Buffer for user input, before string parsing
buffer_size EQU 60
buffer BYTE buffer_size DUP(0)

;===Command Prompt variables
command_prompt_text BYTE 10,"Please enter a command > ",0				;general command prompt
command_found BYTE "COMMAND FOUND!",10,0								;used for testing before procedures are written
invalid_command BYTE " is not a valid command. Type [HELP] for command instructions.",10,0

;===User Commands
quit_command BYTE "QUIT",0
help_command BYTE "HELP",0
show_command BYTE "SHOW",0
run_command BYTE "RUN",0
hold_command BYTE "HOLD",0
kill_command BYTE "KILL",0
step_command BYTE "STEP",0
change_command BYTE "CHANGE",0
load_command BYTE "LOAD",0

;===Help Instructions
help1 BYTE 10,"[QUIT]	Terminates the program.",0
help2 BYTE 10,"[HELP]	Displays these instructions.",0
help3 BYTE 10,"[SHOW]	Displays the job queue.",0
help4 BYTE 10,"[RUN]	Changes the mode of a job from HOLD to RUN. A job must exist in the queue to",0
help5 BYTE 10,"	be placed in RUN mode. You must enter a job name: [RUN] [job name].",0
help6 BYTE 10,"[HOLD]	Changes the mode of a job from RUN to HOLD. A job must exist in the queue to",0
help7 BYTE 10,"	be placed in HOLD mode. You must enter a job name: [HOLD] [job name].",0
help8 BYTE 10,"[KILL]	Removes a job from the job queue. The job must be in the queue and must be in",0
help9 BYTE 10,"	HOLD mode. You must enter a job name: [KILL] [job name].",0
help10 BYTE 10,"[STEP]	Steps through job processing a specific number of times. Enter a number to process",0
help11 BYTE 10,"	that number of times. [STEP] [5] takes 5 steps. [STEP] takes one step.",0
help12 BYTE 10,"[CHANGE] Changes the priority of a job. The job must exist in the job queue. You must",0
help13 BYTE 10,"	enter the job name and priority: [CHANGE] [job name] [priority].",0
help14 BYTE 10,"[LOAD]	Loads a new job into the job queue. The job must not exist in the job queue. You",0
help15 BYTE 10,"	must enter the job name, priority, and run time: [LOAD] [job name] [priority] [run time].",0
help16 BYTE 10,0
help17 BYTE 10,"LIMITS:",0
help18 BYTE 10,"Job name is limited to 8 characters.",0
help19 BYTE 10,"Priority must be a number from 0 through 7.",0
help20 BYTE 10,"Run time must be a number from 1 through 50.",0

;===Quit text
quit_text BYTE 10,"Quitting Program",10,0

;===String parsing variables
a_word BYTE 10 DUP (0),0			;holds one parameter entries
first_word BYTE 60 DUP (0),0		;first word of four from command line
second_word BYTE 60 DUP (0),0		;second word of four from command line
third_word BYTE 60 DUP (0),0		;third word of four from command line
fourth_word BYTE 60 DUP (0),0		;fourth word of four from command line
char_count BYTE 0
num_of_words DWORD 0				;shows number of words in user-entered string
string_length BYTE 0				;store count of user input after ReadString

;===ERRORS
job_name_too_long BYTE 10,"	ERROR, job name too long. Only 8 characters allowed. Try again.",10,0
job_name_too_short BYTE 10,"	ERROR, job name too short. Enter at least one character. Try again.",10,0
step_too_small BYTE 10,"	ERROR, invalid step size. Enter only [STEP] to take one step.",10,0
step_too_big BYTE 10,"	ERROR, step size is too big. Maximum is 127.",10,0
priority_too_small BYTE 10,"	ERROR, invalid priority value. Enter 0 for highest priority.",10,0
priority_too_big BYTE 10,"	ERROR, priority value too large. Maximum is 7.",10,0
run_time_too_small BYTE 10,"	ERROR, invalid run time value. Enter 1 for smallest value.",10,0
run_time_too_big BYTE 10,"	ERROR, run time value too large. Maximum is 50.",10,0
same_job_name BYTE 10,"	ERROR: Job name already exists in queue. Cannot load job.",10,0
queue_is_full BYTE 10,"	ERROR: Queue is full. Cannot load job.",10,0
no_such_job_name BYTE 10,"	ERROR: That job name is not in the queue.",10,0
job_already_running BYTE 10,"	ERROR: That job is already running. Job will continue to run.",10,0
job_already_holding BYTE 10,"	ERROR: That job is already in hold mode. ",10,0
cannot_kill_job BYTE 10,"	ERROR: Cannot kill a job in run mode. Job must be in hold mode.",10,0


;===Job entry strings and variables
job_name BYTE 60 DUP(0),0
enter_job_name BYTE 10,"	Please enter a job name: ",0
enter_priority BYTE 10,"	Please enter priority: ",0
enter_run_time BYTE 10,"	Please enter run time: ",0
run_accepted BYTE 10,"	[RUN] Accepted. ",0
hold_accepted BYTE 10,"	[HOLD] Accepted. ",0
kill_accepted BYTE 10,"	[KILL] Accepted. ",0
step_accepted BYTE 10,"	[STEP] Accepted.",0
load_accepted BYTE 10,"	[LOAD] Accepted.",0
change_accepted BYTE 10,"	[CHANGE] Accepted.",0
job_running BYTE 10,"	Job running.",0
job_holding BYTE 10,"	Job now in hold mode.",0
job_killed BYTE 10,"	Job killed.",0
load_successful BYTE 10,"	Job load successful.",10,0
job_priority_changed BYTE 10,"	Job priority changed.",0
further_processing BYTE 10,"[FURTHER PROCESSING TAKES PLACE HERE]",10,0
step_taken BYTE 10,"	Step taken.",10,0
show_sys_time BYTE 10,"	System time: ",0
n BYTE 1								;stores number of steps
priority DWORD 0						;stores job priority
run_time DWORD 0						;stores run_time
system_time DWORD 1						;time in steps kept by the program

;===Job queue manipulation variables
slot SDWORD -1							;stores job queue slot number
slot_size DWORD 0						;stores the product of slot * SIZE_OF_RECORD
JOB_STATUS_POS EQU 0					;job status byte position
JOB_PRIORITY_POS EQU 1					;job priority byte position
JOB_NAME_POS EQU 2						;job name byte beginning position
JOB_RUN_TIME_POS EQU 10					;job run time byte position
JOB_START_TIME_POS EQU 12				;job load time byte position
job_hold_byte BYTE "H",0				;Contains byte symbol for hold
job_run_byte BYTE "R",0					;Contains byte symbol for run
job_avail_byte BYTE "A",0
queue_total_bytes DWORD 0				;holds total number of bytes in queue

;===Show command variables
show_buffer BYTE 10 DUP(0)								;used to temporarily hold data about to be shown to screen
some_space BYTE "	",0									;holds a tab space
show_title BYTE "			JOBS",0						;display title for show procedure
show_subtitles BYTE "Status	Priority	Name		Run Time	Start Time",0

this_is_working BYTE 10,"This is working!",10,0			;testing string

small_buffer BYTE 10 DUP(0)								;a small buffer used for moving data out of the queue

;===Job queue
queue BYTE SIZE_OF_RECORD*NUMBER_OF_RECORDS DUP(0)		;The queue, 160 bytes long
end_of_jobs BYTE 0										;A variable to hold the end of the queue


next_availible_address	DWORD  (OFFSET queue)
temp_record BYTE (SIZE_OF_RECORD+1) DUP(0)	
job_finished_text1 BYTE "Job ",34,0
job_finished_text2 BYTE 34," has finished at: ",0
system_time_text BYTE "System time is: ",0

temp_name BYTE 9 DUP(0), 0


;==========CODE BEGINS HERE===========================================

.CODE

main PROC
CALL Prep_p												;prepare queue with "A" in the job status byte positions
MOV EDX, OFFSET options_text						    ;show user command options
CALL WriteString

COMMAND_PROMPT:											;request command loop	
	
	CALL Flush_everything_p								;resets all variables that are reused
	mov EDX, OFFSET command_prompt_text					;display command prompt
	call WriteString

	mov EDX, OFFSET buffer								;read user entry
	mov ECX, SIZEOF buffer
	call ReadString

	call GetFourWords_p										;gets up to four words from command line
	INVOKE Str_ucase, ADDR first_word						;make word uppercase

	INVOKE Str_compare, ADDR first_word, ADDR quit_command	;compare user entry with "QUIT"
	.IF ZERO?											;quit if user entered quit
		JMP quit_program
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR help_command	;compare user entry with "HELP"
	.IF ZERO?											;go to help if user entered help
		JMP HELP_LABEL
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR show_command	;compare user entry with "SHOW"
	.IF ZERO?
		jmp show_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR run_command	;compare user entry with "RUN"
	.IF ZERO?
		jmp run_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR hold_command	;compare user entry with "HOLD"
	.IF ZERO?
		jmp hold_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR kill_command	;compare user entry with "KILL"
	.IF ZERO?
		jmp kill_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR step_command	;compare user entry with "STEP"
	.IF ZERO?
		jmp step_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR change_command	;compare user entry with "CHANGE"
	.IF ZERO?
		jmp change_label
	.ENDIF

	INVOKE Str_compare, ADDR first_word, ADDR load_command	;compare user entry with "LOAD"
	.IF ZERO?
		jmp load_label
	.ENDIF


	MOV EDX, OFFSET first_word
	CALL WriteString
	MOV EDX, OFFSET invalid_command						;if no valid command entered, tell user
	CALL WriteString

	CALL Flush_everything_p									;flush a_word so it can be used again
	JMP COMMAND_PROMPT									;return to command prompt

	HELP_LABEL:
		CALL Help_p
		JMP COMMAND_PROMPT

	show_label:
		CALL Show_p
		JMP COMMAND_PROMPT

	run_label:
		CALL Run_p
		JMP COMMAND_PROMPT

	hold_label:
		CALL Hold_p
		JMP COMMAND_PROMPT

	kill_label:
		CALL Kill_p
		JMP COMMAND_PROMPT

	step_label:
		CALL Step_p
		JMP COMMAND_PROMPT

	change_label:
		CALL Change_p
		JMP COMMAND_PROMPT

	load_label:
		CALL Load_p
		JMP COMMAND_PROMPT

				
	quit_program:
	MOV edx, OFFSET quit_text   ;display operations
	call WriteString

	INVOKE ExitProcess,0
main ENDP

;=====MAIN PROC ENDS HERE. OTHER PROCS START HERE===========================================

;Assume start address of string is in ESI, length of string is in EDI
;
ToUpper_p PROC USES EAX EBX ECX
	MOV ECX, ESI	;
	ADD ESI, EDI	;

loop1:
	MOV AL, 0[ECX]
	CMP AL, 0			;Check for null termination
	je done
	CMP AL, 61h
	JGE other_bound
	JMP increment
other_bound:
	CMP AL, 7Ah
	JLE convert
	JMP increment
convert:
	MOV EBX, 0[ECX]
	SUB EBX, 20h
	MOV 0[ECX], EBX

increment:
	INC ECX
	CMP ECX, ESI		;checks if index out of bounds
	JG done
	JMP loop1
done:
	ret
ToUpper_p ENDP
;=============================================
;Gets first word of a string from a variable called buffer, ignores spaces and tabs. Buffer must be
;at least 60 bytes in length. Each word can be up to 60 characters. Places the word in variables a_word.

GetWord_p PROC USES ECX EDI ESI
	
	mov EDI, OFFSET buffer								;point EDI to beginning of buffer
	mov ESI, 0											;start ESI and 0
	mov ECX, 0											;use for counting

	mov string_length, AL								;store string length

	cmp string_length, 0				
	JE done
	
	;===Get the first word==========================

	get_first_word_loop:

		mov BL, BYTE PTR [EDI+ESI]							;move one char to BL

		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_1

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_1

		cmp BL, 0h											;if end of line, quit
		JE done

		mov a_word[ECX], BL								;move one char into first_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_1_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_1_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_1_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_1_found
		
	skip_tab_space_1:
		inc ESI
		jmp get_first_word_loop

	word_1_found:
		;mov EDX, OFFSET first_word							;show first word, can uncomment these two lines
		;call WriteString
		;call Crlf
		
	done:
		ret

GetWord_p ENDP
;======================================================================================================
;Gets the first four words of a string from a variable called buffer, ignores spaces and tabs. Buffer must be
;at least 60 bytes in length. Each word can be up to 60 characters. Places the words in variables first_word,
;second_word, thrid_word, and fourth_word respectively. Stores number of words in a variable called num_of_words.

GetFourWords_p PROC USES ECX EDI ESI
	
	mov EDI, OFFSET buffer								;point EDI to beginning of buffer
	mov ESI, 0											;start ESI and 0
	mov ECX, 0											;use for counting

	mov string_length, AL								;store string length

	cmp string_length, 0				
	JE done
	
	;===Get the first word==========================

	get_word_1_loop:

		mov BL, BYTE PTR [EDI+ESI]							;move one char to BL

		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_1

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_1

		cmp BL, 0h											;if end of line, quit
		JE done

		mov first_word[ECX], BL								;move one char into first_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_1_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_1_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_1_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_1_found
		
	skip_tab_space_1:
		inc ESI
		jmp get_word_1_loop

	word_1_found:
	inc num_of_words										;count number of words
		;mov EDX, OFFSET first_word							;uncomment these lines to see first word
		;call WriteString
		;call Crlf
		
	;=====bridge to word 2
		mov ECX, 0
		mov char_count, 0
		inc ESI										
		
	get_word_2_loop:		
				
		mov BL, BYTE PTR [EDI+ESI]		
		
		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_2

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_2

		cmp BL, 0h											;if end of line, quit
		JE done

		mov second_word[ECX], BL								;move one char into first_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_2_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_2_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_2_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_2_found
		
	skip_tab_space_2:
		inc ESI
		jmp get_word_2_loop

	word_2_found:
	inc num_of_words										;count number of words
		;mov EDX, OFFSET second_word						;uncomment these lines to see second word
		;call WriteString
		;call Crlf
	
	;=====bridge to word 3
		mov ECX, 0
		mov char_count, 0
		inc ESI										
		
	get_word_3_loop:		
				
		mov BL, BYTE PTR [EDI+ESI]		
		
		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_3

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_3

		cmp BL, 0h											;if end of line, quit
		JE done

		mov third_word[ECX], BL								;move one char into first_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_3_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_3_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_3_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_3_found
		
	skip_tab_space_3:
		inc ESI
		jmp get_word_3_loop

	word_3_found:
	inc num_of_words										;count number of words
		;mov EDX, OFFSET third_word							; uncomment these lines to see third word
		;call WriteString
		;call Crlf
		
	;=====bridge to word 4
		mov ECX, 0
		mov char_count, 0
		inc ESI										
		
	get_word_4_loop:		
				
		mov BL, BYTE PTR [EDI+ESI]		
		
		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_4

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_4

		cmp BL, 0h											;if end of line, quit
		JE done

		mov fourth_word[ECX], BL								;move one char into first_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_4_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_4_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_4_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_4_found
		
	skip_tab_space_4:
		inc ESI
		jmp get_word_4_loop

	word_4_found:
		inc num_of_words										;count number of words
		;mov EDX, OFFSET fourth_word							;uncomment these lines to see fourth word
		;call WriteString
		;call Crlf		
		
	done:
		ret

GetFourWords_p ENDP
;========================================
;FLUSH_EVERYTHING_P
;Flushes (resets) all variables and arrays that are used again and again
Flush_everything_p PROC USES ECX EAX
	
	;===Reset variables used again and again
	MOV num_of_words, 0								;Reset num_of_words
	MOV n, 1										;Reset number of steps
	MOV slot, -1									;Reset slot to -1, its original value
		
	;===Flush priority
	
	
	;===Flush first_word
	INVOKE Str_length, ADDR first_word				;get first_word string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET first_word							;point EDI to beginning of a_word
	L1:
		MOV first_word[ECX], 0							;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_2
		
		JMP L1
	
	;===Flush second_word
	step_2:
	INVOKE Str_length, ADDR second_word				;get second_word string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET second_word						;point EDI to beginning of a_word
	L2:
		MOV second_word[ECX], 0						;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_3
		
		JMP L2
	
	;===Flush third_word
	step_3:
	INVOKE Str_length, ADDR third_word				;get third_word string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET third_word							;point EDI to beginning of a_word
	L3:
		MOV third_word[ECX], 0							;move null char into third_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_4
		
		JMP L3
	
	;===Flush fourth_word
	step_4:
	INVOKE Str_length, ADDR fourth_word				;get fourth_word string length, place in EAX
	MOV ECX, 0										;counter for fourth_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET fourth_word						;point EDI to beginning of fourth_word
	L4:
		MOV fourth_word[ECX], 0						;move null char into fourth_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_5
		
		JMP L4
	
	;===Flush job_name
	step_5:
	INVOKE Str_length, ADDR job_name				;get job_name string length, place in EAX
	MOV ECX, 0										;counter for job_name
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET job_name						;point EDI to beginning of job_name
	L5:
		MOV job_name[ECX], 0						;move null char into job_name
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_6
		
		JMP L5
	
	;===Flush buffer
	step_6:
	INVOKE Str_length, ADDR buffer					;get buffer string length, place in EAX
	MOV ECX, 0										;counter for buffer
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET buffer							;point EDI to beginning of buffer
	L6:
		MOV buffer[ECX], 0							;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_7
		
		JMP L6
	
	step_7:
	;===Flush priority
	INVOKE Str_length, ADDR priority				;get priority string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET priority							;point EDI to beginning of a_word
	L7:
		MOV priority[ECX], 0							;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_8
		
		JMP L7
	
	step_8:
	;===Flush run_time
	INVOKE Str_length, ADDR run_time				;get run_time string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET run_time						;point EDI to beginning of a_word
	L8:
		MOV run_time[ECX], 0						;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_9
		
		JMP L8
	
	step_9:
	;===Flush small_buffer
	INVOKE Str_length, ADDR small_buffer				;get run_time string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET small_buffer						;point EDI to beginning of a_word
	L9:
		MOV small_buffer[ECX], 0						;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE step_10
		
		JMP L9
	
	step_10:
	;===Flush small_buffer
	INVOKE Str_length, ADDR a_word					;get run_time string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET a_word							;point EDI to beginning of a_word
	L10:
		MOV a_word[ECX], 0							;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE done
		
		JMP L10		
		
	done:
		ret

Flush_everything_p ENDP
;=====================================
;HELP_P
;Displays help instructions.
Help_p PROC
	
	MOV EDX, OFFSET help1
	call WriteString
	
	MOV EDX, OFFSET help2
	call WriteString
	
	MOV EDX, OFFSET help3
	call WriteString
	
	MOV EDX, OFFSET help4
	call WriteString
	
	MOV EDX, OFFSET help5
	call WriteString
	
	MOV EDX, OFFSET help6
	call WriteString
	
	MOV EDX, OFFSET help7
	call WriteString
	
	MOV EDX, OFFSET help8
	call WriteString
	
	MOV EDX, OFFSET help9
	call WriteString
	
	MOV EDX, OFFSET help10
	call WriteString
	
	MOV EDX, OFFSET help11
	call WriteString
	
	MOV EDX, OFFSET help12
	call WriteString
	
	MOV EDX, OFFSET help13
	call WriteString
	
	MOV EDX, OFFSET help14
	call WriteString
	
	MOV EDX, OFFSET help15
	call WriteString
	
	MOV EDX, OFFSET help16
	call WriteString
	
	MOV EDX, OFFSET help17
	call WriteString
	
	MOV EDX, OFFSET help18
	call WriteString
	
	MOV EDX, OFFSET help19
	call WriteString
	
	MOV EDX, OFFSET help20
	call WriteString
	
	call Crlf
	done:
		ret

Help_p ENDP
;=====================================
;RUN_P
;Responds to commands RUN. Checks to make sure job name 8 chars or less.
;Stores job name in variable job_name.
Run_p PROC USES EAX ECX EDX
	
	CMP num_of_words, 1										;check if user entered 1 parameter, or more than one
	JG two_parameters_entered
	
	one_parameter_entered:									;if only one paramter is entered, that is just "Run" entered...
		MOV EDX, OFFSET Run_accepted
		CALL WriteString
		
		MOV EDX, OFFSET enter_job_name						;...ask user to enter job name
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		CALL GetFirstWord_p
		INVOKE Str_length, ADDR a_word						;get length of second word
		
		CMP EAX, 0											;if string_length is 0, too short
		JE too_short
		
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR a_word						;make word uppercase
		INVOKE Str_copy, ADDR a_word, ADDR job_name			;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here			
	
	two_parameters_entered:									;if two parameters entered...
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here
					
	run_process:
		CALL Run_job_p										;Run the job
		JMP done
	
	too_short:
		MOV EDX, OFFSET Run_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_short					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_long:
		MOV EDX, OFFSET Run_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_long					;show "too long" error and return
		CALL WriteString
		JMP done
	
	done:
		ret

Run_p ENDP
;=====================================
;HOLD_P
;Responds to command HOLD. Checks to make sure job name 8 chars or less.
;Stores job name in variable job_name.
Hold_p PROC USES EAX ECX EDX
	
	CMP num_of_words, 1										;check if user entered 1 parameter, or more than one
	JG two_parameters_entered
	
	one_parameter_entered:									;if only one paramter is entered, that is just "HOLD" entered...
		MOV EDX, OFFSET hold_accepted
		CALL WriteString
		
		MOV EDX, OFFSET enter_job_name						;...ask user to enter job name
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		CALL GetFirstWord_p
		INVOKE Str_length, ADDR a_word						;get length of second word
		
		CMP EAX, 0											;if string_length is 0, too short
		JE too_short
		
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR a_word						;make word uppercase
		INVOKE Str_copy, ADDR a_word, ADDR job_name			;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here			
	
	two_parameters_entered:									;if two parameters entered...
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here
					
	run_process:
		CALL Hold_job_p										;Hold the job
		JMP done
	
	too_short:
		MOV EDX, OFFSET hold_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_short					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_long:
		MOV EDX, OFFSET hold_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_long					;show "too long" error and return
		CALL WriteString
		JMP done
	
	done:
		ret

Hold_p ENDP
;=====================================
;KILL_P
;Responds to command KILL. Checks to make sure job name 8 chars or less.
;Stores job name in variable job_name.
Kill_p PROC USES EAX ECX EDX
	
	CMP num_of_words, 1										;check if user entered 1 parameter, or more than one
	JG two_parameters_entered
	
	one_parameter_entered:									;if only one paramter is entered, that is just "kill" entered...
		MOV EDX, OFFSET kill_accepted
		CALL WriteString
		
		MOV EDX, OFFSET enter_job_name						;...ask user to enter job name
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		CALL GetFirstWord_p
		INVOKE Str_length, ADDR a_word						;get length of second word
		
		CMP EAX, 0											;if string_length is 0, too short
		JE too_short
		
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR a_word						;make word uppercase
		INVOKE Str_copy, ADDR a_word, ADDR job_name			;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here			
	
	two_parameters_entered:									;if two parameters entered...
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		JMP run_process										;Further processing must jump here
					
	run_process:
		CALL kill_job_p										;kill the job
		JMP done
	
	too_short:
		MOV EDX, OFFSET kill_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_short					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_long:
		MOV EDX, OFFSET kill_accepted
		CALL WriteString
		MOV EDX, OFFSET job_name_too_long					;show "too long" error and return
		CALL WriteString
		JMP done
	
	done:
		ret

Kill_p ENDP
;=========================
;STEP_P
;Responds to command STEP. Takes one processing step if only [STEP] is entered.
;Takes n steps if [STEP] n is entered. n must be 1 through 300. The step size is
;stored in variable n.
Step_p PROC USES EAX EDX

	.DATA
	
	;temporarily store step size
	num DWORD 0
	
	.CODE
	
	MOV EAX, 0
	CMP num_of_words, 1										;check if user entered 1 parameter, or more than one
	JG two_parameters_entered
	
	one_parameter_entered:									;if only one paramter is entered, that is just "STEP" entered...
		
		JMP run_process
		
		;Increase system time by one
		;Convert binary to ASCII, OR with 30h
		;MOV EDX, OFFSET system_time
		;CALL ParseInteger32
		;INC EAX
		;MOV num, EAX
		;MOV ECX, 0
		;ADD num[ECX], 30h
		;MOV ESI, OFFSET num
		;MOV EDI, OFFSET system_time
		;MOVSD
				
		;Inform user
		;inform_user:
		;MOV EDX, OFFSET step_taken
		;CALL WriteString
		;CALL Show_system_time_p		
		;JMP done
		
				
	two_parameters_entered:									;if two parameters entered...
		MOV EDX, OFFSET second_word							
		CALL ParseInteger32									;convert string in second_word to integer
		CMP EAX, 127										;binary integer value is returned in EAX
		JG too_big											;error if greater than 127
		
		CMP EAX, 1											;error if less than 0
		JL too_small
		
		MOV n, AL											;copy the integer to n
		
		JMP run_process										;Further processing must jump here
					
	run_process:
		CALL step_helper_p
		;CALL WriteString
		JMP done
	
	too_small:
		MOV EDX, OFFSET step_accepted
		CALL WriteString
		MOV EDX, OFFSET step_too_small					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_big:
		MOV EDX, OFFSET step_accepted
		CALL WriteString
		MOV EDX, OFFSET step_too_big					;show "too long" error and return
		CALL WriteString
		JMP done
	
	done:
		ret

Step_p ENDP
;===================
;SHOW_P
;Description: Responds to command SHOW and displays the records in the queue
;Precondition: "queue" must exist and must be organized according to JOB RECORD STRUCTURE.
;				Look just above main .DATA section
;Postcondition:	Records in queue will be displayed line by line
Show_p PROC USES ESI EDI EDX EAX

	.DATA
	
	;A temporary variable
	myTemp DWORD 0
	
	.CODE
	
	;Move total number of bytes to variable "queue total bytes"
	CALL Get_queue_total_bytes_p
	MOV EAX, queue_total_bytes
		
	;Display Title
	CALL Crlf									
	MOV EDX, OFFSET show_title					
	CALL WriteString
	CALL Crlf									
	CALL Crlf									
	MOV EDX, OFFSET show_subtitles				
	CALL WriteString
	CALL Crlf

	;Initialize our record offset
	MOV slot, 0
		
	L1:
		;Copy job status byte to show_buffer
		CLD	
		MOV ESI, OFFSET queue
		ADD ESI, slot
		ADD ESI, JOB_STATUS_POS
		MOV EDI, OFFSET show_buffer
		MOVSB
		INVOKE Str_ucase, ADDR show_buffer

		;If job status byte is "A", jump to next record
		CLD
		MOV ESI, OFFSET show_buffer
		MOV EDI, OFFSET job_avail_byte
		CMPSB
		JE skip_record
		
		;Otherwise, show the record
		MOV EDX, OFFSET show_buffer
		CALL WriteString		
		;MOV EDX, OFFSET some_space					
		;Call WriteString				
		CALL Flush_show_buffer_p
		
		;Show job priority byte
		;CLD
		;MOV ESI, OFFSET queue
		;ADD ESI, slot
		;ADD ESI, JOB_PRIORITY_POS
		;MOV EDI, OFFSET show_buffer
		;MOVSB
		;INVOKE Str_ucase, ADDR show_buffer		
		;MOV EDX, OFFSET show_buffer
		;CALL WriteString		
		;MOV EDX, OFFSET some_space					
		;Call WriteString
		;MOV EDX, OFFSET some_space					
		;Call WriteString
		;CALL Flush_show_buffer_p
		
		CLD
		MOV ESI, OFFSET queue
		ADD ESI, slot
		ADD ESI, JOB_PRIORITY_POS
		MOV EDX, OFFSET some_space					
		Call WriteString
		MOV myTemp, EAX
		MOV EAX, 0
		MOV AL, BYTE PTR [ESI]
		CALL WriteDec
		MOV EDX, OFFSET some_space					
		Call WriteString
		MOV EDX, OFFSET some_space					
		Call WriteString
		MOV EAX, myTemp
		CALL Flush_show_buffer_p

		;Show job name bytes
		CLD
		MOV ESI, OFFSET queue
		ADD ESI, slot
		ADD ESI, JOB_NAME_POS
		MOV EDI, OFFSET show_buffer
		MOVSD
		MOVSD
		INVOKE Str_ucase, ADDR show_buffer		
		MOV EDX, OFFSET show_buffer
		CALL WriteString		
		CALL add_space
		CALL Flush_show_buffer_p
		
		;Show run time bytes
		;CLD
		;MOV ESI, OFFSET queue
		;ADD ESI, slot
		;ADD ESI, JOB_RUN_TIME_POS
		;MOV EDI, OFFSET show_buffer
		;MOVSW
		;INVOKE Str_ucase, ADDR show_buffer		
		;MOV EDX, OFFSET show_buffer
		;CALL WriteString		
		;MOV EDX, OFFSET some_space					
		;Call WriteString		
		;CALL Flush_show_buffer_p
		
		CLD
		MOV ESI, OFFSET queue
		ADD ESI, slot
		ADD ESI, JOB_RUN_TIME_POS
		MOV EDX, OFFSET some_space					
		Call WriteString
		MOV myTemp, EAX
		MOV EAX, 0
		MOV AL, BYTE PTR [ESI]
		CALL WriteDec
		MOV EAX, myTemp
		MOV EDX, OFFSET some_space					
		Call WriteString
		;CALL Crlf
		CALL Flush_show_buffer_p
		
		;Show start time bytes
		CLD
		MOV ESI, OFFSET queue
		ADD ESI, slot
		ADD ESI, JOB_START_TIME_POS
		MOV EDX, OFFSET some_space					
		Call WriteString
		MOV myTemp, EAX
		MOV EAX, 0
		MOV AL, BYTE PTR [ESI]
		CALL WriteDec
		MOV EAX, myTemp
		CALL Crlf
		CALL Flush_show_buffer_p
		
		skip_record:
			ADD slot, SIZE_OF_RECORD
			CMP slot, EAX		
			JE done
	JMP L1
				
	done:
		ret
				
Show_p ENDP
;==================
;LOAD_P
;Responds to command LOAD
Load_p PROC
	
	MOV EDX, OFFSET load_accepted							;inform user, load command has been accepted
	CALL WriteString

	CMP num_of_words, 1										;check if user entered 1 parameter, jump to appropriate section
	JE one_parameter_entered
	
	CMP num_of_words, 2										;check if user entered 2 parameters, jump to appropriate section
	JE two_parameters_entered
	
	CMP num_of_words, 3										;check if user entered 3 parameters, jump to appropriate section
	JE three_parameters_entered
	
	CMP num_of_words, 4										;check if user entered 3 parameters, jump to appropriate section
	JE four_parameters_entered
	
	one_parameter_entered:									;if only "LOAD" was entered
	
		;Ask for job name
		;================
		
		MOV EDX, OFFSET enter_job_name						;...ask user to enter job name
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		CALL GetFirstWord_p
		INVOKE Str_length, ADDR a_word
		
		CMP EAX, 0											;if string_length is 0, too short
		JE too_short
		
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR a_word						;make word uppercase
		INVOKE Str_copy, ADDR a_word, ADDR job_name			;copy string to job_name if all is well
		
		CALL Flush_a_word_p	

		;Ask for priority
		;================
		MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big											;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		MOV priority, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR priority			;if all is well, move the characters into priority

		;Ask for run time
		;================
		MOV EDX, OFFSET enter_run_time						;...ask user to enter run time
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO runtime_too_small								;if non-numbers entered, show error
		
		CMP EAX, 50											;binary integer value is returned in EAX
		JG runtime_too_big									;error if greater than 50
		
		CMP EAX, 1											;error if less than 1
		JL runtime_too_small
		
		MOV run_time, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR run_time			;if all is well, move the characters into run_time
			
		jmp run_process										;Further processing must jump here
		
	
	two_parameters_entered:									;if "LOAD" and job name were entered
	
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		;Ask for priority
		;================
		MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big											;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		MOV priority, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR priority			;if all is well, move the characters into priority

		;Ask for run time
		;================
		MOV EDX, OFFSET enter_run_time						;...ask user to enter run time
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO runtime_too_small								;if non-numbers entered, show error
		
		CMP EAX, 50											;binary integer value is returned in EAX
		JG runtime_too_big									;error if greater than 50
		
		CMP EAX, 1											;error if less than 1
		JL runtime_too_small
		
		MOV run_time, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR run_time			;if all is well, move the characters into run_time
			
		jmp run_process										;Further processing must jump here	
		
		
	three_parameters_entered:								;if "LOAD", job name, and priority were entered
		
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		;Ask for priority									;no need to ask for priority if it was entered, just test for validity
		;================
		;MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		;CALL WriteString
		
		;MOV EDX, OFFSET buffer								;read user entry						
		;MOV ECX, SIZEOF buffer								
		;CALL ReadString
		
		MOV EDX, OFFSET third_word							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big									;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		MOV priority, EAX
		;INVOKE Str_copy, ADDR third_word, ADDR priority		;if all is well, move the characters into priority

		;Ask for run time
		;================
		MOV EDX, OFFSET enter_run_time						;...ask user to enter run time
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO runtime_too_small								;if non-numbers entered, show error
		
		CMP EAX, 50											;binary integer value is returned in EAX
		JG runtime_too_big									;error if greater than 50
		
		CMP EAX, 1											;error if less than 1
		JL runtime_too_small
		
		MOV run_time, EAX
		;INVOKE Str_copy, ADDR buffer, ADDR run_time			;if all is well, move the characters into run_time
			
		jmp run_process										;Further processing must jump here
	
				
	four_parameters_entered:								;if "LOAD", job name, priority, and run time were entered.
															;Ask for nothing to entered, just test for validity of all entries
	
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		;Ask for priority									;no need to ask for priority if it was entered, just test for validity
		;================
		;MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		;CALL WriteString
		
		;MOV EDX, OFFSET buffer								;read user entry						
		;MOV ECX, SIZEOF buffer								
		;CALL ReadString
		
		MOV EDX, OFFSET third_word							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big									;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		MOV priority, EAX
		;INVOKE Str_copy, ADDR third_word, ADDR priority			;if all is well, move the characters into priority

		;Ask for run time									;no need to ask, just test for validity
		;================
		;MOV EDX, OFFSET enter_run_time						;...ask user to enter run time
		;CALL WriteString
		
		;MOV EDX, OFFSET buffer								;read user entry						
		;MOV ECX, SIZEOF buffer								
		;CALL ReadString
		
		MOV EDX, OFFSET fourth_word							
		CALL ParseInteger32									;convert string in buffer to integer
		JO runtime_too_small								;if non-numbers entered, show error
		
		CMP EAX, 50											;binary integer value is returned in EAX
		JG runtime_too_big									;error if greater than 50
		
		CMP EAX, 1											;error if less than 1
		JL runtime_too_small
		
		MOV run_time, EAX
		
		;INVOKE Str_copy, ADDR fourth_word, ADDR run_time			;if all is well, move the characters into run_time
			
		jmp run_process										;Further processing must jump here
	
		
	run_process:
		Call Load_job_p										;Load the job
				
		JMP done	
		
	
	;Errors
	;======
	too_short:
		MOV EDX, OFFSET job_name_too_short					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_long:
		MOV EDX, OFFSET job_name_too_long					;show "too long" error and return
		CALL WriteString
		JMP done
	
	prioritytoo_small:
		MOV EDX, OFFSET priority_too_small					;show "too short" error and return
		CALL WriteString
		JMP done
				
	prioritytoo_big:
		MOV EDX, OFFSET priority_too_big						;show "too long" error and return
		CALL WriteString
		JMP done
		
	runtime_too_small:
		MOV EDX, OFFSET run_time_too_small					;show "too short" error and return
		CALL WriteString
		JMP done
				
	runtime_too_big:
		MOV EDX, OFFSET run_time_too_big					;show "too long" error and return
		CALL WriteString
		JMP done	
	
		
	done:
		ret

Load_p ENDP
;==================
;CHANGE_P
;Responds to command CHANGE
Change_p PROC
	
	MOV EDX, OFFSET change_accepted							;inform user, load command has been accepted
	CALL WriteString

	CMP num_of_words, 1										;check if user entered 1 parameter, jump to appropriate section
	JE one_parameter_entered
	
	CMP num_of_words, 2										;check if user entered 2 parameters, jump to appropriate section
	JE two_parameters_entered
	
	CMP num_of_words, 3										;check if user entered 3 parameters, jump to appropriate section
	JE three_parameters_entered
	
	one_parameter_entered:									;if only "CHANGE" was entered
	
		;Ask for job name
		;================
		
		MOV EDX, OFFSET enter_job_name						;...ask user to enter job name
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		CALL GetFirstWord_p
		INVOKE Str_length, ADDR a_word
		
		CMP EAX, 0											;if string_length is 0, too short
		JE too_short
		
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR a_word						;make word uppercase
		INVOKE Str_copy, ADDR a_word, ADDR job_name			;copy string to job_name if all is well
		
		CALL Flush_a_word_p	


		;Ask for priority
		;================
		MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error		
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big											;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		JO prioritytoo_small								;if non-numbers entered, show error	

		MOV priority, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR priority			;if all is well, move the characters into priority

		jmp run_process										;Further processing must jump here
		
	
	two_parameters_entered:									;if "CHANGE" and job name were entered
	
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		;Ask for priority
		;================
		MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		CALL WriteString
		
		MOV EDX, OFFSET buffer								;read user entry						
		MOV ECX, SIZEOF buffer								
		CALL ReadString
		
		MOV EDX, OFFSET buffer							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error		
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big									;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		JO prioritytoo_small								;if non-numbers entered, show error
		
		MOV priority, EAX
		
		;INVOKE Str_copy, ADDR buffer, ADDR priority			;if all is well, move the characters into priority

		jmp run_process										;Further processing must jump here	
		
		
	three_parameters_entered:								;if "CHANGE", job name, and priority were entered
		
		INVOKE Str_length, ADDR second_word					;...check length of second word
		CMP EAX, 8											;if greater than 8, it's too long
		JG too_long
		
		INVOKE Str_ucase, ADDR second_word					;make word uppercase
		INVOKE Str_copy, ADDR second_word, ADDR job_name	;copy string to job_name if all is well
		
		;Ask for priority									;no need to ask for priority if it was entered, just test for validity
		;================
		;MOV EDX, OFFSET enter_priority						;...ask user to enter priority
		;CALL WriteString
		
		;MOV EDX, OFFSET buffer								;read user entry						
		;MOV ECX, SIZEOF buffer								
		;CALL ReadString
		
		MOV EDX, OFFSET third_word							
		CALL ParseInteger32									;convert string in buffer to integer
		JO prioritytoo_small								;if non-numbers entered, show error		
		
		CMP EAX, 7											;binary integer value is returned in EAX
		JG prioritytoo_big									;error if greater than 7
		
		CMP EAX, 0											;error if less than 0
		JL prioritytoo_small
		
		JO prioritytoo_small								;if non-numbers entered, show error
		
		MOV priority, EAX
		
		;INVOKE Str_copy, ADDR third_word, ADDR priority			;if all is well, move the characters into priority

		jmp run_process										;Further processing must jump here
	
				
	run_process:
		
		CALL Change_priority_p
		JMP done
	
	;Errors
	;======
	too_short:
		MOV EDX, OFFSET job_name_too_short					;show "too short" error and return
		CALL WriteString
		JMP done
				
	too_long:
		MOV EDX, OFFSET job_name_too_long					;show "too long" error and return
		CALL WriteString
		JMP done
	
	prioritytoo_small:
		MOV EDX, OFFSET priority_too_small					;show "too short" error and return
		CALL WriteString
		JMP done
				
	prioritytoo_big:
		MOV EDX, OFFSET priority_too_big						;show "too long" error and return
		CALL WriteString
		JMP done
		
		
	done:
		ret

Change_p ENDP
;==================
;FIND_EMPTY_SLOT_P
;Description: Looks in the queue for the first slot with "A" (available)
;Precondition: variable "slot" must exist and must be a SDWORD
;Postcondition:	variable "slot" will contain record number, 0 through 9, or will contain -1
Find_Empty_Slot_p PROC USES ESI EDI EBX

	.DATA
	my_record_number DWORD 0
		
	.CODE	
	;Move total number of bytes to variable "queue total bytes"
	CALL Get_queue_total_bytes_p
	MOV EAX, queue_total_bytes
	
	;Initialize variables
	MOV slot, -1
	MOV my_record_number, 0
	MOV EBX, 0
	
	L1:
		;Copy job status byte to small_buffer
		CALL Flush_small_buffer_p
		CLD	
		MOV ESI, OFFSET queue
		ADD ESI, my_record_number
		ADD ESI, JOB_STATUS_POS
		MOV EDI, OFFSET small_buffer
		MOVSB
		INVOKE Str_ucase, ADDR small_buffer
		
		;If job status byte is not "A", jump to next record
		CLD
		MOV ESI, OFFSET small_buffer
		MOV EDI, OFFSET job_avail_byte
		CMPSB
		JNE skip_record
		
		;Otherwise, return slot number
		MOV slot, EBX				
		JMP done		
		
		;Skip a record
		skip_record:
				INC EBX
				ADD my_record_number, SIZE_OF_RECORD
				CMP my_record_number, EAX
				JE done
				JMP L1
		
		done:
			ret	

Find_Empty_Slot_p ENDP
;==================
;FLUSH_SHOW_BUFFER_P
;Flushes (resets) show_buffer variables
Flush_show_buffer_p PROC USES ECX EAX

	INVOKE Str_length, ADDR show_buffer				;get show_buffer string length, place in EAX
	MOV ECX, 0										;counter for show_buffer
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET show_buffer							;point EDI to beginning of show_buffer
	L1:
		MOV show_buffer[ECX], 0							;move null char into show_buffer
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE done
		
		JMP L1
	
	done:
		ret
Flush_show_buffer_p ENDP
;==================
;LOAD_JOB_P
;Loads a job into the queue.
;Uses Find_job name_p which returns the slot number if the same job name is found in the queue
;Uses Find_empty_slot_p which returns the empty slot number in the variable slot
Load_job_p PROC USES EAX EBX ESI EDI

	;Refuse to load job with same name
	Call Find_job_name_p							
	CMP slot, -1
	JG error_same_job_name							

	;Error, if queue is full
	Call Find_empty_slot_p							
	CMP slot, -1
	JE no_empty_slots

	;Otherwise, get absolute position of slot
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, BYTE PTR slot
	MOV BL, SIZE_OF_RECORD
	MUL BL
	
	;EAX now contains slot's absolute position
	
	;LOAD AT THAT POSITION	
	;Load the status byte
	CLD
	MOV ESI, OFFSET job_hold_byte
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_STATUS_POS
	MOVSB
	
	;Load the priority
	CLD
	MOV ESI, OFFSET priority
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_PRIORITY_POS
	MOVSB
	
	;Load the job name
	CLD
	MOV ESI, OFFSET job_name
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_NAME_POS
	MOVSD
	MOVSD
	
	;Load the run time
	CLD
	MOV ESI, OFFSET run_time
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_RUN_TIME_POS
	MOVSW
	
	;Load the system time
	CLD
	MOV ESI, OFFSET system_time
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_START_TIME_POS
	MOVSD
	
	;Inform user
	MOV EDX, OFFSET load_successful
	CALL WriteString	
	JMP done
	
	error_same_job_name:
		MOV EDX, OFFSET same_job_name					
		CALL WriteString
		jmp done

	no_empty_slots:
		MOV EDX, OFFSET queue_is_full
		CALL WriteString
		jmp done

	done:
		ret

Load_job_p ENDP
;==================
;PREP_P
;Preps the queue with "A" in every job status byte. "A" means the job slot is available.
Prep_p PROC USES ESI EDI EBX

	;Move total number of bytes to variable "queue total bytes"
	CALL Get_queue_total_bytes_p
	MOV EAX, queue_total_bytes
	
	;Initialize EBX as our counter
	MOV EBX, 0
		
	L1:
		;Move "A" to first byte position of every record
		CLD
		MOV ESI, OFFSET job_avail_byte
		MOV EDI, OFFSET queue
		ADD EDI, EBX
		MOVSB
		
		;Loop back if not at end of record
		ADD EBX, SIZE_OF_RECORD
		CMP EBX, EAX
		JGE done
		JMP L1
		
	done:
		ret

Prep_p ENDP
;===============
;FLUSH_SMALL_BUFFER_P
;Flushes (resets) the small_buffer
Flush_small_buffer_p PROC USES ECX EAX
	
	INVOKE Str_length, ADDR small_buffer			;get small_buffer string length, place in EAX
	MOV ECX, 0										;counter for small_buffer
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET small_buffer					;point EDI to beginning of small_buffer
	L1:
		MOV small_buffer[ECX], 0					;move null char into small_buffer
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE done
		
		JMP L1
		
	done:
		ret

Flush_small_buffer_p ENDP
;===============
;FIND_JOB_NAME_P
;Description: Looks in the queue for the specified job name, returns slot number in variable "slot"
;Precondition: variable "slot" must exist and must be a SDWORD
;Postcondition:	variable "slot" will contain record number, 0 through 9, or will contain -1
Find_job_name_p PROC USES ESI EDI EBX
	
	.DATA
	record_number DWORD 0
		
	.CODE	
	;Move total number of bytes to variable "queue total bytes"
	CALL Get_queue_total_bytes_p
	MOV EAX, queue_total_bytes
	
	;Initialize variables
	MOV slot, -1
	MOV record_number, 0
	MOV EBX, 0
	
	L1:
		;Copy job status byte to small_buffer
		CALL Flush_small_buffer_p
		CLD	
		MOV ESI, OFFSET queue
		ADD ESI, record_number
		ADD ESI, JOB_STATUS_POS
		MOV EDI, OFFSET small_buffer
		MOVSB
		INVOKE Str_ucase, ADDR small_buffer
		
		;If job status byte is "A", jump to next record
		CLD
		MOV ESI, OFFSET small_buffer
		MOV EDI, OFFSET job_avail_byte
		CMPSB
		JE skip_record
		
		;Otherwise, place job name in small buffer
		CALL Flush_small_buffer_p
		CLD
		MOV ESI, OFFSET queue
		ADD ESI, record_number
		ADD ESI, JOB_NAME_POS
		MOV EDI, OFFSET small_buffer
		MOVSD
		MOVSD		
		
		INVOKE Str_ucase, ADDR small_buffer
		
		;Compare job name, byte by byte
		;CLD
		;MOV ESI, OFFSET small_buffer
		;MOV EDI, OFFSET job_name
		;MOV ECX, LENGTHOF small_buffer
		;REPE CMPSB
		INVOKE Str_compare, ADDR small_buffer, ADDR job_name
		;CMP ECX, 0
		JE found
		
		;Skip a record
		skip_record:
				INC EBX
				ADD record_number, SIZE_OF_RECORD
				CMP record_number, EAX
				JE done				
				
	JMP L1
	
	;If job name found, update slot
	found:
		MOV slot, EBX				
		JMP done
		
	done:
		ret

Find_job_name_p ENDP
;===============
;RUN_JOB_P
;Description: Changes a job's status from "H" to "R"
;Precondition: Job's status must be "H", otherwise error will occur
;Postcondition:	Job's status will be "R"
Run_job_p PROC USES EBX EAX

	.DATA
	
	;To temporarily hold register's contents
	temp DWORD 0
	
	.CODE

	;Find if job exists
	Call Flush_small_buffer_p
	Call Find_job_name_p
	Call Flush_small_buffer_p							
	
	;Error if job does not exist
	CMP slot, -1
	JE no_such_job_in_queue
	
	;If job does exist, get absolute position from slot number
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, BYTE PTR slot
	MOV BL, SIZE_OF_RECORD
	MUL BL
	
	;Move job status byte to small_buffer at that posititon
	CLD
	MOV ESI, OFFSET queue
	ADD ESI, EAX
	MOV EDI, OFFSET small_buffer
	MOV temp, ESI
	MOVSB
	
	;Compare byte, if "R", Error
	INVOKE Str_compare, ADDR small_buffer, ADDR job_run_byte
	JE already_running
	
	;If no error, change byte to "R"
	CLD
	MOV ESI, OFFSET job_run_byte
	MOV EDI, temp
	MOVSB											
			
	MOV EDX, OFFSET job_running								
	CALL WriteString
	JMP done
	
	;===ERRORS
	;Inform user job is already running
	already_running:											
		MOV EDX, OFFSET job_already_running
		CALL WriteString
		JMP done
	
	;Inform user no such job name exists
	no_such_job_in_queue:										
		MOV EDX, OFFSET no_such_job_name
		CALL WriteString
		JMP done	
		
	done:
		ret

Run_job_p ENDP
;==============
;HOLD_JOB_P
;Description: Changes a job's status from "R" to "H"
;Precondition: Job's status must be "R", otherwise error will occur
;Postcondition:	Job's status will be "H"
Hold_job_p PROC USES EBX EAX

	.DATA
	
	;To temp_holdorarily hold register's contents
	temp_hold DWORD 0
	
	.CODE

	;Find if job exists
	Call Flush_small_buffer_p
	Call Find_job_name_p
	Call Flush_small_buffer_p							
	
	;Error if job does not exist
	CMP slot, -1
	JE no_such_job_in_queue
	
	;If job does exist, get absolute position from slot number
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, BYTE PTR slot
	MOV BL, SIZE_OF_RECORD
	MUL BL
	
	;Move job status byte to small_buffer at that posititon
	CLD
	MOV ESI, OFFSET queue
	ADD ESI, EAX
	MOV EDI, OFFSET small_buffer
	MOV temp_hold, ESI
	MOVSB
	
	;Compare byte, if "H", Error
	INVOKE Str_compare, ADDR small_buffer, ADDR job_hold_byte
	JE already_holding
	
	;If no error, change byte to "H"
	CLD
	MOV ESI, OFFSET job_hold_byte
	MOV EDI, temp_hold
	MOVSB											
			
	MOV EDX, OFFSET job_holding								
	CALL WriteString
	JMP done
	
	;===ERRORS
	;Inform user job is already in hold mode
	already_holding:											
		MOV EDX, OFFSET job_already_holding
		CALL WriteString
		JMP done
	
	;Inform user no such job name exists
	no_such_job_in_queue:										
		MOV EDX, OFFSET no_such_job_name
		CALL WriteString
		JMP done	
		
	done:
		ret

Hold_job_p ENDP
;==============
;KILL_JOB_P
;Description: Changes a job's status from "H" to "A".
;Precondition: Job's status must be "H", otherwise error will occur.
;Postcondition:	Job's status will be "H". Job's name will be erased from queue.
KILL_JOB_P PROC USES EBX EAX

	.DATA
	
	;To temporaryorarily hold register's contents
	temporary DWORD 0
	
	.CODE

	;Find if job exists
	Call Flush_small_buffer_p
	Call Find_job_name_p
	Call Flush_small_buffer_p							
	
	;Error if job does not exist
	CMP slot, -1
	JE no_such_job_in_queue
	
	;If job does exist, get absolute position from slot number
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, BYTE PTR slot
	MOV BL, SIZE_OF_RECORD
	MUL BL
	
	;Move job status byte to small_buffer at that posititon
	CLD
	MOV ESI, OFFSET queue
	ADD ESI, EAX
	MOV EDI, OFFSET small_buffer
	MOV temporary, ESI
	MOVSB
	
	;Compare byte, if "R", Error
	INVOKE Str_compare, ADDR small_buffer, ADDR job_run_byte
	JE cannot_kill_running_job
	
	;If no error, change byte to "A"
	CLD
	MOV ESI, OFFSET job_avail_byte
	MOV EDI, temporary
	MOVSB											
			
	MOV EDX, OFFSET job_killed								
	CALL WriteString
	JMP done
	
	;===ERRORS
	;Inform user job is running
	cannot_kill_running_job:											
		MOV EDX, OFFSET cannot_kill_job
		CALL WriteString
		JMP done
	
	;Inform user no such job name exists
	no_such_job_in_queue:										
		MOV EDX, OFFSET no_such_job_name
		CALL WriteString
		JMP done	
		
	done:
		ret

KILL_JOB_P ENDP
;==============
;GET_QUEUE_TOTAL_BYTES
;Description: Gets total number of bytes in queue, places them in variable "queue_total_bytes"
;Precondition: Requires NUMBER_OF_RECORDS and SIZE_OF_RECORD must be integers that contain number of records
;				and byte size of record, respectively
;Postcondition:	Variable "queue_total_bytes" will contain total number of bytes in record
Get_queue_total_bytes_p PROC USES EAX EBX
	
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, NUMBER_OF_RECORDS
	;DEC AL
	MOV BL, SIZE_OF_RECORD
	MUL BL
	MOV queue_total_bytes, EAX				
	done:
		ret
				
Get_queue_total_bytes_p ENDP
;=============
;Gets first word of a string from a variable called buffer, ignores spaces and tabs. Buffer must be
;at least 60 bytes in length. Each word can be up to 60 characters. Places the word in variables a_word.

GetFirstWord_p PROC USES ECX EDX
	
	mov EDI, OFFSET buffer								;point EDI to beginning of buffer
	mov ESI, 0											;start ESI and 0
	mov ECX, 0											;use for counting

	mov string_length, AL								;store string length

	cmp string_length, 0				
	JE done
	
	;===Get the first word==========================

	get_first_word_loop:

		mov BL, BYTE PTR [EDI+ESI]							;move one char to BL

		cmp BL, 20h											;if space, skip it
		JE skip_tab_space_1

		cmp BL, 09h											;if tab, skip it							
		JE skip_tab_space_1

		cmp BL, 0h											;if end of line, quit
		JE done

		mov a_word[ECX], BL									;move one char into a_word variable
		inc char_count
		inc ECX

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is space, word is found
		cmp AL, 20h								
		JE word_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if next char is tab, word is found
		cmp AL, 09h							
		JE word_found

		mov AL, BYTE PTR [EDI+ESI+1]						;if end of line char, word is found
		cmp AL, 0h							
		JE word_found
		
		cmp char_count, 60									;will take up to 60 characters in a word
		JE word_found
		
	skip_tab_space_1:
		inc ESI
		jmp get_first_word_loop

	word_found:
		;mov EDX, OFFSET first_word							;show first word, can uncomment these two lines
		;call WriteString
		;call Crlf
		
	done:
		ret

GetFirstWord_p ENDP
;=============
;FLUSH_A_WORD_P
;Flushes (resets) a_word
Flush_a_word_p PROC USES ECX EAX EDI
	
	INVOKE Str_length, ADDR a_word					;get a_word string length, place in EAX
	MOV ECX, 0										;counter for a_word
	
	CMP EAX, 0										;if string length equals 0, get out of procedure
	JE done
	
	MOV EDI, OFFSET a_word							;point EDI to beginning of a_word
	L1:
		MOV a_word[ECX], 0							;move null char into a_word
		INC ECX
		
		CMP EAX, ECX								;check str_length
		JE done
		
		JMP L1	
		
	done:
		ret

Flush_a_word_p ENDP
;=============
;CHANGE_PRIORITY_P
;Description: Changes a job's priority value
;Precondition: Job's new priority value must be in variable "priority" and must be within the acceptable range
;Postcondition:	Job's current priority value will be changed to the new priority
Change_priority_p PROC USES EBX EAX

	;Find if job exists
	Call Flush_small_buffer_p
	Call Find_job_name_p
	Call Flush_small_buffer_p							
	
	;Error if job does not exist
	CMP slot, -1
	JE no_such_job_in_queue
	
	;If job does exist, get absolute position from slot number
	MOV EAX, 0
	MOV EBX, 0
	MOV AL, BYTE PTR slot
	MOV BL, SIZE_OF_RECORD
	MUL BL
	
	;Note: at this point, EAX contains job's absolute position
	
	;Change the job's priority
	CLD
	MOV ESI, OFFSET priority
	MOV EDI, OFFSET queue
	ADD EDI, EAX
	ADD EDI, JOB_PRIORITY_POS	
	MOVSB

	;Print confirmation
	MOV EDX, OFFSET job_priority_changed
	CALL WriteString
	JMP done
	
	;Inform user no such job name exists
	no_such_job_in_queue:										
		MOV EDX, OFFSET no_such_job_name
		CALL WriteString
		JMP done	
		
	done:
		ret

Change_priority_p ENDP
;=============
;Adds a tab to display in SHOW_P if job name is less than 8 characters
add_space PROC USES EAX EDX

	INVOKE Str_length, ADDR show_buffer
	CMP EAX, 8
	JL add_the_space
	JMP done
	
	add_the_space:
		MOV EDX, OFFSET some_space
		CALL WriteString
		
	done:
		ret

add_space ENDP
;=============
;Displays the system time
Show_system_time_p PROC
	
	MOV EDX, OFFSET show_sys_time
	CALL WriteString
	MOV EDX, OFFSET system_time
	CALL WriteString
	CALL Crlf
	ret

Show_system_time_p ENDP
;=============
step_helper_p PROC USES EAX EBX ECX EDX ESI EDI
	call align_p			;organize the records

n_loop:					;for executing n times
	CMP n, 0				;Check if it's the nth step
	JLE done				;if it is, we're done
						;otherwise start the inner priority loop
	MOV EBX, 0			;initialize current priority
priority_loop:				;loop that cycles through priorities
	CMP EBX, 7			;check if we've used all priorities
	JG next_n				;if we have used all priorities, then there are no records to step
						;so we just go to the next n and increment system time

	MOV EDX, OFFSET queue			;initialize to start of queue
access_loop:						;A loop to cycle through elements in queue.
	CMP EDX, next_availible_address	;Check if done with all records of this priority
	JGE next_priority				;If we have done all records of current priority, go on to next priority
								;otherwise continue checking this records with this priority
	MOV CL, 0[EDX]					;Move status byte into CL for comparison
	AND CL, 11011111b				;Convert status to uppercase
	CMP CL, 'R'					;Check if status is runnable
	JE runnable					;case: runnble - we can maybe step the record depending on if it's at the current priority
								;
	ADD EDX, SIZE_OF_RECORD			;otherwise, the record is not runnable
	JMP access_loop				;so we just go and access the next record in queue

runnable:
	MOV AH, BYTE PTR JOB_PRIORITY_POS[EDX]		;get the priorty byte
	MOVZX ECX, AH
	CMP EBX, ECX							;compare to see if priority byte is equivalent to the current priority
	JE execute							;if it is, the current record is first, runnable, and of highest priority,
										;meaning we should execute it
	ADD EDX, SIZE_OF_RECORD					;otherwise, keep on accessing elements in the queue using the current priority
	JMP access_loop						;

execute:
	DEC SWORD PTR [EDX + JOB_RUN_TIME_POS]		;update job run time
	MOV AL, BYTE PTR [EDX + JOB_RUN_TIME_POS]
	CMP AL, 0	;check if job is finished
	JLE rmvjb
	JG next_step							;case: record is NOT done executing

rmvjb:
	MOV CL, 'A'							
	MOV BYTE PTR [EDX], CL					;case: job IS done executing
	
	PUSH ECX								;
	PUSH EDX								;save registers

	
	CALL crlf
	MOV EDI, OFFSET temp_name				;move into name buffer
	MOV ESI, EDX
	ADD ESI, JOB_NAME_POS
	MOV ECX, 8
	CLD
	REP MOVSB

	MOV EDX, OFFSET job_finished_text1			;display job finished text
	CALL WriteString

	MOV EDX, OFFSET temp_name
	CALL WriteString

	MOV EDX, OFFSET job_finished_text2			
	CALL WriteString						

	MOV EAX, system_time
	CALL WriteInt
	CALL crlf								;new lines for formatting
	CALL crlf								;

	POP EDX								;restore registers
	POP ECX								;
next_step:
	CALL rotate_p							;rotate
	JMP next_n

next_record:
	ADD EDX, SIZE_OF_RECORD
	JMP access_loop

next_priority:
	INC EBX			;increment priority
	JMP priority_loop

next_n:
	INC system_time
	DEC n
JMP n_loop

done:
	MOV EDX, OFFSET system_time_text
	CALL WriteString
	MOV EAX, system_time
	CALL WriteDec
	CALL crlf
	CALL crlf

	RET
step_helper_p ENDP
;==============
align_p PROC USES  EAX EBX ECX EDX ESI EDI
	MOV EAX, OFFSET queue				;Initialize queue pointers
	MOV EBX, OFFSET queue				;

loop1:
	CMP EBX, (OFFSET queue + SIZE_OF_RECORD*NUMBER_OF_RECORDS)		;check if out of bounds	
	JGE fill												;if out, go to done
	
	MOV DL, 0[EBX]											;load current record's status character into DL
	AND DL, 11011111b										;compare status to uppercase
	CMP DL, 'R'
	JE move_record
	CMP DL, 'H'
	JE move_record
	JMP incrementB
move_record:
	CMP EAX, EBX
	JE incrementA
	MOV ESI, EBX
	MOV EDI, EAX
	MOV ECX, SIZE_OF_RECORD
	CLD
	REP MOVSB
incrementA:
	ADD EAX, SIZE_OF_RECORD
incrementB:
	ADD EBX, SIZE_OF_RECORD
	JMP loop1
fill:
	MOV next_availible_address, EAX

loop2:
	CMP EAX, (OFFSET queue + SIZE_OF_RECORD*NUMBER_OF_RECORDS)
	JGE done
	MOV DL, 'A'
	MOV 0[EAX],DL
	ADD EAX, SIZE_OF_RECORD
	JMP loop2
done:
	RET
align_p ENDP
;===============
rotate_p PROC USES EAX EBX ECX ESI EDI
	call align_p

	CMP next_availible_address, OFFSET queue	;Empty queue case
	JLE done

	MOV ESI, OFFSET queue			;this block saves the first record in temp_record		
	MOV EDI, OFFSET temp_record					
	MOV ECX, SIZE_OF_RECORD			
	CLD			
	REP MOVSB


	MOV EAX, OFFSET queue
shift_loop:
	ADD EAX, SIZE_OF_RECORD			;update and check if out of bounds
	CMP EAX, next_availible_address	;if we are out of bounds, then
	JGE append					;jump to code that appends the first element to the end

	MOV ESI, EAX
	MOV EDI, EAX					;Set up destination as:
	SUB EDI, SIZE_OF_RECORD			;One record before source
	MOV ECX, SIZE_OF_RECORD			;Initialize counter
	CLD							;set direction
	REP MOVSB						;copy over
	JMP shift_loop					;go back to beginning of loop
append:
	MOV EDI, next_availible_address
	SUB EDI, SIZE_OF_RECORD
	MOV ESI, OFFSET temp_record
	MOV ECX, SIZE_OF_RECORD
	CLD
	REP MOVSB
done:
	RET
rotate_p ENDP


END main