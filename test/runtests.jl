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
    @test addition != C_NULL
    @test UInt32(UInt32(2) + UInt32(10)) === ccall(addition, UInt32, (UInt32, UInt32), 2, 10)
end

@testset "Compile Julia function" begin
    @testset "Emission" begin
        function addition(a::UInt32, b::UInt32)
            a + b
        end

        name, emission = Rust.AST.generate_rust(addition, (UInt32, UInt32))
        @test isa(emission, String)
        @test name == "addition"
    end

    @testset "Compilation" begin
        function addition(a::UInt32, b::UInt32)
            a + b
        end

        addition = compile_function(addition, (UInt32, UInt32))

        @test addition != C_NULL
        @test UInt32(UInt32(2) + UInt32(10)) === ccall(addition, UInt32, (UInt32, UInt32), 2, 10)
    end

    @testset "Every function" begin
        function everything(a::UInt32, b::UInt32)
            (b >> a * b + div(b, a) * (a % b) - a | b) + (a & b + (~b $ a))
        end

        everything_rust = compile_function(everything, (UInt32, UInt32))

        @test everything_rust != C_NULL
        @test everything(UInt32(2), UInt32(10)) === ccall(everything_rust, UInt32, (UInt32, UInt32), 2, 10)
    end
end
