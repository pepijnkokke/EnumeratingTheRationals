(** * Enumerating The Rationals *)

Require Import List.
Require Import Streams.
Require Import PArith.
Require Import NArith.
Require Import QArith.
Require Import Recdef.

(** ** CoLists *)

Module CoList.

  (** A [colist] is defined by analogy to the [Stream] datatype,
      so that we can use the high-level predicates defined in the
      [Coq.Lists.Streams] module. *)

  Notation colist         := Stream.
  Notation cocons         := Cons.
  Notation Eq             := EqSt.
  Notation Eq_refl        := EqSt_reflex.
  Notation Eq_sym         := sym_EqSt.
  Notation Eq_trans       := trans_EqSt.
  Notation Exists         := Exists.
  Notation Exists_here    := Here.
  Notation Exists_further := Further.
  Notation Forall         := ForAll.
  Notation Always         := HereAndFurther.
  Notation lookup         := Str_nth.

  (** Ensure that [lookup] is transparent. *)

  Hint Unfold lookup.

  (** Constructs [colist]s by iteratively unfolding values. *)

  CoFixpoint unfold {A B: Type} (f: B -> (A*B)) (e: B) : colist A :=
    match f e with
      | (x,xs) => cocons  x (unfold f xs)
    end.
  
  (** Takes a finite prefix of an infinite [colist]. *)

  Fixpoint take {A: Type} (n: nat) (xs: colist A) : list A :=
    match n with
      | O => nil
      | S n =>
        match xs with
          | cocons x xs => cons x (take n xs)
        end
    end.

  Inductive In {A: Type} (P: A -> Prop) (l: colist A) : Prop :=
  | At (n: nat) : P (lookup n l) -> In P l.

  Theorem In_Exists : forall {A: Type} (P: A -> Prop) (l: colist A),
    In P l -> Exists (fun l => P (hd l)) l.
  Proof.
    intros A P l H; elim H; clear H; intro n.
    generalize l; clear l.
    induction n as [|n].
    - intros l H; destruct l as [e l].
      apply Exists_here; simpl in *; assumption.
    - intros l H; destruct l as [e l].
      apply IHn in H; apply Exists_further; simpl; assumption.
  Qed.
  
  Theorem Exists_In : forall {A: Type} (P: A -> Prop) (l: colist A),
    Exists (fun l => P (hd l)) l -> In P l.
  Proof.
    intros A P l H; elim H.
    - clear H l; intros l H.
      apply (At P l 0); simpl; assumption.
    - clear H l; intros l H IH; elim IH; clear IH; intros n IH.
      apply (At P l (S n)).
      destruct l as [e l]; simpl in *; assumption.
  Qed.
  
End CoList.

Notation colist                := CoList.colist.
Notation cocons                := CoList.cocons.
Notation colist_eq             := CoList.Eq.
Notation colist_eq_refl        := CoList.Eq_refl.
Notation colist_eq_sym         := CoList.Eq_sym.
Notation colist_eq_trans       := CoList.Eq_trans.
Notation colist_exists         := CoList.Exists.
Notation colist_exists_here    := CoList.Exists_here.
Notation colist_exists_further := CoList.Exists_further.
Notation colist_forall         := CoList.Forall.
Notation colist_forall_always  := CoList.Always.
Notation colist_unfold         := CoList.unfold.
Notation colist_take           := CoList.take.
Notation in_colist             := CoList.In.
Notation in_colist_at          := CoList.At.
Notation colist_exists_in      := CoList.Exists_In.
Notation colist_in_exists      := CoList.In_Exists.

(** ** CoTrees *)

Module CoTree.

  CoInductive cotree (A: Type) :=
  | conode : cotree A -> A -> cotree A -> cotree A.

  (** Constructs [cotrees]s by iteratively unfolding values. *)

  CoFixpoint unfold {A B: Type} (f: B -> (B*A*B)) (e: B) : cotree A :=
    match f e with
      | (l,x,r) => conode _ (unfold f l) x (unfold f r)
    end.

  (** Returns the [root] of a [cotree], which is the topmost value. *)

  Definition root {A: Type} (t: cotree A) : A :=
    match t with
      | conode _ x _ => x
    end.

  (** Returns the left subtree of a [cotree]. *)
  
  Definition left {A: Type} (t: cotree A) : cotree A :=
    match t with
      | conode l _ _ => l
    end.

  (** Returns the right subtree of a [cotree]. *)
  
  Definition right {A: Type} (t: cotree A) : cotree A :=
    match t with
      | conode _ _ r => r
    end.

  (** Define an inductive datatype for performing queries on
      [cotree]s, as the [nat] type is for [colist]s. *)

  Inductive path : Type :=
  | Here  : path
  | Left  : path -> path
  | Right : path -> path.

  Fixpoint lookup {A: Type} (p: path) (t: cotree A) : A :=
    match t with
      | conode l x r =>
        match p with
          | Here    => x
          | Left  p => lookup p l
          | Right p => lookup p r
        end
    end.
        
  (** Equality as defined on [cotree]s; to prove (co)equality,
      one must show that the [root]s of the two trees are equal,
      and that both of their subtrees are equal.
   
      Note that the constructor [conode_eq] can only be applied
      when both roots are already proven equal. *)

  CoInductive Eq {A: Type} : cotree A -> cotree A -> Prop :=
    cotree_eq : forall x l1 r1 l2 r2,
                  Eq l1 l2
                  -> Eq r1 r2
                  -> Eq (conode _ l1 x r1) (conode _ l2 x r2).

  Theorem Eq_root : forall {A: Type} (t1 t2: cotree A), Eq t1 t2 -> root t1 = root t2.
    intros A t1 t2 H; destruct H; reflexivity.
  Qed.

  Theorem Eq_left : forall {A: Type} (t1 t2: cotree A), Eq t1 t2 -> Eq (left t1) (left t2).
    intros A t1 t2 H; destruct H; simpl; assumption.
  Qed.

  Theorem Eq_right : forall {A: Type} (t1 t2: cotree A), Eq t1 t2 -> Eq (right t1) (right t2).
    intros A t1 t2 H; destruct H; simpl; assumption.
  Qed.

  Section Eq_coind.
    Variable A: Type.
    Variable R: cotree A -> cotree A -> Prop.
    
    Hypothesis Case_root  : forall t1 t2, R t1 t2 -> root t1 = root t2.
    Hypothesis Case_left  : forall t1 t2, R t1 t2 -> R (left t1) (left t2).
    Hypothesis Case_right : forall t1 t2, R t1 t2 -> R (right t1) (right t2).
    
    Theorem Eq_coind : forall t1 t2: cotree A, R t1 t2 -> Eq t1 t2.
      cofix.
      destruct t1 as [l1 x1 r1].
      destruct t2 as [l2 x2 r2].
      intro H.
      generalize H; intro Heq.
      apply Case_root in Heq; simpl in Heq; rewrite Heq.
      constructor.
      - apply Case_left in H; simpl in H.
        apply Eq_coind; assumption.
      - apply Case_right in H; simpl in H.
        apply Eq_coind; assumption.
    Qed.
  End Eq_coind.
  
  Theorem Eq_refl : forall {A: Type} (t: cotree A), Eq t t.
    intros A t.
    apply (Eq_coind A (fun t1 t2 => t1 = t2)).
    - intros t1 t2 H; rewrite H; reflexivity.
    - intros t1 t2 H; rewrite H; reflexivity.
    - intros t1 t2 H; rewrite H; reflexivity.
    - reflexivity.
  Qed.

  Theorem Eq_sym : forall {A: Type} (t1 t2: cotree A), Eq t1 t2 -> Eq t2 t1.
    cofix.
    intros A t1 t2 H.
    destruct t1 as [l1 x1 r1].
    destruct t2 as [l2 x2 r2].
    generalize H; intro Heq; apply Eq_root in Heq; simpl in Heq.
    rewrite <- Heq.
    constructor.
    - apply Eq_left in H; simpl in H.
      generalize H; apply Eq_sym.
    - apply Eq_right in H; simpl in H.
      generalize H; apply Eq_sym.
  Qed.

  Theorem Eq_trans : forall {A: Type} (t1 t2 t3: cotree A), Eq t1 t2 -> Eq t2 t3 -> Eq t1 t3.
    cofix.
    intros A t1 t2 t3 H12 H23.
    destruct t1 as [l1 x1 r1].
    destruct t2 as [l2 x2 r2].
    destruct t3 as [l3 x3 r3].
    generalize H12; intro Heq12; apply Eq_root in Heq12; simpl in Heq12.
    generalize H23; intro Heq23; apply Eq_root in Heq23; simpl in Heq23.
    rewrite <- Heq23, <- Heq12.
    constructor.
    - apply Eq_left in H12; simpl in H12.
      apply Eq_left in H23; simpl in H23.
      generalize H12 H23.
      apply Eq_trans.
    - apply Eq_right in H12; simpl in H12.
      apply Eq_right in H23; simpl in H23.
      generalize H12 H23.
      apply Eq_trans.
  Qed.

  (** [In] defines proofs on the elements of a [cotree]. *)

  Inductive In {A: Type} (P: A -> Prop) (t: cotree A) : Prop :=
  | At (p: path) : P (lookup p t) -> In P t.

  (** [Exists] defines proofs on the subtrees of a [cotree] *)

  Inductive Exists {A: Type} (P: cotree A -> Prop) (t: cotree A) : Prop :=
  | Exists_here  : P t -> Exists P t
  | Exists_left  : Exists P (left t) -> Exists P t
  | Exists_right : Exists P (right t) -> Exists P t.

  (** Duality of [In] and [Exists]: A proof for [In] is equivalent to a proof
      for [Exists] with a predicate on the root of the subtree. *)

  Theorem In_Exists : forall {A: Type} (P: A -> Prop) (t: cotree A),
    In P t -> Exists (fun t => P (root t)) t.
  Proof.
    intros A P t H; elim H; clear H; intro p.
    generalize t; clear t.
    induction p as [|p|p].
    - intros t H; destruct t as [l x r]; apply Exists_here; simpl in *; assumption.
    - intros t H; destruct t as [l x r]; simpl in *.
      apply IHp in H; apply Exists_left; simpl; assumption.
    - intros t H; destruct t as [l x r]; simpl in *.
      apply IHp in H; apply Exists_right; simpl; assumption.
  Qed.
  
  Theorem Exists_In : forall {A: Type} (P: A -> Prop) (t: cotree A),
    Exists (fun t => P (root t)) t -> In P t.
  Proof.
    intros A P t H; elim H.
    - clear H t; intros t H.
      apply (At P t Here); destruct t as [l x r]; simpl in *; assumption.
    - clear H t; intros t H IH; elim IH; clear IH; intros p IH.
      apply (At P t (Left p)).
      destruct t as [l x r]; simpl in *; assumption.
    - clear H t; intros t H IH; elim IH; clear IH; intros p IH.
      apply (At P t (Right p)).
      destruct t as [l x r]; simpl in *; assumption.
  Qed.

  Theorem Exists_At : forall {A: Type} (P: A -> Prop) (p: path) (t: cotree A),
    P (lookup p t) -> Exists (fun t => P (root t)) t.
  Proof.
    intros A P p t H; apply (At P t p) in H; apply In_Exists; assumption.
  Qed.

  (** [Forall] defines a proof on all subtrees of a [cotree] *)

  CoInductive Forall {A: Type} (P: cotree A -> Prop) (t: cotree A) : Prop :=
  | Always : P t -> Forall P (left t) -> Forall P (right t) -> Forall P t.

  Section Forall_coind.
    Variable A: Type.
    Variable P: cotree A -> Prop.
    Variable R: cotree A -> Prop.

    Hypothesis Case_here  : forall t, R t -> P t.
    Hypothesis Case_left  : forall t, R t -> R (left t).
    Hypothesis Case_right : forall t, R t -> R (right t).
    
    Theorem Forall_coind : forall t, R t -> Forall P t.
      cofix.
      constructor.
      - apply Case_here  in H; assumption.
      - apply Case_left  in H; apply Forall_coind in H; assumption.
      - apply Case_right in H; apply Forall_coind in H; assumption.
    Qed.
  End Forall_coind.

  Lemma Forall_here : forall {A} P (t: cotree A), Forall P t -> P t.
    intros A P t H; destruct H as [H0 HL HR]; assumption.
  Qed.

  Lemma Forall_left : forall {A} P (t: cotree A), Forall P t -> Forall P (left t).
    intros A P t H; destruct H as [H0 HL HR]; assumption.
  Qed.
    
  Lemma Forall_right : forall {A} P (t: cotree A), Forall P t -> Forall P (right t).
    intros A P t H; destruct H as [H0 HL HR]; assumption.
  Qed.

  Lemma ForallP_ExistsP : forall {A} P (t: cotree A),
    Forall P t -> Exists P t.
  Proof.
    intros A P t.
    intro H; apply Forall_here in H.
    constructor; assumption.
  Qed.

  Lemma ForallP_NotExistsNotP : forall {A} P (t: cotree A),
    Forall P t -> ~(Exists (fun t => ~P t) t).
  Proof.
    intros A P t H F.
    induction F as [t F0|t FL IHL|t FR IHR].
    - apply Forall_here  in H; elim F0; assumption.
    - apply Forall_left  in H; apply IHL in H; assumption.
    - apply Forall_right in H; apply IHR in H; assumption.
  Qed.

  Lemma ExistsNotNotP_NotForallNotP : forall {A} P (t: cotree A),
    Exists (fun t => ~ ~ P t) t -> ~ Forall (fun t => ~P t) t.
  Proof. 
    intros A P t H F.
    destruct H.
    - apply Forall_here  in F; elim H; assumption.
    - apply Forall_left  in F; apply ForallP_NotExistsNotP in F; elim F. assumption.
    - apply Forall_right in F; apply ForallP_NotExistsNotP in F; elim F. assumption.
  Qed.

  Section Map.
    
    (** Definition of [map] over [cotree]s. *)

    CoFixpoint map {A B: Type} (f: A -> B) (t: cotree A) : cotree B :=
      match t with
        | conode l x r => conode _ (map f l) (f x) (map f r)
      end.
    
    Theorem Forall_map : forall {A B: Type} (P: cotree B -> Prop) (f: A -> B) (t: cotree A),
      Forall (fun t => P (map f t)) t -> Forall P (map f t).
    Proof.
      intros A B P f; cofix; intros t H.
      constructor.
      - apply Forall_here in H; assumption.
      - apply Forall_left in H.
        destruct t as [l x r]; simpl in *.
        apply Forall_map in H; assumption.
      - apply Forall_right in H.
        destruct t as [l x r]; simpl in *.
        apply Forall_map in H; assumption.
    Qed.

  End Map.

  Section Enumerate.

    (** Performs a breadth-first walk over a forest of [cotree]s, provided that
        the forest is provably non-empty. *)
  
    CoFixpoint bf_acc {A: Type} (ts: list (cotree A)) : ts<>nil -> colist A.
      refine (match ts as xs return xs<>nil -> colist A with
                | nil       => fun h => _
                | cons t ts => fun h =>
                  match t with
                    | conode l x r => cocons x (bf_acc _ (ts ++ (cons l (cons r nil))) _)
                  end
              end).
      exfalso; apply h; reflexivity.
      apply not_eq_sym; apply app_cons_not_nil.
    Defined.

    (** Performs a breadth-first walk over a [cotree], returning a [colist]. *)
    
    Definition bf {A: Type} (t: cotree A) : colist A.
      refine (bf_acc (t :: nil) _).
      apply not_eq_sym; apply nil_cons.
    Defined.

    Theorem In_bf : forall {A: Type} (P: A -> Prop) (t: cotree A),
      In P t -> in_colist P (bf t).
    Proof.
    Admitted.

  End Enumerate.
    
End CoTree.

(** Import [CoTree] into the global scope. *)

Notation cotree               := CoTree.cotree.
Notation conode               := CoTree.conode.
Notation cotree_unfold        := CoTree.unfold.
Notation cotree_bf            := CoTree.bf.
Notation cotree_map           := CoTree.map.
Notation cotree_root          := CoTree.root.
Notation cotree_left          := CoTree.left.
Notation cotree_right         := CoTree.right.
Notation cotree_lookup        := CoTree.lookup.
Notation cotree_path          := CoTree.path.
Notation cotree_here          := CoTree.Here.
Notation cotree_goleft        := CoTree.Left.
Notation cotree_goright       := CoTree.Right.
Notation cotree_eq            := CoTree.Eq.
Notation cotree_eq_refl       := CoTree.Eq_refl.
Notation cotree_eq_sym        := CoTree.Eq_sym.
Notation cotree_eq_trans      := CoTree.Eq_trans.
Notation cotree_eq_root       := CoTree.Eq_root.
Notation cotree_eq_left       := CoTree.Eq_left.
Notation cotree_eq_right      := CoTree.Eq_right.
Notation cotree_eq_coind      := CoTree.Eq_coind.
Notation cotree_exists        := CoTree.Exists.
Notation cotree_exists_at     := CoTree.Exists_at.
Notation cotree_exists_here   := CoTree.Exists_here.
Notation cotree_exists_left   := CoTree.Exists_left.
Notation cotree_exists_right  := CoTree.Exists_right.
Notation cotree_forall        := CoTree.Forall.
Notation cotree_forall_always := CoTree.Always.
Notation cotree_forall_here   := CoTree.Forall_here.
Notation cotree_forall_left   := CoTree.Forall_left.
Notation cotree_forall_right  := CoTree.Forall_right.
Notation cotree_forall_map    := CoTree.Forall_map.
Notation in_cotree            := CoTree.In.
Notation in_cotree_at         := CoTree.At.
Notation cotree_equals_in     := CoTree.Equals_In.
Notation cotree_in_equals     := CoTree.In_Equals.

(** ** The Stern-Brocot Tree *)
Module SternBrocot.

  (** *** Required Proofs on Natural Numbers *)

  Local Open Scope N_scope.
  
  Section N_Properties.

    Definition N_pos (n:N) : n<>0 -> positive.
      refine (match n as n' return n'<>0 -> positive with
                | 0      => fun h => _
                | Npos p => fun h => p
              end).
      exfalso; apply h; reflexivity.
    Defined.
  
    Definition N_Z (n:N) : Z :=
      match n with
        | 0      => Z0 
        | Npos n => Zpos n
      end.
    
    Lemma Npos_over_Nplus_l : forall n m : N,
      n <> 0 -> n + m <> 0.
    Proof.
      intros n m H.
      destruct n as [|n].
      - exfalso; apply H; reflexivity.
      - destruct m as [|m].
        * simpl; assumption.
        * simpl; discriminate.
    Qed.
  
    Lemma Npos_over_Nplus_r : forall n m : N,
      m <> 0 -> n + m <> 0.
    Proof.
      intros; rewrite Nplus_comm; apply Npos_over_Nplus_l; assumption.
    Qed.
    
    Lemma Npos_over_Nplus : forall n m : N,
      n <> 0 \/ m <> 0 -> n + m <> 0.
    Proof.
      intros n m H; elim H; [apply Npos_over_Nplus_l|apply Npos_over_Nplus_r].
    Qed.

  End N_Properties.

  (** *** Construction of the Tree *)

  Section SternBrocotDef.

    Inductive Qpair : Type :=
    | qpair (a b c d : N) (HL: a<>0 \/ c<>0) (HR: b<>0 \/ d<>0) : Qpair.
    
    Definition next (q:Qpair) : Qpair*Q*Qpair.
      refine (match q with
                | qpair a b c d HL HR =>
                  let ac := a + c in
                  let bd := b + d in
                  let l  := qpair a  b  ac bd _ _ in
                  let r  := qpair ac bd  c  d _ _ in
                  let q  := N_Z ac # N_pos bd _ in
                  (l,q,r)
              end).
      - right; unfold ac; apply Npos_over_Nplus in HL; assumption.
      - right; unfold bd; apply Npos_over_Nplus in HR; assumption.
      - left ; unfold ac; apply Npos_over_Nplus in HL; assumption.
      - left ; unfold bd; apply Npos_over_Nplus in HR; assumption.
      -        unfold bd; apply Npos_over_Nplus in HR; assumption.
    Defined.

    Definition tree : cotree Q.
      refine (cotree_unfold next (qpair 0 1 1 0 _ _)).
      - right ; discriminate.
      - left  ; discriminate.
    Defined.
    
    Definition enum : colist Q := cotree_bf tree.

  End SternBrocotDef.

  Section GcdPath.

    (** *** Computational Trace of a GCD Computation *)

    Definition step (qs: cotree_path -> cotree_path) (acc: N*cotree_path) :=
      match acc with
        | (d,q0) => (d,qs q0)
      end.

    Definition pairsum (p: N*N) :=
      match p with (m,n) => N.to_nat (m + n) end.

    Function gcd_path (p: N*N) {measure pairsum p} :=
      match p with (m,n) => 
        if (m <? n) then step cotree_goleft (gcd_path (m,(n - m))) else
        if (n <? m) then step cotree_goright (gcd_path ((m - n),n)) else
        (m, cotree_here)
      end.
    Proof.
      intros p m n Hp Hltb; simpl.
      pose proof (N.ltb_spec m n) as Hlt.
      destruct Hlt as [Hlt|Hlt].
    Admitted.

  End GcdPath.
  
End SternBrocot.

Notation stern_brocot_next := SternBrocot.next.
Notation stern_brocot_tree := SternBrocot.tree.
Notation stern_brocot_enum := SternBrocot.enum.

(** ** The Calkin-Wilf Tree *)
Module CalkinWilf.

  Local Open Scope positive_scope.

  Definition next (q:positive*positive) : (positive*positive)*Q*(positive*positive) :=
    match q with
      | (m,n) => ((m,m + n),Zpos m # n,(m + n,n))
    end.
  
  Definition tree : cotree Q := cotree_unfold next (1,1).
  
  Definition enum : colist Q := cotree_bf tree.

  Local Open Scope Q_scope.
  
  Theorem contains_1 : in_cotree (fun p => p = 1#1) tree.
  Proof. constructor; reflexivity. Qed.

  Theorem contains_2 : in_cotree (fun p => p = 2#1) tree.
  Proof.
    apply cotree_exists_right.
    constructor; reflexivity.
  Qed.
  
  Theorem contains_Q : forall q:Q, in_cotree (fun p => p = Qred q) tree.
    intros q. 
    destruct q as [num den].
  Admitted.

End CalkinWilf.

Notation calkin_wilf_next := CalkinWilf.next.
Notation calkin_wilf_tree := CalkinWilf.tree.
Notation calkin_wilf_enum := CalkinWilf.enum.

