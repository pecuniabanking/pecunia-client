/***************************************************************************
    begin       : Sat Dec 27 2003
    copyright   : (C) 2003-2010 by Martin Preuss
    email       : martin@libchipcard.de


 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU Lesser General Public            *
 *   License as published by the Free Software Foundation; either          *
 *   version 2.1 of the License, or (at your option) any later version.    *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 *
 *   MA  02111-1307  USA                                                   *
 *                                                                         *
 ***************************************************************************/


#ifndef GWENHYWFAR_PROCESS_H
#define GWENHYWFAR_PROCESS_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/syncio.h>
#include <gwenhywfar/error.h>

/** redirect the child processes stdin channel */
#define GWEN_PROCESS_FLAGS_REDIR_STDIN  0x00000001
/** redirect the child processes stdout channel */
#define GWEN_PROCESS_FLAGS_REDIR_STDOUT 0x00000002
/** redirect the child processes stderr channel */
#define GWEN_PROCESS_FLAGS_REDIR_STDERR 0x00000004

#define GWEN_PROCESS_FLAGS_DEFAULT 0


#ifdef __cplusplus
extern "C" {
#endif

  typedef struct GWEN_PROCESS GWEN_PROCESS;

  /**
   * States a process can assume.
   */
  typedef enum {
    /** process has not yet been started */
    GWEN_ProcessStateNotStarted=0,
    /** process is running */
    GWEN_ProcessStateRunning,
    /** process exited normally */
    GWEN_ProcessStateExited,
    /** process terminated abnormally (on POSIX systems this is in most
     * cases an uncaught signal) */
    GWEN_ProcessStateAborted,
    /** process has been stopped (unused for now) */
    GWEN_ProcessStateStopped,
    /** process is in an unknown state */
    GWEN_ProcessStateUnknown
  } GWEN_PROCESS_STATE;


  /**
   * Creates a process representation. This does not start a process, it
   * simply prepares some data for starting a process.
   */
  GWENHYWFAR_API GWEN_PROCESS *GWEN_Process_new();

  /**
   * Frees process data. This does not stop the process represented by this
   * data. You should only free this data after the process has terminated
   * or if you are not interested in the result of the process (because
   * after freeing this data there is no way to communicate with the process).
   */
  GWENHYWFAR_API void GWEN_Process_free(GWEN_PROCESS *pr);

  /**
   * Returns the current process flags
   * (see @ref GWEN_PROCESS_FLAGS_REDIR_STDOUT and others)
   */
  GWENHYWFAR_API
    uint32_t GWEN_Process_GetFlags(const GWEN_PROCESS *pr);

  /**
   * Sets the process flags to the given value
   * (see @ref GWEN_PROCESS_FLAGS_REDIR_STDOUT and others)
   */
  GWENHYWFAR_API
    void GWEN_Process_SetFlags(GWEN_PROCESS *pr, uint32_t f);

  /**
   * Adds the given flag to the current process flags
   * (see @ref GWEN_PROCESS_FLAGS_REDIR_STDOUT and others)
   */
  GWENHYWFAR_API
    void GWEN_Process_AddFlags(GWEN_PROCESS *pr, uint32_t f);

  /**
   * Removes the given flag from the current process flags
   * (see @ref GWEN_PROCESS_FLAGS_REDIR_STDOUT and others)
   */
  GWENHYWFAR_API
    void GWEN_Process_SubFlags(GWEN_PROCESS *pr, uint32_t f);

  /**
   * Starts the given process.
   * @param pr pointer to process data
   * @param prg path and name of the program to start
   * @param args command line arguments for the program (MUST NOT contain
   *  the name of the program)
   */
  GWENHYWFAR_API GWEN_PROCESS_STATE GWEN_Process_Start(GWEN_PROCESS *pr,
                                                       const char *prg,
                                                       const char *args);

  /**
   * Checks for the current state of the given process.
   */
  GWENHYWFAR_API GWEN_PROCESS_STATE GWEN_Process_CheckState(GWEN_PROCESS *pr);

  /**
   * Returns the result of a process. This process must have terminated
   * in order to return a result.
   */
  GWENHYWFAR_API int GWEN_Process_GetResult(GWEN_PROCESS *pr);

  /**
   * Waits for the termination of the given process.
   */
  GWENHYWFAR_API int GWEN_Process_Wait(GWEN_PROCESS *pr);

  /**
   * Terminates a process immediately (on POSIX systems this is performed
   * by sending a KILL signal).
   * This function waits for the process to terminate.
   */
  GWENHYWFAR_API int GWEN_Process_Terminate(GWEN_PROCESS *pr);

  /**
   * Returns a GWEN_BUFFEREDIO which can be used to write data to be
   * received by the process via stdin. Returns 0 if the process does not
   * have the flag @ref GWEN_PROCESS_FLAGS_REDIR_STDIN set.
   */
  GWENHYWFAR_API
    GWEN_SYNCIO *GWEN_Process_GetStdin(const GWEN_PROCESS *pr);

  /**
   * Returns a GWEN_BUFFEREDIO which can be used to read data written by
   * the process via stdout. Returns 0 if the process does not
   * have the flag @ref GWEN_PROCESS_FLAGS_REDIR_STDOUT set.
   */
  GWENHYWFAR_API
    GWEN_SYNCIO *GWEN_Process_GetStdout(const GWEN_PROCESS *pr);

  /**
   * Returns a GWEN_BUFFEREDIO which can be used to read data written by
   * the process via stderr. Returns 0 if the process does not
   * have the flag @ref GWEN_PROCESS_FLAGS_REDIR_STDERR set.
   */
  GWENHYWFAR_API
    GWEN_SYNCIO *GWEN_Process_GetStderr(const GWEN_PROCESS *pr);


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_PROCESS_H */


