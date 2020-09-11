{-# LANGUAGE DeriveAnyClass, CPP #-}
{-|
Module      : KMonad.Keyboard.Types
Description : Basic keyboard types
Copyright   : (c) David Janssen, 2020
License     : MIT
Maintainer  : janssen.dhj@gmail.com
Stability   : experimental
Portability : portable

The following module contains all the basic, OS-agnostic types that we use to
reason about keyboards, their elements, and their events. Note that some of the
terminology can be ambiguous, so for clarity's sake this is how we use
terminology in KMonad:

A keyboard is a collection of different entities that can exist as either
pressed or released.

When we say *key* we are using this to refer to the unique identifiability of an
element (by its 'Keycode').

When we say *button* we are using this to refer to the fact that the elements of
a keyboard have 2 states, and that changing between these states causes actions
to occur.

Buttons are bound to keys, and when a state-change associated with a particular
key is detected ('KeyEvent'), that key's button is looked up, and it's state is
similarly changed.

-}
module KMonad.Keyboard.Types
  ( -- * Keycode
    -- $code
    Keycode
  , HasKeycode(..)
  , matchCode

    -- * Switch
    -- $switch
  , Switch(..)
  , HasSwitch(..)
  , isPress, isRelease

    -- * KeyEvent
    -- $event
  , KeyEvent
  , mkKeyEvent, mkPress, mkRelease
  )
where

import KMonad.Prelude

import KMonad.Util

#ifdef linux_HOST_OS
import KMonad.Keyboard.Linux.Keycode ( Keycode )
#endif

--------------------------------------------------------------------------------
-- $code
--
-- 'Keycode's are what an OS uses to identify which key is being pressed. In the
-- following section we define the OS-agnostic 'Keycode' support in KMonad. This
-- wraps around the OS-specific 'Keycode' definitions imported above.

-- | A class describing how to access some value's 'Keycode'.
class HasKeycode a where
  keycode :: Lens' a Keycode

-- | Return whether the keycodes match between 2 values.
matchCode :: (HasKeycode a, HasKeycode b) => a -> b -> Bool
matchCode a b = a^.keycode == b^.keycode

--------------------------------------------------------------------------------
-- $switch
--
-- 'Switch' describes a state-transition for a 2-state system, with the
-- additional semantics of some sort of /enabled/ vs. /disabled/ context.

-- | An ADT describing all the state-changes a button or key can undergo.
data Switch
  = Press   -- ^ Change from disabled to enabled
  | Release -- ^ Change from enabled to disabled
  deriving (Eq, Ord, Enum, Show, Generic, Hashable)

-- | A class describing how to access some value's 'Switch'
class HasSwitch a where
  switch :: Lens' a Switch

instance HasSwitch Switch where switch = id

-- | How to pretty-print a 'Switch'
instance Display Switch where
  textDisplay = tshow

-- | Return whether a value contained a 'Press'
isPress :: HasSwitch a => a -> Bool
isPress = (Press ==) . view switch

-- | Return whether a value contained a 'Release'
isRelease :: HasSwitch a => a -> Bool
isRelease = (Release ==) . view switch

--------------------------------------------------------------------------------
-- $event
--
-- A 'KeyEvent' is a detected state-change for some key, identified by its
-- 'Keycode'. Additionally, we store the time when this change was detected.

data KeyEvent = KeyEvent
  { _keSwitch :: !Switch  -- ^ Wether a 'Press' or 'Release' occurred
  , _keCode   :: !Keycode -- ^ The identity of the key which registered the event
  , _keTime   :: !UTCTime -- ^ When the event occured
  }
makeLenses ''KeyEvent

instance HasSwitch  KeyEvent where switch  = keSwitch
instance HasKeycode KeyEvent where keycode = keCode
instance HasTime    KeyEvent where time    = keTime

-- | How to pretty-print a 'KeyEvent'
instance Display KeyEvent where
  textDisplay e = tshow (e^.switch) <> " " <> textDisplay (e^.keycode)

-- | Create a new 'KeyEvent'
mkKeyEvent :: Switch -> Keycode -> UTCTime -> KeyEvent
mkKeyEvent = KeyEvent

-- | Create a new 'Press' 'KeyEvent'
mkPress :: Keycode -> UTCTime -> KeyEvent
mkPress = mkKeyEvent Press

-- | Create a new 'Release' 'KeyEvent'
mkRelease :: Keycode -> UTCTime -> KeyEvent
mkRelease = mkKeyEvent Release
