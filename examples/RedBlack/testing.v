Require Import QuickChick.
Require Import GenLow GenHigh.
Import GenLow GenHigh.
Require Import NPeano.

Require Import ssreflect ssrnat ssrbool eqtype.

Require Import redblack.

Require Import List String.
Import ListNotations.

Open Scope string.

Open Scope Checker_scope.

(* Red-Black Tree invariant: executable definition *)

Fixpoint black_height_bool (t: tree) : option nat :=
  match t with
    | Leaf => Some 0
    | Node c tl _ tr =>
      let h1 := black_height_bool tl in
      let h2 := black_height_bool tr in
      match h1, h2 with
        | Some n1, Some n2 =>
          if n1 == n2 then
            match c with
              | Black => Some (S n1)
              | Red => Some n1
            end
          else None
        | _, _ => None
      end
  end.

Definition is_black_balanced (t : tree) : bool :=
  isSome (black_height_bool t).

Fixpoint has_no_red_red (c : color) (t : tree) : bool :=
  match t with
    | Leaf => true
    | Node Red t1 _ t2 =>
      match c with
        | Red => false
        | Black => has_no_red_red Red t1 && has_no_red_red Red t2
      end
    | Node Black t1 _ t2 =>
      has_no_red_red Black t1 && has_no_red_red Black t2
  end.

(* begin is_redblack_bool *)
Definition is_redblack_bool (t : tree) : bool :=
  is_black_balanced t && has_no_red_red Red t.
(* end is_redblack_bool *)

Fixpoint showColor (c : color) :=
  match c with
    | Red => "Red"
    | Black => "Black"
  end.

Fixpoint tree_to_string (t : tree) :=
  match t with
    | Leaf => "Leaf"
    | Node c l x r => "Node " ++ showColor c ++ " "
                            ++ "(" ++ tree_to_string l ++ ") "
                            ++ show x ++ " "
                            ++ "(" ++ tree_to_string r ++ ")"
  end.

Instance showTree {A : Type} `{_ : Show A} : Show tree :=
  {|
    show t := "" (* CH: tree_to_string t causes a 9x increase in runtime *)
  |}.

(* begin insert_preserves_redblack_checker *)
Definition insert_preserves_redblack_checker (genTree : G tree) : Checker :=
  forAll arbitrary (fun n => forAll genTree (fun t =>
    is_redblack_bool t ==> is_redblack_bool (insert n t))).
(* end insert_preserves_redblack_checker *)

Import QcDefaultNotation. Open Scope qc_scope.

(* begin genAnyTree *)
Definition genColor := elems [Red; Black].
Fixpoint genAnyTree_depth (d : nat) : G tree :=
  match d with 
    | 0 => returnGen Leaf
    | S d' => frequency (returnGen Leaf) 
                     [(1,returnGen Leaf); 
                      (9,liftGen4 Node genColor (genAnyTree_depth d')
                                      arbitrary (genAnyTree_depth d'))]
  end.
Definition genAnyTree : G tree := sized genAnyTree_depth.
(* end genAnyTree *)

Extract Constant defSize => "10".
Extract Constant Test.defNumTests => "10000".
(* begin QC_naive *)
QuickCheck (insert_preserves_redblack_checker genAnyTree).
(* end QC_naive *)
Extract Constant Test.defNumTests => "10000".

Module DoNotation.
Import ssrfun.
Notation "'do!' X <- A ; B" :=
  (bindGen A (fun X => B))
  (at level 200, X ident, A at level 100, B at level 200).
End DoNotation.
Import DoNotation.

Require Import Relations Wellfounded Lexicographic_Product.

Definition ltColor (c1 c2: color) : Prop :=
  match c1, c2 with
    | Red, Black => True
    | _, _ => False
  end.

Lemma well_foulded_ltColor : well_founded ltColor.
Proof.
  unfold well_founded.
  intros c; destruct c;
  repeat (constructor; intros c ?; destruct c; try now (exfalso; auto)).
Qed.

Definition sigT_of_prod {A B : Type} (p : A * B) : {_ : A & B} :=
  let (a, b) := p in existT (fun _ : A => B) a b.

Definition prod_of_sigT {A B : Type} (p : {_ : A & B}) : A * B :=
  let (a, b) := p in (a, b).


Definition wf_hc (c1 c2 : (nat * color)) : Prop :=
  lexprod nat (fun _ => color) lt (fun _ => ltColor) (sigT_of_prod c1) (sigT_of_prod c2).

Lemma well_founded_hc : well_founded wf_hc.
Proof.
  unfold wf_hc. apply wf_inverse_image.
  apply wf_lexprod. now apply Wf_nat.lt_wf. intros _; now apply well_foulded_ltColor.
Qed.

Require Import Program.Wf. Import WfExtensionality.
Require Import FunctionalExtensionality.

(* begin genRBTree_height *)
Program Fixpoint genRBTree_height (hc : nat*color) {wf wf_hc hc} : G tree :=
  match hc with
  | (0, Red) => returnGen Leaf
  | (0, Black) => oneOf [returnGen Leaf;
                    (do! n <- arbitrary; returnGen (Node Red Leaf n Leaf))]
  | (S h, Red) => liftGen4 Node (returnGen Black) (genRBTree_height (h, Black))
                                        arbitrary (genRBTree_height (h, Black))
  | (S h, Black) => do! c' <- genColor;
                    let h' := match c' with Red => S h | Black => h end in
                    liftGen4 Node (returnGen c') (genRBTree_height (h', c'))
                                       arbitrary (genRBTree_height (h', c')) end.
(* end genRBTree_height *)
Next Obligation.
  abstract (unfold wf_hc; simpl; left; omega).
Qed.
Next Obligation.
  abstract (unfold wf_hc; simpl; left; omega).
Qed.
Next Obligation.
  abstract (unfold wf_hc; simpl; destruct c'; [right; apply I | left; omega]).
Qed.
Next Obligation.
  abstract (unfold wf_hc; simpl; destruct c'; [right; apply I | left; omega]).
Qed.
Next Obligation.
  abstract (apply well_founded_hc).
Defined.

Lemma genRBTree_height_eq (hc : nat*color) :
  genRBTree_height hc =
  match hc with
  | (0, Red) => returnGen Leaf
  | (0, Black) => oneOf [returnGen Leaf;
                    (do! n <- arbitrary; returnGen (Node Red Leaf n Leaf))]
  | (S h, Red) => liftGen4 Node (returnGen Black) (genRBTree_height (h, Black))
                                        arbitrary (genRBTree_height (h, Black))
  | (S h, Black) => do! c' <- genColor;
                    let h' := match c' with Red => S h | Black => h end in
                    liftGen4 Node (returnGen c') (genRBTree_height (h', c'))
                                       arbitrary (genRBTree_height (h', c')) end.
Proof.
  unfold_sub genRBTree_height (genRBTree_height hc).
  f_equal. destruct hc as [[|h] [|]]; try reflexivity.
  f_equal. apply functional_extensionality => [[|]]; reflexivity.
Qed.

(* Hope that this is enough for preventing unfolding genRBTree_height *)
Global Opaque genRBTree_height.


(* begin genRBTree *)
Definition genRBTree := sized (fun h => genRBTree_height (h, Red)).
(* end genRBTree *)

Definition showDiscards (r : Result) :=
  match r with
  | Success ns nd _ _ => "Success: number of successes " ++ show (ns-1) ++ newline ++
                         "         number of discards "  ++ show nd ++ newline
  | _ => show r
  end.

Definition testInsert :=
  showDiscards (quickCheck (insert_preserves_redblack_checker genRBTree)).

Extract Constant defSize => "10".
Extract Constant Test.defNumTests => "10000".
(* begin QC_good *)
QuickCheck (insert_preserves_redblack_checker genRBTree).
(* end QC_good *)
