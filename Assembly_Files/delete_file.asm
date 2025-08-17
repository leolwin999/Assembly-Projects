section .data
        filename db "file_to_be_deleted.txt", 0                         ; The filename to delete

        success_msg db "Successfully deleted the file!", 0xA            ; Message for success
        success_msg_len equ $ - success_msg                             ; Message length

        error_msg db "Error occurred! Does the file really exist?"      ; Error message
        error_msg_len equ $ - error_msg                                 ; Message length

section .text
        global _start                                                   ; Make the entry point visible to the linker

_start:
        mov rax, 87                                                     ; Syscall number for "unlink"
        mov rdi, filename                                               ; 1st arg: address of the filename
        syscall                                                         ; Call kernel
                                                                        ; rax will be 0 on success or negative if error

        cmp rax, 0                                                      ; Compare the return value in rax with 0.
        jl _error_unlink                                                ; If rax is less than 0, jump to error handler

        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for stdout
        mov rsi, success_msg                                            ; Address of the success message
        mov rdx, success_msg_len                                        ; Message length
        syscall                                                         ; Call kernel

        jmp _exit                                                       ; Jump to the clean exit

_error_unlink:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for stdout
        mov rsi, error_msg                                              ; Address of the error message
        mov rdx, error_msg_len                                          ; Message length
        syscall                                                         ; Call kernel

        jmp _exit_error                                                 ; Jump to error exit

_exit:
        mov rax, 60                                                     ; Syscall number for exit
        xor rdi, rdi                                                    ; Exit code 0 for success
        syscall                                                         ; Call kernel

_exit_error:
        mov rax, 60                                                     ; Syscall number for exit
        mov rdi, 1                                                      ; Exit code 1 to indicate an error occurred
        syscall                                                         ; Call kernel

; Quick glance on how unlik works: 

; The unlink system call in Linux deletes a name from the filesystem. Its operation depends on whether the name refers to a regular file, a symbolic link, or if the file has multiple hard links or is currently open by a process.

; Decrements Link Count:
; When unlink is called on a file, it primarily removes the directory entry (the "link") that points to the file's inode. This action decrements the file's "link count," which tracks how many directory entries point to that specific inode.

; File Deletion (if link count becomes zero):
; If the link count becomes zero after unlink is called, and no processes currently have the file open, the file's data blocks are marked as free in the filesystem, making the space available for reuse. The inode itself is also freed. This effectively deletes the file. 

; File Deletion (if file is open):
; If the link count becomes zero but one or more processes still have the file open (e.g., a program is reading from or writing to it), the file's data and inode are not immediately freed. Instead, the file remains in existence until the last process that has it open closes its file descriptor. Only then is the file truly deleted and its resources reclaimed.

;-----------------------------------------------------

; What are inodes in linux?
;Inodes, short for index nodes, are a fundamental data structure in Unix-style file systems, including those used in Linux. They serve as a unique identifier and store crucial metadata about every file and directory within a specific file system.

; Key aspects of inodes:
; Metadata Storage:
; Inodes hold information about a file or directory, such as:
; - File type (e.g., regular file, directory, symbolic link)
; - Permissions (read, write, execute for owner, group, others)
; - Owner ID and Group ID
; - File size
; - Timestamps (last access, last modification, last change)
; - Number of hard links pointing to the inode
; - Pointers to the disk blocks where the actual file data is stored.
