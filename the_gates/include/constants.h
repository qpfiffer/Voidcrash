// vim: noet ts=4 sw=4
#pragma once

#define UNUSED(x) (void)x
#define WINDOW_NAME "VOIDCRASH"
#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 720

#ifdef F_DOUBLE_PRECISION
#define VS_CHAR "%lf"
#else
#define VS_CHAR "%f"
#endif
