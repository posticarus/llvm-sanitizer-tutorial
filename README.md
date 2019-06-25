# llvm-sanitizer-tutorial

This is a tutorial on how to build an LLVM sanitizer. 

# Background 
An LLVM sanitizer is a powerful tool used to instrument and analyze programs. This github repo holds an example sanitizer and step by step docuemtation to integrate a sanitizer into the toolchain. This sanitizer can serve as a template towards building more complex tools. For more information on what sanitizers are, see the related blogpost: 

URL

# Quickstart: Building the toolchain & running a sanitizer 

There are three patch files in this repo, one for LLVM, clang, and compiler-rt. The install script will download version 8, apply the patches, and put the new files in their appropriate locations. 

```
EDIT THIS HAS TO CHANGE CUZ WE DOIN PATCH FILES
#Clone the repo
git clone https://github.com/trailofbits/llvm-sanitizer-tutorial.git && cd llvm-sanitizer-tutorial/llvm 
#Make the build dir 
mkdir build && cd build 
#configure and build, there are a lot of configuration options for LLVM
cmake -DLLVM_TARGETS_TO_BUILD="X86" .. && make
cd bin && ./clang -fsanitize=testsan -g -o malloc_target ../../../target_programs/malloc_target.c
./malloc_target
```
You should see output from the LLVM pass and additional output from the runtime component when the program is executed. Most of this readme will be from the blogpost above, but in this repo im going to list all the tedious technical details that didn't make it past editing. Note that this post only covers on how to build a sanitizer for Linux. 

# Building an out of source pass 
Why build out of source first? Building your instrumentation pass out of source is a good first step when building your sanitizer. This allows you to debug your pass and determine if it's functioning correctly. When building the LLVM tool chain, you can use the `opt` tool to run your pass on bitcode and use the `llvm-dis` tool to view the actual IR. 

```
./clang -c -emit-llvm ../../../target_programs/malloc_target.c -o malloc_target.bc
./opt -load ../lib/LLVMTestPass.so -testfunc < malloc_target.bc > malloc_instrumented.bc 
./llvm-dis < malloc_instrumented.bc | less
```

The first thing is to create your pass, check out `llvm/lib/Transform/TestPass/TestPass.cpp` for the code I'm going to be referencing. The LLVM module is the largest unit of compilation, it essentially represents the file. The function and basic block passes operate at those respective levels. The module pass just prints out the function names, the function pass instruments function entries, and the basic block pass inserts function calls after malloc. These function symbols will be defined inside of our runtime component. At the bottom of the file there is a few lines of code to register the pass with `opt`. Later on these will be removed and replaced with functions that create the pass object. These functions will be called by the LLVM pass manager when your specify your sanitizer to clang. To build this module create a new directory in `llvm/lib/Transforms/` and use the `add_llvm_library` macro. You can copy the TestPass or the Hello cmake files for reference. 

# Building a runtime component 
Sanitizer runtimes are located in `llvm/projects/compiler-rt/lib/`. The sanitizer runtime component supplies runtime functions that the transformation pass will call into. In the testsan directory, there is an example runtime that defines some functions and shows how to use the interceptor interface. The actual mechanics of the `INTERCEPTOR` macro differs based on the OS, on Linux it replaces the symbol address and uses dlsym to resolve the real function address. There are a two other things to take note of in this example. 
* The macro `SANITIZER_INTERFACE` tells compiler-rt that it needs to export that function symbol because it might be called by the instrumented program. 
* The init function contains macro magic, it's designed to run immediately upon being loaded. This is either done by placing the function in the `.pre_init` array or with the `constructor` attribute. 

There are a few steps required to build the runtime component. Look at the `testsan` cmake file for an example reference on how to use these cmake macros. If you are building on linux you can probably just copy it and replace testsan with the name of your sanitizer. If there is confusion the macros are defined in `compiler-rt/cmake`. 

* Create a directory for your source in `llvm/projects/compiler-rt/lib/`
* In the cmake file you need to 
  * Add the component to compiler-rt 
  * Use the add_compiler_rt_runtime macro to add your runtime
    * Make sure to include the RTCommon libs and interceptor lib if you use them.
  * Use add_sanitizer_rt_symbols to generate the interface symbols 
  
The next step is modifying the `compiler-rt/cmake/config-ix.make`. This is apart of the compiler-rt build system and sets variables for your sanitizer to decide if your component could be built by checking to see what operating system and architectures you set. The file is actually rather large, feel free to search for TESTSAN and testsan to find the right places. 
* add your sanitizer name to the list of all sanitizers. The cmake file in the lib directory iterates over the sanitizers in this list to decide which ones to try and build.
* define your sanitizers supported architectures (X86, X86_64) 
* check if the operating system is supported for your architecture and set build flag to true 

At this point you should be able to build your runtime pass by just attempting to build the toolchain. 

# Defining the sanitizer/Modifying the driver 
These steps are what you need to do to define the sanitizer and set up the compiler driver to be ready for integration. 
* In `llvm/tools/clang/include/Basic/Sanitizers.def` add your sanitizers using the macro like all the others. 
* In `llvm/tools/clang/`

# Integrating a pass 


# Integrating a runtime component 

# Some other things I learned 
Your IR passes will be operating system agnostic but other parts of the toolchain are not. When integrating your sanitizer you will have to perform different build operations for OSX/Windows etc. For example in this tutorial we statically linked the runtime to  Fortunately compiler-rt hides a lot of the nastiness from you. I reccomend trying to use the sanitizer runtime interface as much as possible so you can run on as many operating systems without getting a headache.

If you are having issues with some of the cmake build systems I would double check to see you didn't make any typos. For example if you put the architecture as ${x86}, it needs to be ${X86} etc etc. 

Overall this winternship was a great experience, and I hope that this repo documents what I learned so the rest of you can build sanitizers without needing to comb through the toolchain. Below are some of the helpful resources I linked in the blogpost, they are all really great. 

# Helpful resources 
link the dam blogpost again lol <br/>
eli's awesome stuff <br/>
adrians awesome stuff <br/>
llvm conference awesome stuff <br/>  
llvm class references   
