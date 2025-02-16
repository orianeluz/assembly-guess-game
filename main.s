/* 326367570 orian eluz */
.section .data
.globl seed_integer
seed_integer:
    .long 0    # this is the seed value entered by the user

.globl random_integer
random_integer:
    .long 0    # this is the random number generated between 0 and n 

.globl guess_integer
guess_integer:
    .long 0    # number guessed by the user 

.globl max_n
max_n:
    .long 10   # max random number 

.globl max_attempts
max_attempts:
    .long 5    # maximum guesses  m = 5

.globl rounds_won
rounds_won:
    .long 0    # counter of rounds the user won

.globl read_char
read_char:
    .byte 0    # user response to double or nothing

.globl easy_mode
easy_mode:
    .byte 0    # flag to tell if easy mode y or n

.section .rodata
prompt_seed_msg:
    .string "Enter configuration seed: "  # ask user for the seed

scanf_fmt:
    .string "%d"    # reading integers

user_guess_msg:
    .string "What is your guess? "  # ask user for their guess

user_incorrect_msg:
    .string "Incorrect. "  # message for incorrect guesses

user_lost_msg:
    .string "\nGame over, you lost :(. The correct answer was %d\n"  # message when the user loses

double_prompt_msg:
    .string "Double or nothing! Would you like to continue to another round? (y/n) "  # ask user if they want to continue

final_message:
    .string "Congratz! You won %d rounds!\n"  # final message 
easy_mode_prompt_msg:
    .string "Would you like to play in easy mode? (y/n) "  # ask user if he want easy mode

guess_below_msg:
    .string "Your guess was below the actual number ...\n"  # message when guess is too low

guess_above_msg:
    .string "Your guess was above the actual number ...\n"  # message when guess is too high

scanf_char:
    .string " %c"    # reading a character

.section .text
.globl main
.type main, @function
main:
    
    pushq %rbp                 
    movq %rsp, %rbp            

    # initialize the rounds won counter to 0
    movl $0, rounds_won(%rip)  

.round_start:
    # ask user to enter the seed value 
    movq $prompt_seed_msg, %rdi
    xorq %rax, %rax
    call printf

    # read the seed value 
    movq $scanf_fmt, %rdi
    movq $seed_integer, %rsi
    xorq %rax, %rax
    call scanf

    # ask if the user wants easy mode
    movq $easy_mode_prompt_msg, %rdi
    xorq %rax, %rax
    call printf

    # read the user choice for easy mode
    movq $scanf_char, %rdi
    movq $easy_mode, %rsi
    xorq %rax, %rax
    call scanf

    # set the random seed and generate random number
    movl seed_integer(%rip), %edi  # use the seed
    call srand                      # initialize the random number generator
    xorq %rax, %rax
    call rand                       # generate a random number
    movl max_n(%rip), %ecx          # value of n
    xorl %edx, %edx                 # clear edx for division
    idivl %ecx                      # divide rand by n save the remainder
    movl %edx, %eax                 # move remainder to eax
    addl $1, %eax                   
    movl %eax, random_integer(%rip) # store the random number

    # initialize attempts counter
    movl $0, %r15d                  

.guess_loop:
    # check if user has used all attempts (m = 5)
    cmpl max_attempts(%rip), %r15d  
    je .game_over                    # if attempts >= m the user loses

    # ask user for his guess
    movq $user_guess_msg, %rdi
    xorq %rax, %rax
    call printf

    # read the guess from the user
    movq $scanf_fmt, %rdi
    movq $guess_integer, %rsi
    xorq %rax, %rax
    call scanf

    # compare the user guess to the random number
    movl random_integer(%rip), %eax
    movl guess_integer(%rip), %ebx
    cmpl %eax, %ebx
    je .correct_guess  # jump to correct guess if they match

    # easy mode is on
    movb $'y', %al
    cmpb easy_mode(%rip), %al
    jne .not_easy_mode

    # print incorrect message
    movq $user_incorrect_msg, %rdi
    xorq %rax, %rax
    call printf

    # in easy mode tell user if guess is below the number
    movl guess_integer(%rip), %eax
    cmpl random_integer(%rip), %eax
    jl .print_below
    
    # print above message
    movq $guess_above_msg, %rdi
    xorq %rax, %rax
    call printf
    jmp .increment_attempts

.print_below:
    # print below message
    movq $guess_below_msg, %rdi
    xorq %rax, %rax
    call printf
    jmp .increment_attempts

.not_easy_mode:
    # print incorrect message if not in easy mode
    movq $user_incorrect_msg, %rdi
    xorq %rax, %rax
    call printf
    jmp .increment_attempts

.increment_attempts:
    # increment attempts counter and return to the loop
    incl %r15d                      # increment the attempts counter
    jmp .guess_loop                 # go to the main loop   
.correct_guess:
    # increment the rounds won counter
    incl rounds_won(%rip)       

    # ask user if they want to play double or nothing
    movq $double_prompt_msg, %rdi
    xorq %rax, %rax
    call printf

    # read the user choice for double or nothing
    movq $scanf_char, %rdi
    movq $read_char, %rsi
    xorq %rax, %rax
    call scanf

    movb $'y', %al
    cmpb read_char(%rip), %al
    jne .win_round

    # update seed and n for double or nothing
    movl seed_integer(%rip), %eax
    addl %eax, %eax                # seed = seed * 2
    movl %eax, seed_integer(%rip)

    movl max_n(%rip), %eax
    addl %eax, %eax                # n = n * 2
    movl %eax, max_n(%rip)

    movl seed_integer(%rip), %edi
    call srand                     # reseed the random number generator

    # Generate a new random number
    call rand
    movl max_n(%rip), %ebx
    xorl %edx, %edx
    idivl %ebx
    movl %edx, %eax
    addl $1, %eax
    movl %eax, random_integer(%rip)

    # reset the attempts for the new round
    xorl %r15d, %r15d

    jmp .guess_loop

.win_round:
    # print final message
    movq $final_message, %rdi
    movl rounds_won(%rip), %esi
    xorq %rax, %rax
    call printf
    jmp .exit

.game_over:
    # user failed to guess within 5 attempts
    movq $user_lost_msg, %rdi       
    movl random_integer(%rip), %esi 
    xorq %rax, %rax
    call printf

.exit:
    # exit the program
    movq %rbp, %rsp
    popq %rbp
    ret
