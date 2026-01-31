/*
 * basic zx spectrum functions
 * 
 * MIT License (see: LICENSE)
 * copyright (c) 2021 - 2026 tomaz stih
 *
 * tstih
 *
 */
#ifndef __SPECTRUM_H__
#define __SPECTRUM_H__

/* ROM I/O */
extern void cinit(void);
extern void cclear(void);
extern void cputs(const char *s);
extern void cputc(char ch);

#endif /* __SPECTRUM_H__ */