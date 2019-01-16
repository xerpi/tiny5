#define ARRAY_LEN(x) (sizeof(x) / sizeof(*x))

int a[128], b[128];

void main()
{
	int i, ok = 1;

	for (i = 0; i < ARRAY_LEN(a); i++)
		a[i] = 5;

	/* memcpy */
	for (i = 0; i < ARRAY_LEN(b); i++)
		b[i] = a[i];

	/* Check memcpy */
	for (i = 0; i < ARRAY_LEN(a); i++) {
		if (b[i] != a[i]) {
			ok = 0;
			break;
		}
	}

	/* Test done: ECALL, result to r3 */
	asm volatile(
		"add x3, %0, x0\n\t"
		"ecall"
		: : "r"(ok)
	);
}
