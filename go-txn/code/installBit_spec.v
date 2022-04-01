Definition install_one_bit (src dst: u8) (bit: nat) : u8 :=
  let b := byte_to_bits src !!! bit in
  let dst'_bits := <[bit := new_bit]> byte_to_bits dst in
  let dst' := bits_to_byte dst'_bits in
  dst'.
