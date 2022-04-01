(* The state of SimpleNFS is a map from file handles
(inode numbers) to contents (list of bytes). *)
Definition State := gmap fh (list u8).

Definition write (f : fh) (off : u64)
           (d : list u8) (d0 : list u8)
    : transition State u32 :=
  (* Convert u64 to mathematical integer *)
  let off := int.nat off in
  (* Simplified spec does not allow creating holes,
     but does allow appending *)
  check (off ≤ length d0);
  let d' := d0[:off] ++ d ++ d0[off+length d:] in
  (* Update spec file state *)
  modify (fun s => insert f d' s);
  ret (U32 (length d)).
