/******************************************************************************
*
* 
* 
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file te_fsbl_hooks.h
*
******************************************************************************/
#ifndef TE_FSBL_HOOKS_H_
#define TE_FSBL_HOOKS_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include "fsbl.h"
// rename and enable custom TE hooks
#include "te_fsbl_hooks_te0720.h"
// #define ENABLE_TE_HOOKS_BD //TE_FsblHookBeforeBitstreamDload
// #define ENABLE_TE_HOOKS_AD //TE_FsblHookAfterBitstreamDload
#define ENABLE_TE_HOOKS_BH //TE_FsblHookBeforeHandoff
// #define ENABLE_TE_HOOKS_FB //TE_FsblHookFallback

/************************** Function Prototypes ******************************/

/* FSBL hook function which is called before bitstream download */
u32 TE_FsblHookBeforeBitstreamDload(void);

/* FSBL hook function which is called after bitstream download */
u32 TE_FsblHookAfterBitstreamDload(void);

/* FSBL hook function which is called before handoff to the application */
u32 TE_FsblHookBeforeHandoff(void);

/* FSBL hook function which is called in FSBL fallback */
void TE_FsblHookFallback(void);

#ifdef __cplusplus
}
#endif

#endif	/* end of protection macro */
