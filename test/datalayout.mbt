///|
test "DataLayout Alloc Size Basic Type" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let datalayout = mod.getDataLayout()
  let i1ty = ctx.getInt1Ty()
  assert_eq(datalayout.getTypeAllocSize(i1ty), 1)
  let i8ty = ctx.getInt8Ty()
  assert_eq(datalayout.getTypeAllocSize(i8ty), 1)
  let i16ty = ctx.getInt16Ty()
  assert_eq(datalayout.getTypeAllocSize(i16ty), 2)
  let i32ty = ctx.getInt32Ty()
  assert_eq(datalayout.getTypeAllocSize(i32ty), 4)
  let i64ty = ctx.getInt64Ty()
  assert_eq(datalayout.getTypeAllocSize(i64ty), 8)
  let f32ty = ctx.getFloatTy()
  assert_eq(datalayout.getTypeAllocSize(f32ty), 4)
  let f64ty = ctx.getDoubleTy()
  assert_eq(datalayout.getTypeAllocSize(f64ty), 8)
  let arrty = ctx.getArrayType(i32ty, 4)
  assert_eq(datalayout.getTypeAllocSize(arrty), 16)
}

///|
test "DataLayout Alloc Size Struct Type" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let arrty = ctx.getArrayType(i32ty, 4)
  let struct1 = ctx.getStructType([i32ty, f64ty, i32ty])
  assert_eq(datalayout.getTypeAllocSize(struct1), 24)
  let struct2 = ctx.getStructType([i8ty, i32ty, arrty])
  assert_eq(datalayout.getTypeAllocSize(struct2), 24)
}

///|
test "DataLayout Edge Cases" {
  let ctx = Context::new()
  let mod = ctx.addModule("edge_cases")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f64ty = ctx.getDoubleTy()

  // Test empty struct - should be 0 size
  let empty_struct = ctx.getStructType([], name="empty")
  assert_eq(datalayout.getTypeAllocSize(empty_struct), 0)

  // Test single element structs
  let single_i8 = ctx.getStructType([i8ty])
  assert_eq(datalayout.getTypeAllocSize(single_i8), 1)
  let single_i32 = ctx.getStructType([i32ty])
  assert_eq(datalayout.getTypeAllocSize(single_i32), 4)
  let single_f64 = ctx.getStructType([f64ty])
  assert_eq(datalayout.getTypeAllocSize(single_f64), 8)

  // Test alignment requirements
  // [i8, i64] - i64 needs 8-byte alignment
  let align_test1 = ctx.getStructType([i8ty, i64ty])
  assert_eq(datalayout.getTypeAllocSize(align_test1), 16) // 1 + 7 padding + 8 = 16

  // [i16, i64] - i64 needs 8-byte alignment  
  let align_test2 = ctx.getStructType([i16ty, i64ty])
  assert_eq(datalayout.getTypeAllocSize(align_test2), 16) // 2 + 6 padding + 8 = 16

  // [i32, i64] - i64 needs 8-byte alignment
  let align_test3 = ctx.getStructType([i32ty, i64ty])
  assert_eq(datalayout.getTypeAllocSize(align_test3), 16) // 4 + 4 padding + 8 = 16

  // Test multiple small fields requiring padding
  // [i8, i8, i32] - i32 needs 4-byte alignment
  let padding_test1 = ctx.getStructType([i8ty, i8ty, i32ty])
  assert_eq(datalayout.getTypeAllocSize(padding_test1), 8) // 1 + 1 + 2 padding + 4 = 8

  // [i8, i8, i8, i32] - i32 needs 4-byte alignment  
  let padding_test2 = ctx.getStructType([i8ty, i8ty, i8ty, i32ty])
  assert_eq(datalayout.getTypeAllocSize(padding_test2), 8) // 1 + 1 + 1 + 1 padding + 4 = 8

  // Test complex nested alignment
  // [i8, f64, i8] - f64 needs 8-byte alignment
  let complex_test1 = ctx.getStructType([i8ty, f64ty, i8ty])
  assert_eq(datalayout.getTypeAllocSize(complex_test1), 24) // 1 + 7 padding + 8 + 1 + 7 padding = 24

  // Test arrays in structs
  let arr_i8_4 = ctx.getArrayType(i8ty, 4)
  let arr_test1 = ctx.getStructType([i32ty, arr_i8_4])
  assert_eq(datalayout.getTypeAllocSize(arr_test1), 8) // 4 + 4 = 8
  let arr_i64_2 = ctx.getArrayType(i64ty, 2)
  let arr_test2 = ctx.getStructType([i8ty, arr_i64_2])
  assert_eq(datalayout.getTypeAllocSize(arr_test2), 24) // 1 + 7 padding + 16 = 24
}

///|
test "DataLayout Packed Structs" {
  let ctx = Context::new()
  let mod = ctx.addModule("packed")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Test packed structs - no padding between fields
  let packed_struct1 = ctx.getStructType([i8ty, i32ty], isPacked=true)
  assert_eq(datalayout.getTypeAllocSize(packed_struct1), 5) // 1 + 4 = 5 (no padding)
  let packed_struct2 = ctx.getStructType([i8ty, i64ty], isPacked=true)
  assert_eq(datalayout.getTypeAllocSize(packed_struct2), 9) // 1 + 8 = 9 (no padding)
  let packed_struct3 = ctx.getStructType([i8ty, i32ty, i8ty], isPacked=true)
  assert_eq(datalayout.getTypeAllocSize(packed_struct3), 6) // 1 + 4 + 1 = 6 (no padding)
}

///|
test "DataLayout Nested Structs" {
  let ctx = Context::new()
  let mod = ctx.addModule("nested")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Create inner structs
  let inner1 = ctx.getStructType([i8ty, i32ty]) // size 8: 1 + 3 padding + 4 = 8
  let inner2 = ctx.getStructType([i64ty, i8ty]) // size 16: 8 + 1 + 7 padding = 16

  // Test nested struct alignment
  // struct { inner1, i8 } where inner1 has alignment 4
  let nested1 = ctx.getStructType([inner1, i8ty])
  assert_eq(datalayout.getTypeAllocSize(nested1), 12) // 8 + 1 + 3 padding = 12

  // struct { i8, inner1 } - inner1 needs 4-byte alignment
  let nested2 = ctx.getStructType([i8ty, inner1])
  assert_eq(datalayout.getTypeAllocSize(nested2), 12) // 1 + 3 padding + 8 = 12

  // struct { inner2, i32 } where inner2 has alignment 8
  let nested3 = ctx.getStructType([inner2, i32ty])
  assert_eq(datalayout.getTypeAllocSize(nested3), 24) // 16 + 4 + 4 padding = 24

  // struct { i8, inner2 } - inner2 needs 8-byte alignment
  let nested4 = ctx.getStructType([i8ty, inner2])
  assert_eq(datalayout.getTypeAllocSize(nested4), 24) // 1 + 7 padding + 16 = 24

  // Test struct containing nested structs
  let complex_nested = ctx.getStructType([inner1, inner2, i8ty])
  assert_eq(datalayout.getTypeAllocSize(complex_nested), 32) // 8 + 16 + 1 + 7 padding = 32
}

///|
test "DataLayout Array Types" {
  let ctx = Context::new()
  let mod = ctx.addModule("arrays")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f64ty = ctx.getDoubleTy()

  // Test basic array sizes
  let i8_array_10 = ctx.getArrayType(i8ty, 10)
  assert_eq(datalayout.getTypeAllocSize(i8_array_10), 10) // 1 * 10 = 10
  let i32_array_5 = ctx.getArrayType(i32ty, 5)
  assert_eq(datalayout.getTypeAllocSize(i32_array_5), 20) // 4 * 5 = 20
  let i64_array_3 = ctx.getArrayType(i64ty, 3)
  assert_eq(datalayout.getTypeAllocSize(i64_array_3), 24) // 8 * 3 = 24
  let f64_array_4 = ctx.getArrayType(f64ty, 4)
  assert_eq(datalayout.getTypeAllocSize(f64_array_4), 32) // 8 * 4 = 32

  // Test zero-sized arrays
  let zero_array = ctx.getArrayType(i32ty, 0)
  assert_eq(datalayout.getTypeAllocSize(zero_array), 0) // 4 * 0 = 0

  // Test single element arrays
  let single_i64 = ctx.getArrayType(i64ty, 1)
  assert_eq(datalayout.getTypeAllocSize(single_i64), 8) // 8 * 1 = 8

  // Test arrays of structs
  let struct_ty = ctx.getStructType([i8ty, i32ty]) // size 8
  let struct_array = ctx.getArrayType(struct_ty, 3)
  assert_eq(datalayout.getTypeAllocSize(struct_array), 24) // 8 * 3 = 24

  // Test multidimensional arrays (array of arrays)
  let inner_array = ctx.getArrayType(i16ty, 4) // size 8
  let outer_array = ctx.getArrayType(inner_array, 3)
  assert_eq(datalayout.getTypeAllocSize(outer_array), 24) // 8 * 3 = 24
}

///|
test "DataLayout Struct Offset Basic" {
  let ctx = Context::new()
  let mod = ctx.addModule("offset_basic")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Test basic offset calculation
  // struct { i8, i32, i16 } - with alignment padding
  let basic_struct = ctx.getStructType([i8ty, i32ty, i16ty])

  // Field offsets:
  // i8:  offset 0
  // i32: offset 4 (aligned to 4 bytes)
  // i16: offset 8 (aligned to 2 bytes)
  assert_eq(datalayout.getStructTypeOffset(basic_struct, 0), 0) // i8 at offset 0
  assert_eq(datalayout.getStructTypeOffset(basic_struct, 1), 4) // i32 at offset 4
  assert_eq(datalayout.getStructTypeOffset(basic_struct, 2), 8) // i16 at offset 8

  // Test struct with larger alignment requirements
  // struct { i8, i64, i8 }
  let align_struct = ctx.getStructType([i8ty, i64ty, i8ty])

  // Field offsets:
  // i8:  offset 0
  // i64: offset 8 (aligned to 8 bytes)
  // i8:  offset 16
  assert_eq(datalayout.getStructTypeOffset(align_struct, 0), 0) // i8 at offset 0
  assert_eq(datalayout.getStructTypeOffset(align_struct, 1), 8) // i64 at offset 8
  assert_eq(datalayout.getStructTypeOffset(align_struct, 2), 16) // i8 at offset 16
}

///|
test "DataLayout Struct Offset Packed vs Non-Packed" {
  let ctx = Context::new()
  let mod = ctx.addModule("offset_packed")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Test non-packed struct
  let normal_struct = ctx.getStructType([i8ty, i32ty, i64ty])

  // Non-packed offsets (with alignment):
  // i8:  offset 0
  // i32: offset 4 (aligned to 4 bytes)
  // i64: offset 8 (aligned to 8 bytes)
  assert_eq(datalayout.getStructTypeOffset(normal_struct, 0), 0) // i8
  assert_eq(datalayout.getStructTypeOffset(normal_struct, 1), 4) // i32
  assert_eq(datalayout.getStructTypeOffset(normal_struct, 2), 8) // i64

  // Test packed struct (no alignment padding)
  let packed_struct = ctx.getStructType([i8ty, i32ty, i64ty], isPacked=true)

  // Packed offsets (no alignment):
  // i8:  offset 0
  // i32: offset 1 (no alignment)
  // i64: offset 5 (no alignment)
  assert_eq(datalayout.getStructTypeOffset(packed_struct, 0), 0) // i8
  assert_eq(datalayout.getStructTypeOffset(packed_struct, 1), 1) // i32
  assert_eq(datalayout.getStructTypeOffset(packed_struct, 2), 5) // i64
}

///|
test "DataLayout Struct Offset Complex Alignment" {
  let ctx = Context::new()
  let mod = ctx.addModule("offset_complex")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f64ty = ctx.getDoubleTy()

  // Test complex struct with multiple alignment requirements
  // struct { i8, i16, i8, i32, i8, i64, i8, f64 }
  let complex_struct = ctx.getStructType([
    i8ty, i16ty, i8ty, i32ty, i8ty, i64ty, i8ty, f64ty,
  ])

  // Expected offsets:
  // i8:  offset 0
  // i16: offset 2 (aligned to 2 bytes, skip 1 byte)
  // i8:  offset 4 
  // i32: offset 8 (aligned to 4 bytes, skip 3 bytes)
  // i8:  offset 12
  // i64: offset 16 (aligned to 8 bytes, skip 3 bytes)
  // i8:  offset 24
  // f64: offset 32 (aligned to 8 bytes, skip 7 bytes)
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 0), 0) // i8
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 1), 2) // i16
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 2), 4) // i8
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 3), 8) // i32
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 4), 12) // i8
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 5), 16) // i64
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 6), 24) // i8
  assert_eq(datalayout.getStructTypeOffset(complex_struct, 7), 32) // f64
}

///|
test "DataLayout Struct Offset Nested Structs" {
  let ctx = Context::new()
  let mod = ctx.addModule("offset_nested")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Create inner structs
  let inner1 = ctx.getStructType([i8ty, i32ty]) // size 8, align 4
  let inner2 = ctx.getStructType([i64ty, i8ty]) // size 16, align 8

  // Test nested struct offsets
  // struct { inner1, i8, inner2 }
  let nested_struct = ctx.getStructType([inner1, i8ty, inner2])

  // Expected offsets:
  // inner1: offset 0
  // i8:     offset 8
  // inner2: offset 16 (aligned to 8 bytes, skip 7 bytes)
  assert_eq(datalayout.getStructTypeOffset(nested_struct, 0), 0) // inner1
  assert_eq(datalayout.getStructTypeOffset(nested_struct, 1), 8) // i8  
  assert_eq(datalayout.getStructTypeOffset(nested_struct, 2), 16) // inner2

  // Test another arrangement
  // struct { i8, inner1, inner2 }
  let nested_struct2 = ctx.getStructType([i8ty, inner1, inner2])

  // Expected offsets:
  // i8:     offset 0
  // inner1: offset 4 (aligned to 4 bytes, skip 3 bytes)
  // inner2: offset 16 (aligned to 8 bytes, skip 4 bytes)
  assert_eq(datalayout.getStructTypeOffset(nested_struct2, 0), 0) // i8
  assert_eq(datalayout.getStructTypeOffset(nested_struct2, 1), 4) // inner1
  assert_eq(datalayout.getStructTypeOffset(nested_struct2, 2), 16) // inner2
}

///|
test "DataLayout Struct Offset Edge Cases" {
  let ctx = Context::new()
  let mod = ctx.addModule("offset_edge")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()

  // Test boundary conditions
  let test_struct = ctx.getStructType([i8ty, i32ty, i8ty])

  // Test invalid indices
  assert_eq(datalayout.getStructTypeOffset(test_struct, -1), 0) // negative index
  assert_eq(datalayout.getStructTypeOffset(test_struct, 3), 0) // out of bounds
  assert_eq(datalayout.getStructTypeOffset(test_struct, 10), 0) // way out of bounds

  // Test empty struct
  let empty_struct = ctx.getStructType([], name="empty_offset")
  assert_eq(datalayout.getStructTypeOffset(empty_struct, 0), 0) // empty struct

  // Test single element struct
  let single_struct = ctx.getStructType([i32ty])
  assert_eq(datalayout.getStructTypeOffset(single_struct, 0), 0) // single element at 0
  assert_eq(datalayout.getStructTypeOffset(single_struct, 1), 0) // out of bounds
}
