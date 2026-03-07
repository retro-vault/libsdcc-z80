/*
 * bare-metal I/O declarations (platform-independent)
 *
 * gpl-2.0-or-later (see: LICENSE)
 * copyright (c) 2021 - 2026 tomaz stih
 */
#ifndef __IO_H__
#define __IO_H__

extern void cinit(void);
extern void cclear(void);
extern void cputs(const char *s);
extern void cputc(char ch);

#endif /* __IO_H__ */
