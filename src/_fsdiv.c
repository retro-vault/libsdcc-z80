/*-------------------------------------------------------------------------
   _fsdiv.c - Floating point library in optimized assembly for 8051

   Copyright (c) 2004, Paul Stoffregen, paul@pjrc.com

   This library is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 2, or (at your option) any
   later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this library; see the file COPYING. If not, write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.

   As a special exception, if you link this library with other files,
   some of which are compiled with SDCC, to produce an executable,
   this library does not by itself cause the resulting executable to
   be covered by the GNU General Public License. This exception does
   not however invalidate any other reasons why the executable file
   might be covered by the GNU General Public License.
-------------------------------------------------------------------------*/

#define _AUTOMEM
#define __SDCC_FLOAT_LIB
#include <float.h>

/*
** libgcc support for software floating point.
** Copyright (C) 1991 by Pipeline Associates, Inc.  All rights reserved.
** Permission is granted to do *anything* you want with this file,
** commercial or otherwise, provided this message remains intact.  So there!
** I would appreciate receiving any updates/patches/changes that anyone
** makes, and am willing to be the repository for said changes (am I
** making a big mistake?).
**
** Pat Wood
** Pipeline Associates, Inc.
** pipeline!phw@motown.com or
** sun!pipeline!phw or
** uunet!motown!pipeline!phw
*/

/* (c)2000/2001: hacked a little by johan.knol@iduna.nl for sdcc */

union float_long
  {
    float f;
    long l;
  };

/* divide two floats */
static float __fsdiv_org (float a1, float a2)
{
  volatile union float_long fl1, fl2;
  long result;
  unsigned long mask;
  unsigned long mant1, mant2;
  int exp;
  char sign;

  fl1.f = a1;

  exp = EXP (fl1.l);
  /* numerator denormal??? */
  if (!exp)
    return (0);

  fl2.f = a2;
  /* subtract exponents */
  exp -= EXP (fl2.l);
  exp += EXCESS;

  /* compute sign */
  sign = SIGN (fl1.l) ^ SIGN (fl2.l);

  /* now get mantissas */
  mant1 = MANT (fl1.l);
  mant2 = MANT (fl2.l);

  /* this assures we have 24 bits of precision in the end */
  if (mant1 < mant2)
    {
      mask = 0x1000000;
    }
  else
    {
      mask = 0x0800000;
      exp++;
    }

  if (exp < 1) /* denormal */
    return (0);

  if (exp >= 255)
    {
      fl1.l = sign ? SIGNBIT | __INFINITY : __INFINITY;
    }
  else
    {
      /* now we perform repeated subtraction of fl2.l from fl1.l */
      result = 0;
      do
        {
          long diff = mant1 - mant2;
          if (diff >= 0)
            {
              mant1 = diff;
              result |= mask;
            }
          mant1 <<= 1;
          mask >>= 1;
        }
      while (mask);

      /* round */
      if (mant1 >= mant2)
        result += 1;

      result &= ~HIDDEN;

      /* pack up and go home */
      fl1.l = PACK (sign ? SIGNBIT : 0 , exp, result);
    }
  return (fl1.f);
}

float __fsdiv (float a1, float a2)
{
  unsigned long _AUTOMEM *p2 = (unsigned long *) &a2;

  if (EXP (*p2) == 0) // a2 is denormal or zero, treat as zero
    {
      float f;
      unsigned long _AUTOMEM *p = (unsigned long *) &f;
      if (a1 > 0.0f)
        *p = __INFINITY;           // +inf
      else if (a1 < 0.0f)
        *p = SIGNBIT | __INFINITY; // -inf
      else // a1 is denormal, zero or nan
        *p = __NAN;                // nan
      return f;
    }
  return __fsdiv_org (a1, a2);
}