-- Copyright (c) 2014 Floris van Doorn. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Floris van Doorn

-- category
import logic.eq logic.connectives
import data.unit data.sigma data.prod
import algebra.function
import logic.axioms.funext

open eq eq.ops

inductive category [class] (ob : Type) : Type :=
mk : Π (mor : ob → ob → Type) (comp : Π⦃A B C : ob⦄, mor B C → mor A B → mor A C)
           (id : Π {A : ob}, mor A A),
            (Π ⦃A B C D : ob⦄ {h : mor C D} {g : mor B C} {f : mor A B},
            comp h (comp g f) = comp (comp h g) f) →
           (Π ⦃A B : ob⦄ {f : mor A B}, comp id f = f) →
           (Π ⦃A B : ob⦄ {f : mor A B}, comp f id = f) →
            category ob

inductive Category : Type :=
mk : Π (A : Type), category A → Category

namespace category

  section
  parameters {ob : Type} {Cat : category ob} {A B C D : ob}

  definition mor : ob → ob → Type := rec (λ mor compose id assoc idr idl, mor) Cat
  definition compose : Π {A B C : ob}, mor B C → mor A B → mor A C :=
  rec (λ mor compose id assoc idr idl, compose) Cat

  definition id : Π {A : ob}, mor A A :=
  rec (λ mor compose id assoc idr idl, id) Cat
  definition ID (A : ob) : mor A A := @id A

  precedence `∘` : 60
  infixr `∘` := compose
  infixl `=>`:25 := mor

  theorem assoc : Π {A B C D : ob} {h : mor C D} {g : mor B C} {f : mor A B},
                h ∘ (g ∘ f) = (h ∘ g) ∘ f :=
  rec (λ mor comp id assoc idr idl, assoc) Cat

  theorem id_left  : Π {A B : ob} {f : mor A B}, id ∘ f = f :=
  rec (λ mor comp id assoc idl idr, idl) Cat
  theorem id_right : Π {A B : ob} {f : mor A B}, f ∘ id = f :=
  rec (λ mor comp id assoc idl idr, idr) Cat

  theorem id_compose {A : ob} : (ID A) ∘ id = id :=
  id_left

  theorem left_id_unique (i : mor A A) (H : Π{B} {f : mor B A}, i ∘ f = f) : i = id :=
  calc
    i = i ∘ id : symm id_right
    ... = id : H

  theorem right_id_unique (i : mor A A) (H : Π{B} {f : mor A B}, f ∘ i = f) : i = id :=
  calc
    i = id ∘ i : eq.symm id_left
    ... = id : H

  inductive is_section [class] {A B : ob} (f : mor A B) : Type :=
  mk : ∀{g}, g ∘ f = id → is_section f
  inductive is_retraction [class] {A B : ob} (f : mor A B) : Type :=
  mk : ∀{g}, f ∘ g = id → is_retraction f
  inductive is_iso [class] {A B : ob} (f : mor A B) : Type :=
  mk : ∀{g}, g ∘ f = id → f ∘ g = id → is_iso f

  definition retraction_of {A B : ob} (f : mor A B) {H : is_section f} : mor B A :=
  is_section.rec (λg h, g) H
  definition section_of {A B : ob} (f : mor A B) {H : is_retraction f} : mor B A :=
  is_retraction.rec (λg h, g) H
  definition inverse {A B : ob} (f : mor A B) {H : is_iso f} : mor B A :=
  is_iso.rec (λg h1 h2, g) H

  postfix `⁻¹` := inverse

  theorem id_is_iso [instance] : is_iso (ID A) :=
  is_iso.mk id_compose id_compose

  theorem inverse_compose {A B : ob} {f : mor A B} {H : is_iso f} : f⁻¹ ∘ f = id :=
  is_iso.rec (λg h1 h2, h1) H

  theorem compose_inverse {A B : ob} {f : mor A B} {H : is_iso f} : f ∘ f⁻¹ = id :=
  is_iso.rec (λg h1 h2, h2) H

  theorem iso_imp_retraction [instance] {A B : ob} (f : mor A B) {H : is_iso f} : is_section f :=
  is_section.mk inverse_compose

  theorem iso_imp_section [instance] {A B : ob} (f : mor A B) {H : is_iso f} : is_retraction f :=
  is_retraction.mk compose_inverse

  theorem retraction_compose {A B : ob} {f : mor A B} {H : is_section f} :
      retraction_of f ∘ f = id :=
  is_section.rec (λg h, h) H

  theorem compose_section {A B : ob} {f : mor A B} {H : is_retraction f} :
      f ∘ section_of f = id :=
  is_retraction.rec (λg h, h) H

  theorem left_inverse_eq_right_inverse {A B : ob} {f : mor A B} {g g' : mor B A}
      (Hl : g ∘ f = id) (Hr : f ∘ g' = id) : g = g' :=
  calc
    g = g ∘ id : symm id_right
     ... = g ∘ f ∘ g' : {symm Hr}
     ... = (g ∘ f) ∘ g' : assoc
     ... = id ∘ g' : {Hl}
     ... = g' : id_left

  theorem section_eq_retraction {A B : ob} {f : mor A B}
      (Hl : is_section f) (Hr : is_retraction f) : retraction_of f = section_of f :=
  left_inverse_eq_right_inverse retraction_compose compose_section

  theorem section_retraction_imp_iso {A B : ob} {f : mor A B}
      (Hl : is_section f) (Hr : is_retraction f) : is_iso f :=
  is_iso.mk (subst (section_eq_retraction Hl Hr) retraction_compose) compose_section

  theorem inverse_unique {A B : ob} {f : mor A B} (H H' : is_iso f)
          : @inverse _ _ f H = @inverse _ _ f H' :=
  left_inverse_eq_right_inverse inverse_compose compose_inverse

  theorem retraction_of_id {A : ob} : retraction_of (ID A) = id :=
  left_inverse_eq_right_inverse retraction_compose id_compose

  theorem section_of_id {A : ob} : section_of (ID A) = id :=
  symm (left_inverse_eq_right_inverse id_compose compose_section)

  theorem iso_of_id {A : ob} : ID A⁻¹ = id :=
  left_inverse_eq_right_inverse inverse_compose id_compose

  theorem composition_is_section [instance] {f : mor A B} {g : mor B C}
      (Hf : is_section f) (Hg : is_section g) : is_section (g ∘ f) :=
  is_section.mk
    (calc
      (retraction_of f ∘ retraction_of g) ∘ g ∘ f
            = retraction_of f ∘ retraction_of g ∘ g ∘ f : symm assoc
        ... = retraction_of f ∘ (retraction_of g ∘ g) ∘ f : {assoc}
        ... = retraction_of f ∘ id ∘ f : {retraction_compose}
        ... = retraction_of f ∘ f : {id_left}
        ... = id : retraction_compose)

  theorem composition_is_retraction [instance] {f : mor A B} {g : mor B C}
      (Hf : is_retraction f) (Hg : is_retraction g) : is_retraction (g ∘ f) :=
  is_retraction.mk
    (calc
      (g ∘ f) ∘ section_of f ∘ section_of g = g ∘ f ∘ section_of f ∘ section_of g : symm assoc
        ... = g ∘ (f ∘ section_of f) ∘ section_of g : {assoc}
        ... = g ∘ id ∘ section_of g : {compose_section}
        ... = g ∘ section_of g : {id_left}
        ... = id : compose_section)

  theorem composition_is_inverse [instance] {f : mor A B} {g : mor B C}
      (Hf : is_iso f) (Hg : is_iso g) : is_iso (g ∘ f) :=
  section_retraction_imp_iso _ _

  definition mono {A B : ob} (f : mor A B) : Prop :=
  ∀⦃C⦄ {g h : mor C A}, f ∘ g = f ∘ h → g = h
  definition epi  {A B : ob} (f : mor A B) : Prop :=
  ∀⦃C⦄ {g h : mor B C}, g ∘ f = h ∘ f → g = h

  theorem section_is_mono {f : mor A B} (H : is_section f) : mono f :=
  λ C g h H,
  calc
    g = id ∘ g : symm id_left
  ... = (retraction_of f ∘ f) ∘ g : {symm retraction_compose}
  ... = retraction_of f ∘ f ∘ g : symm assoc
  ... = retraction_of f ∘ f ∘ h : {H}
  ... = (retraction_of f ∘ f) ∘ h : assoc
  ... = id ∘ h : {retraction_compose}
  ... = h : id_left

  theorem retraction_is_epi {f : mor A B} (H : is_retraction f) : epi f :=
  λ C g h H,
  calc
    g = g ∘ id : symm id_right
  ... = g ∘ f ∘ section_of f : {symm compose_section}
  ... = (g ∘ f) ∘ section_of f : assoc
  ... = (h ∘ f) ∘ section_of f : {H}
  ... = h ∘ f ∘ section_of f : symm assoc
  ... = h ∘ id : {compose_section}
  ... = h : id_right

  end

  section

  definition objects [coercion] (C : Category) : Type
  := Category.rec (fun c s, c) C

  definition category_instance [instance] (C : Category) : category (objects C)
  := Category.rec (fun c s, s) C

  end

end category

open category

inductive functor {obC obD : Type} (C : category obC) (D : category obD) : Type :=
mk : Π (obF : obC → obD) (morF : Π⦃A B : obC⦄, mor A B → mor (obF A) (obF B)),
    (Π ⦃A : obC⦄, morF (ID A) = ID (obF A)) →
    (Π ⦃A B C : obC⦄ {f : mor A B} {g : mor B C}, morF (g ∘ f) = morF g ∘ morF f) →
     functor C D

inductive Functor (C D : Category) : Type :=
mk : functor (category_instance C) (category_instance D) → Functor C D

infixl `⇒`:25 := functor

namespace functor
  section basic_functor
  parameters {obC obD : Type} {C : category obC} {D : category obD}
  definition object [coercion] (F : C ⇒ D) : obC → obD := rec (λ obF morF Hid Hcomp, obF) F

  definition morphism [coercion] (F : C ⇒ D) : Π{A B : obC}, mor A B → mor (F A) (F B) :=
  rec (λ obF morF Hid Hcomp, morF) F

  theorem respect_id (F : C ⇒ D) : Π {A : obC}, F (ID A) = ID (F A) :=
  rec (λ obF morF Hid Hcomp, Hid) F

  theorem respect_comp (F : C ⇒ D) : Π {a b c : obC} {f : mor a b} {g : mor b c},
      F (g ∘ f) = F g ∘ F f :=
  rec (λ obF morF Hid Hcomp, Hcomp) F
  end basic_functor

  section category_functor

  protected definition compose {obC obD obE : Type} {C : category obC} {D : category obD} {E : category obE}
      (G : D ⇒ E) (F : C ⇒ D) : C ⇒ E :=
  functor.mk
    (λx, G (F x))
    (λ a b f, G (F f))
    (λ a, calc
      G (F (ID a)) = G id : {respect_id F}
               ... = id   : respect_id G)
    (λ a b c f g, calc
      G (F (g ∘ f)) = G (F g ∘ F f)     : {respect_comp F}
                ... = G (F g) ∘ G (F f) : respect_comp G)

  precedence `∘∘` : 60
  infixr `∘∘` := compose

  protected theorem assoc {obA obB obC obD : Type} {A : category obA} {B : category obB}
      {C : category obC} {D : category obD} {H : C ⇒ D} {G : B ⇒ C} {F : A ⇒ B} :
      H ∘∘ (G ∘∘ F) = (H ∘∘ G) ∘∘ F :=
  rfl

  -- later check whether we want implicit or explicit arguments here. For the moment, define both
  protected definition id {ob : Type} {C : category ob} : functor C C :=
  mk (λa, a) (λ a b f, f) (λ a, rfl) (λ a b c f g, rfl)
  protected definition ID {ob : Type} (C : category ob) : functor C C := id
  protected definition Id {C : Category} : Functor C C := Functor.mk id
  protected definition iD (C : Category) : Functor C C := Functor.mk id

  protected theorem id_left {obC obB : Type} {B : category obB} {C : category obC} {F : B ⇒ C}
      : id ∘∘ F = F :=
  rec (λ obF morF idF compF, rfl) F

  protected theorem id_right {obC obB : Type} {B : category obB} {C : category obC} {F : B ⇒ C}
      : F ∘∘ id = F :=
  rec (λ obF morF idF compF, rfl) F

  end category_functor

  section Functor
--  parameters {C D E : Category} (G : Functor D E) (F : Functor C D)
  definition Functor_functor {C D : Category} (F : Functor C D) : functor (category_instance C) (category_instance D) :=
  Functor.rec (λ x, x) F

  protected definition Compose {C D E : Category} (G : Functor D E) (F : Functor C D) : Functor C E :=
  Functor.mk (compose (Functor_functor G) (Functor_functor F))

--  namespace Functor
  precedence `∘∘` : 60
  infixr `∘∘` := Compose
--  end Functor

  protected definition Assoc {A B C D : Category} {H : Functor C D} {G : Functor B C} {F : Functor A B}
    :  H ∘∘ (G ∘∘ F) = (H ∘∘ G) ∘∘ F :=
  rfl

  protected theorem Id_left {B : Category} {C : Category} {F : Functor B C}
      : Id ∘∘ F = F :=
  Functor.rec (λ f, subst id_left rfl) F

  protected theorem Id_right {B : Category} {C : Category} {F : Functor B C}
      : F ∘∘ Id = F :=
  Functor.rec (λ f, subst id_right rfl) F

  end Functor

end functor

open functor

inductive natural_transformation {obC obD : Type} {C : category obC} {D : category obD}
    (F G : functor C D) : Type :=
mk : Π (η : Π(a : obC), mor (object F a) (object G a)), (Π{a b : obC} (f : mor a b), morphism G f ∘ η a = η b ∘ morphism F f)
 → natural_transformation F G

-- inductive Natural_transformation {C D : Category} (F G : Functor C D) : Type :=
-- mk : natural_transformation (Functor_functor F) (Functor_functor G) → Natural_transformation F G

infixl `==>`:25 := natural_transformation

namespace natural_transformation
  section
  parameters {obC obD : Type} {C : category obC} {D : category obD} {F G : C ⇒ D}

  definition natural_map [coercion] (η : F ==> G) :
      Π(a : obC), mor (object F a) (object G a) :=
  rec (λ x y, x) η

  definition naturality (η : F ==> G) :
      Π{a b : obC} (f : mor a b), morphism G f ∘ η a = η b ∘ morphism F f :=
  rec (λ x y, y) η
  end

  section
  parameters {obC obD : Type} {C : category obC} {D : category obD} {F G H : C ⇒ D}
  protected definition compose (η : G ==> H) (θ : F ==> G) : F ==> H :=
  natural_transformation.mk
    (λ a, η a ∘ θ a)
    (λ a b f,
      calc
        morphism H f ∘ (η a ∘ θ a) = (morphism H f ∘ η a) ∘ θ a : assoc
          ... = (η b ∘ morphism G f) ∘ θ a : {naturality η f}
          ... = η b ∘ (morphism G f ∘ θ a) : symm assoc
          ... = η b ∘ (θ b ∘ morphism F f) : {naturality θ f}
          ... = (η b ∘ θ b) ∘ morphism F f : assoc)
  end
  precedence `∘n` : 60
  infixr `∘n` := compose
  section
  protected theorem assoc {obC obD : Type} {C : category obC} {D : category obD} {F₄ F₃ F₂ F₁ : C ⇒ D} {η₃ : F₃ ==> F₄} {η₂ : F₂ ==> F₃} {η₁ : F₁ ==> F₂} : η₃ ∘n (η₂ ∘n η₁) = (η₃ ∘n η₂) ∘n η₁ :=
  congr_arg2_dep mk (funext (take x, assoc)) proof_irrel

  --TODO: check whether some of the below identities are superfluous
  protected definition id {obC obD : Type} {C : category obC} {D : category obD} {F : C ⇒ D}
      : natural_transformation F F :=
  mk (λa, id) (λa b f, id_right ⬝ symm id_left)
  protected definition ID {obC obD : Type} {C : category obC} {D : category obD} (F : C ⇒ D)
      : natural_transformation F F := id
  -- protected definition Id {C D : Category} {F : Functor C D} : Natural_transformation F F :=
  -- Natural_transformation.mk id
  -- protected definition iD {C D : Category} (F : Functor C D) : Natural_transformation F F :=
  -- Natural_transformation.mk id

  protected theorem id_left {obC obD : Type} {C : category obC} {D : category obD} {F G : C ⇒ D}
      {η : F ==> G} : natural_transformation.compose id η = η :=
  rec (λf H, congr_arg2_dep mk (funext (take x, id_left)) proof_irrel) η

  protected theorem id_right {obC obD : Type} {C : category obC} {D : category obD} {F G : C ⇒ D}
      {η : F ==> G} : natural_transformation.compose η id = η :=
  rec (λf H, congr_arg2_dep mk (funext (take x, id_right)) proof_irrel) η

  end
end natural_transformation

-- examples of categories / basic constructions (TODO: move to separate file)

open functor
namespace category
  section
  open unit
  definition one [instance] : category unit :=
  category.mk (λa b, unit) (λ a b c f g, star) (λ a, star) (λ a b c d f g h, unit.equal _ _)
    (λ a b f, unit.equal _ _) (λ a b f, unit.equal _ _)
  end

  section
  parameter {ob : Type}
  definition opposite (C : category ob) : category ob :=
  category.mk (λa b, mor b a) (λ a b c f g, g ∘ f) (λ a, id) (λ a b c d f g h, symm assoc)
    (λ a b f, id_right) (λ a b f, id_left)
  precedence `∘op` : 60
  infixr `∘op` := @compose _ (opposite _) _ _ _

  parameters {C : category ob} {a b c : ob}

  theorem compose_op {f : @mor ob C a b} {g : mor b c} : f ∘op g = g ∘ f :=
  rfl

  theorem op_op {C : category ob} : opposite (opposite C) = C :=
  category.rec (λ mor comp id assoc idl idr, refl (mk _ _ _ _ _ _)) C
  end

  definition Opposite (C : Category) : Category :=
  Category.mk (objects C) (opposite (category_instance C))


  section
  definition type_category : category Type :=
  mk (λA B, A → B) (λ a b c, function.compose) (λ a, function.id)
    (λ a b c d h g f, symm (function.compose_assoc h g f))
    (λ a b f, function.compose_id_left f) (λ a b f, function.compose_id_right f)
  end

  section cat_Cat

  definition Cat : category Category :=
  mk (λ a b, Functor a b) (λ a b c g f, functor.Compose g f) (λ a, functor.Id)
     (λ a b c d h g f, functor.Assoc) (λ a b f, functor.Id_left)
     (λ a b f, functor.Id_right)

  end cat_Cat

  section functor_category
  parameters {obC obD : Type} (C : category obC) (D : category obD)
  definition functor_category : category (functor C D) :=
  mk (λa b, natural_transformation a b)
     (λ a b c g f, natural_transformation.compose g f)
     (λ a, natural_transformation.id)
     (λ a b c d h g f, natural_transformation.assoc)
     (λ a b f, natural_transformation.id_left)
     (λ a b f, natural_transformation.id_right)
  end functor_category


  section slice
  open sigma

  definition slice {ob : Type} (C : category ob) (c : ob) : category (Σ(b : ob), mor b c) :=
  mk (λa b, Σ(g : mor (dpr1 a) (dpr1 b)), dpr2 b ∘ g = dpr2 a)
     (λ a b c g f, dpair (dpr1 g ∘ dpr1 f)
       (show dpr2 c ∘ (dpr1 g ∘ dpr1 f) = dpr2 a,
         proof
         calc
           dpr2 c ∘ (dpr1 g ∘ dpr1 f) = (dpr2 c ∘ dpr1 g) ∘ dpr1 f : assoc
             ... = dpr2 b ∘ dpr1 f : {dpr2 g}
             ... = dpr2 a : {dpr2 f}
         qed))
     (λ a, dpair id id_right)
     (λ a b c d h g f, dpair_eq    assoc    proof_irrel)
     (λ a b f,         sigma.equal id_left  proof_irrel)
     (λ a b f,         sigma.equal id_right proof_irrel)
  -- We give proof_irrel instead of rfl, to give the unifier an easier time
  end slice

  section coslice
  open sigma

  definition coslice {ob : Type} (C : category ob) (c : ob) : category (Σ(b : ob), mor c b) :=
  mk (λa b, Σ(g : mor (dpr1 a) (dpr1 b)), g ∘ dpr2 a = dpr2 b)
     (λ a b c g f, dpair (dpr1 g ∘ dpr1 f)
       (show (dpr1 g ∘ dpr1 f) ∘ dpr2 a = dpr2 c,
         proof
         calc
           (dpr1 g ∘ dpr1 f) ∘ dpr2 a = dpr1 g ∘ (dpr1 f ∘ dpr2 a): symm assoc
             ... = dpr1 g ∘ dpr2 b : {dpr2 f}
             ... = dpr2 c : {dpr2 g}
         qed))
     (λ a, dpair id id_left)
     (λ a b c d h g f, dpair_eq    assoc    proof_irrel)
     (λ a b f,         sigma.equal id_left  proof_irrel)
     (λ a b f,         sigma.equal id_right proof_irrel)

  -- theorem slice_coslice_opp {ob : Type} (C : category ob) (c : ob) :
  --     coslice C c = opposite (slice (opposite C) c) :=
  -- sorry
  end coslice

  section product
  open prod
  definition product {obC obD : Type} (C : category obC) (D : category obD)
      : category (obC × obD) :=
  mk (λa b, mor (pr1 a) (pr1 b) × mor (pr2 a) (pr2 b))
     (λ a b c g f, (pr1 g ∘ pr1 f , pr2 g ∘ pr2 f) )
     (λ a, (id,id))
     (λ a b c d h g f, pair_eq    assoc    assoc   )
     (λ a b f,         prod.equal id_left  id_left )
     (λ a b f,         prod.equal id_right id_right)

  end product

  section arrow
  open sigma eq.ops
  -- theorem concat_commutative_squares {ob : Type} {C : category ob} {a1 a2 a3 b1 b2 b3 : ob}
  --     {f1 : a1 => b1} {f2 : a2 => b2} {f3 : a3 => b3} {g2 : a2 => a3} {g1 : a1 => a2}
  --     {h2 : b2 => b3} {h1 : b1 => b2} (H1 : f2 ∘ g1 = h1 ∘ f1) (H2 : f3 ∘ g2 = h2 ∘ f2)
  --       : f3 ∘ (g2 ∘ g1) = (h2 ∘ h1) ∘ f1 :=
  -- calc
  --   f3 ∘ (g2 ∘ g1) = (f3 ∘ g2) ∘ g1 : assoc
  --     ... = (h2 ∘ f2) ∘ g1 : {H2}
  --     ... = h2 ∘ (f2 ∘ g1) : symm assoc
  --     ... = h2 ∘ (h1 ∘ f1) : {H1}
  --     ... = (h2 ∘ h1) ∘ f1 : assoc

  -- definition arrow {ob : Type} (C : category ob) : category (Σ(a b : ob), mor a b) :=
  -- mk (λa b, Σ(g : mor (dpr1 a) (dpr1 b)) (h : mor (dpr2' a) (dpr2' b)),
  --      dpr3 b ∘ g = h ∘ dpr3 a)
  --    (λ a b c g f, dpair (dpr1 g ∘ dpr1 f) (dpair (dpr2' g ∘ dpr2' f) (concat_commutative_squares (dpr3 f) (dpr3 g))))
  --    (λ a, dpair id (dpair id (id_right ⬝ (symm id_left))))
  --    (λ a b c d h g f, dtrip_eq2   assoc    assoc    proof_irrel)
  --    (λ a b f,         trip.equal2 id_left  id_left  proof_irrel)
  --    (λ a b f,         trip.equal2 id_right id_right proof_irrel)

  definition arrow_obs (ob : Type) (C : category ob) :=
  Σ(a b : ob), mor a b

  definition src {ob : Type} {C : category ob} (a : arrow_obs ob C) : ob :=
  dpr1 a

  definition dst {ob : Type} {C : category ob} (a : arrow_obs ob C) : ob :=
  dpr2' a

  definition to_mor {ob : Type} {C : category ob} (a : arrow_obs ob C) : mor (src a) (dst a) :=
  dpr3 a

  definition arrow_mor (ob : Type) (C : category ob) (a b : arrow_obs ob C) : Type :=
  Σ (g : mor (src a) (src b)) (h : mor (dst a) (dst b)), to_mor b ∘ g = h ∘ to_mor a

  definition mor_src {ob : Type} {C : category ob} {a b : arrow_obs ob C} (m : arrow_mor ob C a b) : mor (src a) (src b) :=
  dpr1 m

  definition mor_dst {ob : Type} {C : category ob} {a b : arrow_obs ob C} (m : arrow_mor ob C a b) : mor (dst a) (dst b) :=
  dpr2' m

  definition commute {ob : Type} {C : category ob} {a b : arrow_obs ob C} (m : arrow_mor ob C a b) :
       to_mor b ∘ (mor_src m) = (mor_dst m) ∘ to_mor a :=
  dpr3 m

  definition arrow (ob : Type) (C : category ob) : category (arrow_obs ob C) :=
  mk (λa b, arrow_mor ob C a b)
     (λ a b c g f, dpair (mor_src g ∘ mor_src f) (dpair (mor_dst g ∘ mor_dst f)
        (show to_mor c ∘ (mor_src g ∘ mor_src f) = (mor_dst g ∘ mor_dst f) ∘ to_mor a,
         proof
         calc
         to_mor c ∘ (mor_src g ∘ mor_src f) = (to_mor c ∘ mor_src g) ∘ mor_src f : assoc
           ... = (mor_dst g ∘ to_mor b) ∘ mor_src f  : {commute g}
           ... = mor_dst g ∘ (to_mor b ∘ mor_src f)  : symm assoc
           ... = mor_dst g ∘ (mor_dst f ∘ to_mor a)  : {commute f}
           ... = (mor_dst g ∘ mor_dst f) ∘ to_mor a  : assoc
         qed)
       ))
     (λ a, dpair id (dpair id (id_right ⬝ (symm id_left))))
     (λ a b c d h g f, dtrip_eq_ndep   assoc    assoc    proof_irrel)
     (λ a b f,         trip.equal_ndep id_left  id_left  proof_irrel)
     (λ a b f,         trip.equal_ndep id_right id_right proof_irrel)

  end arrow

  -- definition foo
  --     : category (sorry) :=
  -- mk (λa b, sorry)
  --    (λ a b c g f, sorry)
  --    (λ a, sorry)
  --    (λ a b c d h g f, sorry)
  --    (λ a b f, sorry)
  --    (λ a b f, sorry)

end category
