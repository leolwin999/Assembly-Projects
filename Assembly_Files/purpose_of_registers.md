# Why do registers have different purposes here?  
  
This is a critical concept in assembly. The purpose of a register depends entirely on the system call you are making.  
  
The registers (rdi, rsi, rdx, etc.) are just general-purpose containers for numbers. It's the System Call ABI (Application Binary Interface) that defines **what the kernel expects to find in each register** for a specific syscall.  
  
Think of it like a form you have to fill out. For the write syscall, the fields are:  
- rdi: File Descriptor (Where to write?)
- rsi: Buffer Address (What to write?)
- rdx: Count (How much to write?)  
  
For the open syscall, the fields are **completely different**:  
- rdi: Filename Address (What's the file's name?)
- rsi: Flags (How should I open it?)
- rdx: Mode (What permissions should it have if I create it?)  
  
So, registers don't have a fixed universal purpose like "size" or "source." Their meaning is **defined by the rax value (the syscall number)** you set just before calling syscall.
