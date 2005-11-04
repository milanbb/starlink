#ifndef DITS_ERRH
#define DITS_ERRH 1
/* C language ERROR include file
 * Generated by /sw4/bdk/drama-v1.4.2/release/messgen/r0_5_7/sun4_solaris/messgen utility
 * from input file Dits_Err.msg at Wed Apr 21 15:50:41 2004
 */

/* Facility number */
#define DITS__FACNUM 2000

/* OK Status symbol */
#define DITS__OK 0

/* Invalid argument to a Dits routine */
#define DITS__INVARG 0xFD0800C

/* Error allocating memory */
#define DITS__MALLOCERR 0xFD08014

/* Error adding a task variable */
#define DITS__TASKVARERR 0xFD0801C

/* Dits not initialised */
#define DITS__NOTINIT 0xFD08024

/* No obey routine specified */
#define DITS__NOOBEY 0xFD0802C

/* DitsMsgRec called before previous message was processed */
#define DITS__UNPROCMSG 0xFD08034

/* DitsMsgProc called with no message available */
#define DITS__NOMSG 0xFD0803C

/* The number of messages to be sent is less then one or the number of replies is less then zero */
#define DITS__INVMSGCOUNT 0xFD08044

/* Invalid Dits message type */
#define DITS__INVMSGTYPE 0xFD0804C

/* Invalid Imp system message */
#define DITS__INVSYSMSG 0xFD08054

/* Invalid dits path */
#define DITS__INVPATH 0xFD0805C

/* Dits received an unexpected messages */
#define DITS__UNEXPMSG 0xFD08064

/* The task is not known to the message system */
#define DITS__NOTKNOWN 0xFD0806C

/* The action is not supported by the task */
#define DITS__UNKNACT 0xFD08074

/* The action is already active */
#define DITS__ACTACTIVE 0xFD0807C

/* The action is not active and therefore cannot be kicked */
#define DITS__ACTNOTACT 0xFD08084

/* Invalid transaction id */
#define DITS__INVTRANSID 0xFD0808C

/* Invalid task name */
#define DITS__INVTASKNAME 0xFD08094

/* Task unknown to message system */
#define DITS__UNKNTASK 0xFD0809C

/*  Invalid transaction code */
#define DITS__INVTRANSACT 0xFD080A4

/* An attempt was made to enable Uface context within an action routine */
#define DITS__UFACEERR 0xFD080AC

/* Action does not support Kick operations */
#define DITS__NOKICK 0xFD080B4

/* Task disconnected */
#define DITS__TASKDISC 0xFD080BC

/* The machine on which the task was running has been lost */
#define DITS__MACHLOST 0xFD080C4

/* Already trying to find a path to this task */
#define DITS__FINDINGPATH 0xFD080CC

/* Message length is too small for a Dits message */
#define DITS__INVMSGLEN 0xFD080D4

/* An action attempted to kill itself */
#define DITS__CANTKILLSELF 0xFD080DC

/* An action attempted to signal itself */
#define DITS__CANTSIGSELF 0xFD080E4

/* Action killed by another action in the same task */
#define DITS__ACTKILLED 0xFD080EC

/* Error sending completion message, sent without the argument */
#define DITS__COMPSENDERR 0xFD080F4

/* Function should only be called by user action routines */
#define DITS__NOTUSERACT 0xFD080FC

/* Function should not be called by user action routines */
#define DITS__USERACT 0xFD08104

/* There is not sufficient space in the message receiver for this message */
#define DITS__NOSPACE 0xFD0810C

/* An Imp shutdown message was received */
#define DITS__IMPSHUTDOWN 0xFD08114

/* Dits application routine timeout */
#define DITS__APP_TIMEOUT 0xFD0811C

/* Dits application routine error */
#define DITS__APP_ERROR 0xFD08124

/* Invalid control action name */
#define DITS__INVCONTROL 0xFD0812C

/* No access permission to directory/path */
#define DITS__NOACCESS 0xFD08134

/* Invalid directory name (too long?) */
#define DITS__INVDIRNAME 0xFD0813C

/* No such directory */
#define DITS__NOSUCHDIR 0xFD08144

/* File is not a directory */
#define DITS__NOTDIR 0xFD0814C

/* Actual directory name is too long for space allocated by Dits */
#define DITS__TOOLONG 0xFD08154

/* Unexpected error changing directory */
#define DITS__CHDIRERR 0xFD0815C

/* Unexpected error getting directory name */
#define DITS__GETWDERR 0xFD08164

/* No parameter system routine supplied by user */
#define DITS__NOPARAMSYS 0xFD0816C

/* Dits exited via exit handler */
#define DITS__EXITHANDLER 0xFD08174

/* Exceeded maximum count of Alternative Input Sources */
#define DITS__ALTINMAX 0xFD0817C

/* Invalid File descriptor (UNIX) or Event Flag (VMS) */
#define DITS__INVDESC 0xFD08184

/* A signal interrupts a call to select */
#define DITS__SIGNAL 0xFD0818C

/* Error in select */
#define DITS__SELECTERR 0xFD08194

/* Unexpected Message type code to Dui routine */
#define DITS__DUICODE 0xFD0819C

/* Message system error sending message */
#define DITS__SENDERR 0xFD081A4

/* Apparent Dits Programing Error */
#define DITS__PROGERR 0xFD081AC

/* User applicaction code put an invalid request type */
#define DITS__INVREQ 0xFD081B4

/* Parameter monitor system not enabled */
#define DITS__MONNOTENA 0xFD081BC

/* Parameter changed */
#define DITS__MON_CHANGED 0xFD081C4

/* Parameter monitor started */
#define DITS__MON_STARTED 0xFD081CC

/* Invalid monitor id */
#define DITS__MON_INVID 0xFD081D4

/* This id already monitoring this prameter */
#define DITS__MON_ALREADY 0xFD081DC

/* Have specified monitor of all paramerter but not first */
#define DITS__MON_ALLNOTFIRST 0xFD081E4

/* Invalid monitor message name */
#define DITS__INVMON 0xFD081EC

/* Error sending information message, sent without the argument */
#define DITS__INFOSENDERR 0xFD081F4

/* Task crashed */
#define DITS__TASKCRASHED 0xFD081FC

/* Loaded task exited with error */
#define DITS__EXITERR 0xFD08204

/* The task closed its connection with this task */
#define DITS__CLOSECONN 0xFD0820C

/* DITS Exited via exit handler with signal SIGHUP */
#define DITS__SIGHUP 0xFD08214

/* DITS Exited via exit handler with signal SIGINT */
#define DITS__SIGINT 0xFD0821C

/* DITS Exited via exit handler with signal SIGQUIT */
#define DITS__SIGQUIT 0xFD08224

/* DITS Exited via exit handler with signal SIGPIPE */
#define DITS__SIGPIPE 0xFD0822C

/* DITS Exited via exit handler with signal SIGALRM */
#define DITS__SIGALRM 0xFD08234

/* DITS Exited via exit handler with signal SIGTERM */
#define DITS__SIGTERM 0xFD0823C

/* DITS Exited via exit handler with signal SIGXCPU */
#define DITS__SIGXCPU 0xFD08244

/* DITS Exited via exit handler with signal SIGFXSZ */
#define DITS__SIGXFSZ 0xFD0824C

/* Unexpected error during peek */
#define DITS__PEEKERR 0xFD08254

/* Connection by rejected by target task */
#define DITS__CON_REJECTED 0xFD0825C

/* Error in command arguments */
#define DITS__CMDARGERR 0xFD08264

/* Timeout during load operation */
#define DITS__LOADTIMEOUT 0xFD0826C

/* Recursive call to DitsMsgReceive */
#define DITS__MSGRECUR 0xFD08274

/* DitsActionWait has already been invoked for this action */
#define DITS__WAITALRDY 0xFD0827C

/* Attempt to kick spawnable action without specifying an argument */
#define DITS__SPKICK_NOARG 0xFD08284

/* Invalid argument to kick of spawnable action */
#define DITS__SPKICK_INVARG 0xFD0828C

/* Attempted to signal a spawnable action by name, you must use its index */
#define DITS__SPSIG 0xFD08294

/* Attempted to kill a spawnable action by name, you must use its index */
#define DITS__SPKILL 0xFD0829C

/* Invalid action index */
#define DITS__INVACTINDEX 0xFD082A4

/* Attempt to set a readonly parameter */
#define DITS__READONLY_PAR 0xFD082AC

/* Parameter system does not support multiple get */
#define DITS__PARSYS_NOMGET 0xFD082B4

/* Invalid SDS structure */
#define DITS__INVALID_SDS 0xFD082BC

/* No parameter name supplied */
#define DITS__NONAME 0xFD082C4

/* Can't send on a path while waiting for a notify request */
#define DITS__NOTIFYWAIT 0xFD082CC

/* Attempted to get path when processing connection failure */
#define DITS__CONFAILED 0xFD082D4

/* Task has connected under different id when already connected */
#define DITS__TASKRESTART 0xFD082DC

/* Can't send tap message on a path while waiting for a notify request */
#define DITS__NOTIFYWAIT_TAP 0xFD082E4

/* Can't send MsgOut message on a path while waiting for a notify request */
#define DITS__NOTIFYWAIT_MSG 0xFD082EC

/* Can't send Ers message on a path while waiting for a notify request */
#define DITS__NOTIFYWAIT_ERS 0xFD082F4

/* Can't send Trigger message on a path while waiting for a notify request */
#define DITS__NOTIFYWAIT_TRIG 0xFD082FC

/* Attempt to kill an action which is blocked */
#define DITS__CANTKILLBLOCKED 0xFD08304

/* The DRAMA networking tasks are not running on the machine on which the target task is expected to be running */
#define DITS__NO_NET_ON_REMOTE 0xFD0830C

/* Failed to set up task exit handler */
#define DITS__EXITHANDSETUP 0xFD08314

/* DITS Exited via exit handler with signal SIGABRT */
#define DITS__SIGABRT 0xFD0831C

/* DITS Exited via exit handler with signal SIGFPE */
#define DITS__SIGFPE 0xFD08324

/* DITS Exited via exit handler with signal SIGILL */
#define DITS__SIGILL 0xFD0832C

/* DITS Exited via exit handler with signal SIGSEGV */
#define DITS__SIGSEGV 0xFD08334

/* DITS Exited via exit handler with signal SIGBUS */
#define DITS__SIGBUS 0xFD0833C

/* DITS Exited via exit handler with signal SIGEMT */
#define DITS__SIGEMT 0xFD08344

/* DITS Exited via exit handler with signal SIGEMT */
#define DITS__SIGEMG 0xFD0834C

/* DITS Exited via exit handler with signal SIGIOT */
#define DITS__SIGIOT 0xFD08354

/* DITS Exited via exit handler with signal SIGSYS */
#define DITS__SIGSYS 0xFD0835C

/* DITS Exited via exit handler with signal SIGTRAP */
#define DITS__SIGTRAP 0xFD08364

/* The argument is not a bulk data item */
#define DITS__NOTBULK 0xFD0836C

/* Error in the sequence of releasing bulk data */
#define DITS__BULKRELERR 0xFD08374

/* Attempt to set a parameter via ADITS where the parameter name was too long */
#define DITS__ADITS_SETLONG 0xFD0837C

/* ADITS (Adam to Dits translator) has run out of transaction ids */
#define DITS__ADITS_NOTRANS 0xFD08384

/* ADITS (Adam to Dits translator) has run out of path entries */
#define DITS__ADITS_NOPATHS 0xFD0838C

/* ADITS received a IMP connect without wait.  This should not happen */
#define DITS__ADITS_CONERR 0xFD08394

/* You cannot use the DITS_M_SENDCUR flag when monitoring all parameters */
#define DITS__SENDCUR_ALL 0xFD0839C

/* Attempt to allocate UFACE transaction without a current Uface handler */
#define DITS__UFACE_NOROUTINE 0xFD083A4

#endif
