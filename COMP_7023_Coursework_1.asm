; Assembly language demonstration program

; Build either with the automatic build script:
; "build_asm_vX.sh coursework_1_demo.asm"
; OR
; Assemble command:
; "nasm -g -f elf64 -o coursework_1_demo.o coursework_1_demo.asm"
; Link command:
; "gcc coursework_1_demo.o -no-pie -o coursework_1_demo"
; Executable generated is: "coursework_1_demo"
; Can be run with: "./coursework_1_demo"

; This include line is an absolute path to the I/O library. You may wish to change it to suit your own file system.
%include "/home/malware/asm/joey_lib_io_v9_release.asm"

; "global main" defines the entry point of the executable upon linking.
; In other words, "main" defines the point in the code from which the final executable starts execution.
global main

; The ".data" section is where initialised data in memory is defined. This is where we define strings and other predefined data.
; This section is read/write but NOT executable. If it were executable, someone could modify the data to be malicious executable code and then execute it.
; We don't want that! See "Data Execution Prevention (DEP)".
; "db" means "Define Byte", which allocates 1 byte.
; We could also use:
; "dw" = "Define Word", which allocates 2 bytes
; "dd" = "Define Doubleword", which allocates 4 bytes
; "dq" = "Define Quadword, which allocates 8 bytes
section .data
    str_main_menu db 10,\
                            "Main Menu", 10,\
                            " 1. Add User", 10,\
                            " 2. List All Users", 10, \
                            " 3. Count Users", 10,\
                            " 4. Exit", 10,\
                            "Please Enter Option 1 - 4", 10, 0
    
    department_question db 10,\
                                "Select the number that corresponds with your department", 10,\
                                " 1. Park Keeper", 10,\
                                " 2. Gift Shop", 10,\
                                " 3. Cafe", 10, \
                                "Please Enter Option 1 - 3", 10, 0
    ; Note - after each string we add bytes of value 10 and zero (decimal). These are ASCII codes for linefeed and NULL, respectively.
    ; The NULL is required because we are using null-terminated strings. The linefeed makes the console drop down a line, which saves us having to call "print_nl_new" function separately.
    ; In fact, some strings defined here do not have a linefeed character. These are for occations when we don't want the console to drop down a line when the program runs.
    ;STAFF
    str_program_exit db "Program exited normally.", 10, 0
    str_option_selected db "Option selected: ", 0
    str_invalid_option db "Invalid option, please try again.", 10, 0
    str_enter_surname db "Enter surname:", 10, 0
    str_enter_forename db "Enter forename:", 10, 0
    str_enter_salary db "Enter salary:", 10, 0
    str_enter_year db "Enter starting year:", 10, 0
    str_enter_id db "Enter ID:", 10, 0
    str_enter_email db "Enter email:", 10, 0
    str_array_full db "Can't add - storage full.", 10, 0
    str_number_of_users db "Number of users: ", 0
    str_error db "Error", 0
    
    email db "@jnz.co.uk", 0
    park_keeper db "Park Keeper", 0
    gift_shop db "Gift Shop", 0
    cafe db "Cafe", 0
    
    
    ;Displaying staff details
    display_staff_letter_p db "p", 0
    display_staff db "ID: ", 0
    display_year db "Year of Joining: ", 0
    display_name db "Full Name: ", 0
    display_salary db "Annual Salary: ", 0
    display_dept db "Deaprtment: ", 0
    display_email db "Email: ", 0 

    ; Here we define the size of the block of memory that we want to reserve to hold the users' details
    ; A user record stores the following fields:
    ; forename = 64 bytes (string up to 63 characters plus a null-terminator)
    ; surname = 64 bytes (string up to 63 characters plus a null-terminator)
    ; salary = 2 byte (we're assuming that we don't have any users aged over 255 years old. Although if we entered Henry IV, this may be a problem!)
    ; year = 2 byte (we're assuming that we don't have any users aged over 255 years old. Although if we entered Henry IV, this may be a problem!)
    ; User ID = 4 bytes (string up to 63 characters plus a null terminator)
    ; department = 12 bytes
    ; email = 64 bytes
    size_forename equ 64 ;we define size of block of memory that we want
    size_surname equ 64 ;to reserve and store in size_name_of_field 
    size_id equ 4
    size_dept equ 12
    size_salary equ 4
    size_year_of_joining equ 2
    size_email equ 64

    ; Total size of user record is therefore 64+64+64+2+2 = 136 bytes
    size_user_record equ size_forename + size_surname + size_id + size_dept + size_salary + size_year_of_joining + size_email
    
    max_num_users equ 100 ; 100 users maximum in array (we can make this smaller in debugging for testing array limits etc.)
    size_users_array equ size_user_record*max_num_users ; This calculation is performed at build time and is therefore hard-coded in the final executable.
    ; We could have just said something like "size_users_array equ 19300". However, this is less human-readable and more difficult to modify the number of users / user record fields.
    ; The compiled code would be identical in either case.
    
    current_number_of_users dq 0 ; this is a variable in memory which stores the number of users which have currently been entered into tthe array.
    
    current_year equ 2023
    
; The ".bss" section is where we define uninitialised data in memory. Unlike the .data section, this data does not take up space in the executable file (apart from its definition, of course).
; Upon execution, this data is initialised to zero. This section is read/write but NOT executable, for the same reasons as .data section above.
; The syntax differs slightly from that of the .data section:
; resb = Reserve a Byte (1 byte)
; resw = Reserve a Word (2 bytes)
; resd = Reserve a Doubleword (4 bytes)
; resq = Reserve a Quadword (8 bytes)
section .bss
    users: resb size_users_array; space for max_num_users user records. "resb
    temp_users: resb size_user_record

; The ".text" section contains the executable code. This area of memory is generally read-only so that the code cannot be mucked about with at runtime by a mischievous user.
section .text

add_user:
; Adds a new user into the array
; We need to check that the array is not full before calling this function. Otherwise buffer overflow will occur.
; No parameters (we are using the users array as a global)
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rcx, temp_users ; base address of temp users array
    
    ; get user id
    mov rdi, str_enter_id
    call print_string_new ; print message
    call read_uint_new ; get input from user
    ; inputted number is now in the RAX register
    mov DWORD[rcx], eax ; we are only going to copy the least significant byte of RAX (AL), because our age field is only one byte
    cmp rax, 999999
    jle .error
    cmp rax, 10000000
    jge .error


    mov rsi, park_keeper
    ; get forename
    add rcx, size_id ; move along by 1 byte (which is the size of age field)
    mov rdi, str_enter_forename
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rbx, rax
    call string_length
    cmp rax, 63 ; check if string is larger than 63 characters, allowing space for null
    ja .error
    mov rsi, rbx ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array
    
    ; get surname
    add rcx, size_forename ; move along by 64 bytes (which is the size reserved for the forename string)
    mov rdi, str_enter_surname
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rbx, rax
    call string_length
    cmp rax, 63 ; check if string is larger than 63 characters, allowing space for null
    ja .error
    mov rsi, rbx ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array
    
    
    ; get start year
    add rcx, size_surname ; move along by 64 bytes (which is the size reserved for the surname string)
    mov rdi, str_enter_year
    call print_string_new ; print message
    call read_uint_new ; get input from user
    ; inputted number is now in the RAX register
    mov WORD[rcx], ax ; we are only going to copy the least significant byte of RAX (AL), because our age field is only one byte
    
    ; get salary
    add rcx, size_year_of_joining ; move along by 64 bytes (which is the size reserved for the surname string)
    mov rdi, str_enter_salary
    call print_string_new ; print message
    call read_uint_new ; get input from user
    ; inputted number is now in the RAX register
    mov DWORD[rcx], eax ; we are only going to copy the least significant byte of RAX (AL), because our age field is only one byte
    
    
    
    ;get department
    mov rdi, department_question
    call print_string_new ; print message
    call read_int_new ;read in option
    cmp rax, 1
    jne .check_gift_shop
    mov rsi, park_keeper
    jmp .add_department
   .check_gift_shop:
    cmp rax, 2
    jne .check_cafe
    mov rsi, gift_shop
    jmp .add_department
   .check_cafe:
    cmp rax, 3
    jne .department_error
    
    mov rsi, cafe
    jmp .add_department
   .department_error:
    mov rax, -2
    jmp .error
   .add_department:
    add rcx, size_salary 
    mov rdi, rcx; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array
      
    ; get email
    mov rdi, str_enter_email
    call print_string_new ; print message
    call read_string_new
    mov rbx, rax
    call string_length
    cmp rax, 63 ; check if string is larger than 63 characters, allowing space for null
    ja .error
    mov rsi, rbx
    lea rsi, [rbx + rax - 10];go the last 10 bytes of the user string and check its "@jnz.co.uk"
    lea rdi, [email]
    call strings_are_equal
    cmp rax, 1
    jne .error
    add rcx, size_dept
    mov rsi, rbx
    mov rdi, rcx ; address of new string into rsi
    call copy_string ; copy string from input buffer into user record in array
    
  
    ; copy temp array into array 
    mov rcx, users ; base address of users array
    mov rsi, temp_users
    mov rax, QWORD[current_number_of_users] ; value of current_number_of_users
    mov rbx, size_user_record ; size_user_record is an immediate operand since it is defined at build time.
    mul rbx ; calculate address offset (returned in RAX).
    ; RAX now contains the offset of the next user record. We need to add it to the base address of users record to get the actual address of the next empty user record.
    add rcx, rax ; calculate address of next unused users record in array
    ; RCX now contins address of next empty user record in the array, so we can fill up the data.
    mov rdi, rcx
    call copy_string ; copy id
    add rsi, size_id
    lea rdi, [rcx + size_id]
    call copy_string ; copy forename
    add rsi, size_forename
    lea rdi, [rcx + size_forename+size_id]
    call copy_string ; copy surname
    add rsi, size_surname
    lea rdi, [rcx + size_forename+size_id+size_surname]
    call copy_string ; start year
    add rsi, size_year_of_joining
    lea rdi, [rcx + size_forename+size_id+size_surname+size_year_of_joining]
    call copy_string ; salary
    add rsi, size_salary
    lea rdi, [rcx + size_forename+size_id+size_surname+size_year_of_joining+size_salary]
    call copy_string ; department
    add rsi, size_dept
    lea rdi, [rcx + size_forename+size_id+size_surname+size_year_of_joining+size_salary+size_dept]
    call copy_string ; email
    
    ; clear temp array here
    mov rdi, temp_users
    mov rcx, size_user_record
    xor al, al
    rep stosb
    

    inc QWORD[current_number_of_users] ; increment our number of users counter, since we have just added a record into the array.
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function add_user
    
   .error:
   ; clear temp array here
    mov rdi, temp_users
    mov rcx, size_user_record
    xor al, al
    rep stosb
    
    mov rdi, str_error
    call print_string_new
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function add_user
    
    
    
    
    
list_all_users:
; Takes no parameters (users is global)
; Lists full details of all users in the array
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    lea rsi, [users] ; load base address of the users array into RSI. In other words, RSI points to the users array.
    mov rcx, [current_number_of_users] ; we will use RCX for the counter in our loop

    ;this is the start of our loop
  .start_loop:
    cmp rcx, 0
    je .finish_loop ; if the counter is a zero then we have finished our loop
    ;display the user record
    mov rdi, rsi ; put the pointer to the current record in RDI, to pass to the print_string_new function
    
    ;display ID
   
    mov rdi, display_staff
    call print_string_new

    mov rdi, display_staff_letter_p
    call print_string_new
    
    
    mov edi, [rsi] ; move the pointer along by 129 bytes from the base address of the record (combined size of the forename and surname strings, and age) 
    call print_uint_new
    call print_nl_new
    
    ;display forename
    mov rdi, display_name
    call print_string_new
  
    lea rdi, [rsi + size_id] ; move the pointer along by 64 bytes from the base address of the record (the size of the forename string)
    call print_string_new
    mov rdi,' ' ; space character, between forename and surname.
    call print_char_new ; print a space
    
    ;display surname
    lea rdi, [rsi + size_id+size_forename] ; move the pointer along by 64 bytes from the base address of the record (the size of the forename string)
    call print_string_new
    call print_nl_new
    
    ;display year
    mov rdi, display_year
    call print_string_new
    
    movzx rdi, WORD[rsi + size_id+size_forename+size_surname] ; dereferrence [RSI + 128] into RDI. 128 bytes is the combined size of the forename and surname strings. ;We need to zero extend (movzx) because the age in memory is one byte and the RDI register is 8 bytes.
    mov rbx, rdi  
    call print_uint_new ; print the age
    call print_nl_new
    
    ;display salary
    mov rdi, display_salary
    call print_string_new
    
    mov edi, DWORD[rsi + size_id+size_forename+size_surname+size_year_of_joining] ; dereferrence [RSI + 128] into RDI. 128 bytes is the combined size of the forename and surname strings.
    mov rax, current_year
    
    call print_uint_new ; print the age
    call print_nl_new
    
    ; display department
    mov rdi, display_dept
    call print_string_new
    
    lea rdi, [rsi + size_id+size_forename+size_surname+size_year_of_joining+size_salary] ; move the pointer along by 129 bytes from the base address of the record (combined size of the forename and surname strings, and age) 
    call print_string_new
    call print_nl_new
    
    ; display email
    mov rdi, display_email
    call print_string_new
    
    lea rdi, [rsi + size_id+size_forename+size_surname+size_year_of_joining+size_salary+size_dept] ; move the pointer along by 129 bytes from the base address of the record (combined size of the forename and surname strings, and age) 
    call print_string_new
    call print_nl_new
    
    
    ; next user
    call print_nl_new
    add rsi, size_user_record ; move the address to point to the next record in the array
    dec rcx ; decrement our counter variable
    jmp .start_loop ; jump back to the start of the loop (unconditional jump)
  .finish_loop:

    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx
    ret ; End function list_all_users
    
display_number_of_users:
; No parameters
; Displays number of users in list (to STDOUT)
    push rdi
    mov rdi, str_number_of_users
    call print_string_new
    mov rdi, [current_number_of_users]
    call print_uint_new
    call print_nl_new
    pop rdi    
    ret ; End function display_number_of_users

display_main_menu:
; No parameters
; Prints main menu
    push rdi
    mov rdi, str_main_menu
    call print_string_new
    pop rdi
    ret ; End function display_main_menu

string_length:
    push rcx
    push rbx
    push rdi
    sub rcx,rcx			; this sets the max size to look for to be
    not rcx			; the maximum memory size
    mov al, 0 ; We want to look for the byte 0, null terminator
    mov rdi, rbx		; set the start of the string
    cld
    repne scasb			; search
    sub rdi, rbx		; we need to take off the start of the string
    dec rdi			; and allow for the null terminator
    mov rax, rdi
    
    pop rdi
    pop rbx
    pop rcx
    ret

main: 
    mov rbp, rsp; for correct debugging
    ; We have these three lines for compatability only
    push rbp
    mov rbp, rsp
    sub rsp,32
    
  .menu_loop:
    call display_main_menu
    call read_int_new ; menu option (number) is in RAX
    mov rdx, rax ; store value in RDX
    ; Print the selected option back to the user
    mov rdi, str_option_selected
    call print_string_new
    mov rdi, rdx
    call print_int_new
    call print_nl_new
    ; Now jump to the correct option
    cmp rdx, 1
    je .option_1
    cmp rdx, 2
    je .option_2
    cmp rdx, 3
    je .option_3
    cmp rdx, 4
    je .option_4
    ; If we get here, the option was invalid. Display error and loop back to input option.
    mov rdi, str_invalid_option
    call print_string_new
    jmp .menu_loop

  .option_1: ; 1. Add User
    ; Check that the array is not full    
    mov rdx, [current_number_of_users] ; This is indirect, hence [] to dereference
    cmp rdx, max_num_users ; Note that max_num_users is an immediate operand since it is defined at build-time
    jl .array_is_not_full ; If current_number_of_users < max_num_users then array is not full, so add new user.
    mov rdi, str_array_full ; display "array is full" message and loop back to main menu
    call print_string_new
    jmp .menu_loop
  .array_is_not_full:
    call add_user
    jmp .menu_loop
    
  .option_2: ; 2. List All Users
    call display_number_of_users
    call print_nl_new
    call list_all_users
    jmp .menu_loop
    
  .option_3: ; 3. Count Users
    call display_number_of_users
    jmp .menu_loop 
    
  .option_4: ; 4. Exit
    ; In order to exit the program we just display a message and return from the main function.
    mov rdi, str_program_exit
    call print_string_new

    xor rax, rax ; return zero
    ; and these lines are for compatability
    add rsp, 32
    pop rbp
    
    ret ; End function main