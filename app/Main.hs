module Main where

import Control.Concurrent.MVar
import System.Process
import System.Win32.Services
import qualified System.Win32.Error as E

main = do
    mStop <- newEmptyMVar
    startServiceCtrlDispatcher "Emacs daemon" 3000 (handler mStop) $ \_ _ h -> do
        spawnCommand "emacs --fg-daemon"
        setServiceStatus h running
        takeMVar mStop
        setServiceStatus h stopped

handler mStop hStatus Stop = do
    setServiceStatus hStatus stopPending
    putMVar mStop ()
    return True
handler _ _ Interrogate = return True
handler _ _ _           = return False

running = ServiceStatus Win32OwnProcess Running [AcceptStop] E.Success 0 0 0
stopped = ServiceStatus Win32OwnProcess Stopped [] E.Success 0 0 0
stopPending = ServiceStatus Win32OwnProcess StopPending [AcceptStop] E.Success 0 0 0


{-
module Main where

import Control.Concurrent.MVar
import System.Win32.Services
import System.Win32.Types
import qualified System.Win32.Error as E

main :: IO ()
main = do
    gState <- newMVar (1, ServiceStatus Win32OwnProcess
                          StartPending [] E.Success 0 0 3000)
    mStop <- newEmptyMVar
    startServiceCtrlDispatcher "Test" 3000 (handler mStop gState) $ svcMain mStop gState

svcMain :: MVar a -> MVar (DWORD, ServiceStatus) -> p1 -> p2 -> HANDLE -> IO ()
svcMain mStop gState _ _ h = do
    reportSvcStatus h Running E.Success 0 gState
    takeMVar mStop
    reportSvcStatus h Stopped E.Success 0 gState

handler :: MVar () -> MVar (DWORD, ServiceStatus)
    -> HandlerFunction
handler mStop mState hStatus Stop = do
    reportSvcStatus hStatus StopPending E.Success 3000 mState
    putMVar mStop ()
    return True
handler _ _ _ Interrogate = return True
handler _ _ _ _  = return False

stopPending = ServiceStatus Win32OwnProcess StopPending [AcceptStop] E.Success 0 0 0

reportSvcStatus :: HANDLE -> ServiceState -> E.ErrCode -> DWORD
    -> MVar (DWORD, ServiceStatus) -> IO ()
reportSvcStatus hStatus state win32ExitCode waitHint mState = do
    modifyMVar_ mState $ \(checkPoint, svcStatus) -> do
        let state' = nextState (checkPoint, svcStatus
             { win32ExitCode = win32ExitCode
             , waitHint      = waitHint
             , currentState  = state })
        setServiceStatus hStatus (snd state')
        return state'

nextState :: (DWORD, ServiceStatus) -> (DWORD, ServiceStatus)
nextState (checkPoint, svcStatus) = case (currentState svcStatus) of
    StartPending -> (checkPoint + 1, svcStatus
        { controlsAccepted = [], checkPoint = checkPoint + 1 })
    Running -> (checkPoint, svcStatus
        { controlsAccepted = [AcceptStop], checkPoint = 0 })
    Stopped -> (checkPoint, svcStatus
        { controlsAccepted = [], checkPoint = 0 })
    _ -> (checkPoint + 1, svcStatus
        { controlsAccepted = [], checkPoint = checkPoint + 1 })
-}
