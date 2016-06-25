using Rust
using Base.Test
using Base.Libdl

# write your own tests here
@testset "Compile code string" begin
    rustlib = compile_code("""
        extern crate libc;
        use libc::uint32_t;

        #[no_mangle]
        pub extern fn addition(a: uint32_t, b: uint32_t) -> uint32_t {
           a + b
        }
    """)

    addition = dlsym(rustlib, :addition)
    @test UInt32(UInt32(2) + UInt32(10)) === ccall(addition, UInt32, (UInt32, UInt32), 2, 10)
end
