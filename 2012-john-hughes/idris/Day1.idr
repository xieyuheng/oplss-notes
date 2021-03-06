module Day1

data Tree : a -> Type where
  Leaf : a -> Tree a
  Branch : Tree a -> Tree a -> Tree a

TREE : Tree String
TREE = Branch (Leaf "a") (Branch (Leaf "b") (Leaf "c"))

treeMap : (a -> b) -> Tree a -> Tree b
treeMap f (Leaf a) = Leaf (f a)
treeMap f (Branch l r) = Branch (treeMap f l) (treeMap f r)

-- interface Functor (f : Type -> Type) where
--     map : (m : a -> b) -> f a -> f b

Functor Tree where
  -- map : (f : a -> b) -> Tree a -> Tree b
  map f (Leaf a) = Leaf (f a)
  map f (Branch l r) = Branch (map f l) (map f r)

zipTree : Tree a -> Tree b -> Maybe (Tree (Pair a b))
zipTree (Leaf x) (Leaf y) = Just (Leaf (x, y))
zipTree (Branch l r) (Branch l' r') = do
  l'' <- zipTree l l'
  r'' <- zipTree r r'
  pure (Branch l'' r'')
zipTree _ _ = Nothing

zipTree : Tree a -> Tree b -> Maybe (Tree (Pair a b))
zipTree (Leaf x) (Leaf y) = Just (Leaf (x, y))
zipTree (Branch l r) (Branch l' r') =
  liftA2 Branch (zipTree l l') (zipTree r r')
zipTree _ _ = Nothing

-- test --
-- zipTree TREE TREE

-- data State : (s : Type) -> (a : Type) -> Type where
--   MkState : (g : (s -> (a, s))) -> State s a

record State (s : Type) (a : Type) where
  constructor MkState
  g : (s -> (a, s))

-- to use record
--   we do not even need to change the following code

Functor (State s) where
  -- map : (f : a -> b) -> State s a -> State s b
  map f (MkState g) =
    MkState (\ s =>
      let (a, s') = g s
      in ((f a), s'))

Functor (State s) =>
Applicative (State s) where
  -- (<*>) : State s (a -> b) -> State s a -> State s b
  (MkState f) <*> (MkState g) =
    MkState (\ s =>
      let (f', s') = f s
          (a, s'') = g s'
      in (f' a, s''))
  -- pure : a -> State s a
  pure a = MkState (\ s => (a, s))

Applicative (State s) =>
Monad (State s) where
  -- (>>=) : State s a -> (a -> State s b) -> State s b
  (MkState g) >>= m =
    MkState (\ s =>
      let (a, s') = g s
          MkState f = m a
      in f s')

numberWithInt : Tree a -> (s : Int) -> (Tree Int, Int)
numberWithInt (Leaf _) s = (Leaf s, s+1)
numberWithInt (Branch l r) s =
  let (l', s') = numberWithInt l s
      (r', s'') = numberWithInt r s'
  in (Branch l' r', s'')

tick : State Int Int
tick = MkState (\s => (s, s+1))

-- number : Tree a -> State Int (Tree Int)
-- number (Leaf _) = do
--   s <- tick
--   pure (Leaf s)
-- number (Branch l r) = do
--   l' <- number l
--   r' <- number r
--   pure (Branch l' r')

number : Tree a -> State Int (Tree Int)
number (Leaf _) = liftA Leaf tick
number (Branch l r) = liftA2 Branch (number l) (number r)

NUMBERED_TREE : Tree Int
NUMBERED_TREE =
  let MkState g = number TREE
      (tree, state) = g 0
  in tree

-- generic functions for Monad --
-- liftA : Applicative f => (a -> b) -> f a -> f b
-- liftA2 : Applicative f => (a -> b -> c) -> f a -> f b -> f c

-- the Monad laws --
-- (1)    pure x >>= f  ==  f x
-- (2)      m >>= pure  ==  m
-- (3) (m >>= f) >>= g  ==  m >>= (\x => f x >>= g)
