#ifndef TOP_MODULE_H
#define TOP_MODULE_H

#define IDENT(x) x
#define XSTR(s) STR(s)
#define STR(s) #s
#define INCLUDE_FILE(a, b) XSTR(IDENT(a)b)

#define VTOP_MODULE_HEADER INCLUDE_FILE(VTOP_MODULE, .h)

#endif
